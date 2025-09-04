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
        // Linux: write .directory via helper if available
        QString helper = "fc-directory";
        QStringList args;
        args << QString("--folder=%1").arg(folderPath)
             << QString("--tone=%1").arg(tone)
             << QString("--color=%1").arg(color);
        if (notEmptyString(tag)) {
            args << QString("--tag=%1").arg(tag);
        }
        int code = QProcess::execute(helper, args);
        if (code != 0) {
            qWarning() << "fc-directory failed with code" << code
                       << ", writing .directory directly";
            QDir().mkpath(folderPath);
            QFile file(folderPath + "/.directory");
            if (file.open(QIODevice::WriteOnly | QIODevice::Truncate |
                          QIODevice::Text)) {
                QTextStream out(&file);
                out << "[Desktop Entry]\n";
                out << "Icon=/usr/share/folder-customizer/icons/" << tone << "/"
                    << color << ".png\n";
                if (notEmptyString(tag)) {
                    out << "Comment=" << tag << "\n";
                }
            }
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