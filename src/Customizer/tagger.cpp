#include "Customizer/tagger.h"

#ifdef _WIN32

QRegularExpression section_re("\\[(.+)\\]");
QRegularExpression key_value_re("(.*)=(.*)");

DesktopIniManipulator::DesktopIniManipulator(QString folder) {
    this->m_iniPath = new QString(folder + "\\\\desktop.ini");

    QSettings::Format m_iniFormat = (QSettings::registerFormat(
        "ini", &DesktopIniManipulator::readDeskIniFile,
        &DesktopIniManipulator::writeDeskIniFile));
    this->m_iniFormat = &m_iniFormat;

    this->m_iniSettings =
        new QSettings(*(this->m_iniPath), *(this->m_iniFormat));
};

void DesktopIniManipulator::removeSection(QString section) {
    this->m_iniSettings->remove(section);
    this->setHidden();
}

void DesktopIniManipulator::resetAllSection() {
    this->m_iniSettings->clear();
    this->setHidden();
}
void DesktopIniManipulator::setHidden() {
    // call this to sync changes and make the ini file hidden

    this->m_iniSettings->sync();

    SetFileAttributesA(this->m_iniPath->toStdString().c_str(), 0x2);
    DWORD error = GetLastError();
    std::cout << "Error: " << error << "\n";
}

QSettings* DesktopIniManipulator::getInternalSettings() {
    return m_iniSettings;
}

// STATIC METHODS
bool DesktopIniManipulator::readDeskIniFile(QIODevice& device,
                                            QSettings::SettingsMap& map) {
    QString section;
    while (!device.atEnd()) {
        QString line = device.readLine();
        QRegularExpressionMatch section_match = section_re.match(line);
        if (section_match.hasMatch()) {
            section = section_match.captured(1);
            continue;
        };
        QRegularExpressionMatch key_value_match = key_value_re.match(line);
        if (key_value_match.hasMatch()) {
            QString key = key_value_match.captured(1);
            QStringList value = key_value_match.captured(2).split(",");
            map.insert((section + "/" + key), value);
            continue;
        };
    }
    return true;
}

bool DesktopIniManipulator::writeDeskIniFile(
    QIODevice& device,
    const QSettings::SettingsMap& map) {
    QMap<QString, QMap<QString, QVariant> > restructured_map;
    for (auto i = map.constKeyValueBegin(); i != map.constKeyValueEnd(); ++i) {
        QString keypath = i->first;
        QStringList keypath_list = keypath.split("/");
        QString key = keypath_list.takeLast();
        QString section = keypath_list.join("/");
        restructured_map[section][key] = i->second;
    };
    for (auto i = restructured_map.constKeyValueBegin();
         i != restructured_map.constKeyValueEnd(); ++i) {
        const QString key = i->first;
        const QByteArray section = ("[" + key.toLocal8Bit() + "]\n");
        device.write(section);
        for (auto j = restructured_map[key].constKeyValueBegin();
             j != restructured_map[key].constKeyValueEnd(); ++j) {
            std::string value;
            if (j->second.canConvert<QStringList>()) {
                QStringList valueList = j->second.value<QStringList>();
                value = valueList.join(",").toStdString();
            } else {
                value = j->second.toString().toStdString();
            }
            auto kiy = j->first.toStdString();
            QString prop = (kiy + "=" + value + "\n").c_str();
            device.write(prop.toStdString().c_str());
        }
    }
    return true;
}

void Tagger::tagFolder(QString tag) {
    this->getInternalSettings()->beginGroup(
        "{F29F85E0-4FF9-1068-AB91-08002B27B3D9}");
    this->getInternalSettings()->setValue("Prop5", tag);
    this->getInternalSettings()->endGroup();
    this->setHidden();
}

#else  // non-Windows: write Comment to .directory

#include <QtCore/QDir>
#include <QtCore/QFile>
#include <QtCore/QTextStream>

void Tagger::tagFolder(QString tag) {
    QDir().mkpath(m_folder);
    QFile file(m_folder + "/.directory");
    // Preserve existing keys if file exists, but ensure [Desktop Entry] header
    QMap<QString, QString> kv;
    if (file.exists()) {
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
    }
    kv["Comment"] = tag;
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate |
                  QIODevice::Text)) {
        QTextStream out(&file);
        out << "[Desktop Entry]\n";
        for (auto it = kv.constBegin(); it != kv.constEnd(); ++it) {
            out << it.key() << "=" << it.value() << "\n";
        }
        file.close();
    }
}

#endif