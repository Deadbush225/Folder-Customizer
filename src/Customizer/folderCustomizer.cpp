#include "Customizer/folderCustomizer.h"
#ifndef _WIN32
#include <QtCore/QDir>
#include <QtCore/QFile>
#include <QtCore/QProcess>
#include <QtCore/QTextStream>
#endif

bool notEmptyString(QString s) {
    return !(s.isNull() || s.isEmpty());
}

void FolderCustomizer::colorizeTag(QString folderPath,
                                   QString tone,
                                   QString color,
                                   QString tag) {
    if (notEmptyString(tag)) {
        qDebug() << "Tagging Folder";
        Tagger* desktopManip = new Tagger(folderPath);
        desktopManip->tagFolder(tag);
        delete desktopManip;
    }

    if (notEmptyString(tone) && notEmptyString(color)) {
        qDebug() << "Changing Icon";
#ifdef _WIN32
        changeIcon(folderPath, tone, color);
#else
        // Linux: update .directory file as INI
        QString dirFilePath = folderPath + "/.directory";
        QMap<QString, QString> kv;

        // Read existing properties if file exists
        QFile file(dirFilePath);
        if (file.exists() && file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            while (!file.atEnd()) {
                const QString line = file.readLine();
                if (line.startsWith('#') || line.trimmed().isEmpty())
                    continue;
                if (line.startsWith("["))
                    continue;  // section header
                int eq = line.indexOf('=');
                if (eq > 0) {
                    QString k = line.left(eq).trimmed();
                    QString v = line.mid(eq + 1).trimmed();
                    kv[k] = v;
                }
            }
            file.close();
        }

        // Set or update Icon and Comment
        kv["Icon"] = QString("/usr/lib/folder-customizer/bin/Icons/%1/%2.ico")
                         .arg(tone, color);
        if (notEmptyString(tag)) {
            kv["Comment"] = tag;
        }

        // Write back to .directory file
        if (file.open(QIODevice::WriteOnly | QIODevice::Truncate |
                      QIODevice::Text)) {
            QTextStream out(&file);
            out << "[Desktop Entry]\n";
            for (auto it = kv.constBegin(); it != kv.constEnd(); ++it) {
                out << it.key() << "=" << it.value() << "\n";
            }
            file.close();
        } else {
            qWarning() << "Failed to open .directory file for writing in"
                       << folderPath;
        }
#endif
    }
}

void FolderCustomizer::reset(QString folderPath,
                             bool resetIcon,
                             bool resetTag) {
#ifdef _WIN32
    DesktopIniManipulator* desktopManip = new DesktopIniManipulator(folderPath);
    if (resetIcon) {
        qDebug() << "Reseting icon";
        desktopManip->removeSection(".ShellClassInfo");
    }
    if (resetTag) {
        qDebug() << "Reseting tag";
        desktopManip->removeSection("{F29F85E0-4FF9-1068-AB91-08002B27B3D9}");
    }
    delete desktopManip;
#else
    // On Linux: edit .directory file, removing Icon and/or Comment
    QFile file(folderPath + "/.directory");
    if (!file.exists())
        return;  // nothing to reset
    QMap<QString, QString> kv;
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        while (!file.atEnd()) {
            const QString line = file.readLine();
            if (line.startsWith('#') || line.trimmed().isEmpty())
                continue;
            if (line.startsWith("["))
                continue;  // section header
            const int eq = line.indexOf('=');
            if (eq > 0) {
                const QString k = line.left(eq).trimmed();
                const QString v = line.mid(eq + 1).trimmed();
                kv[k] = v;
            }
        }
        file.close();
    }
    if (resetIcon)
        kv.remove("Icon");
    if (resetTag)
        kv.remove("Comment");
    if (kv.isEmpty()) {
        QFile::remove(folderPath + "/.directory");
        return;
    }
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate |
                  QIODevice::Text)) {
        QTextStream out(&file);
        out << "[Desktop Entry]\n";
        for (auto it = kv.constBegin(); it != kv.constEnd(); ++it) {
            out << it.key() << "=" << it.value() << "\n";
        }
        file.close();
    }
#endif
}