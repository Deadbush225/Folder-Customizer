#include "tagger.h"

QRegularExpression section_re("\\[(.+)\\]");
QRegularExpression key_value_re("(.*)=(.*)");

DesktopIniManipulator::DesktopIniManipulator(QString folder) {
    this->m_iniPath = new QString(folder + "\\desktop.ini");

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

void DesktopIniManipulator::tagFolder(QString folder, QString tag) {
    this->m_iniSettings->beginGroup("{F29F85E0-4FF9-1068-AB91-08002B27B3D9}");
    this->m_iniSettings->setValue("Prop5", tag);
    this->m_iniSettings->endGroup();

    this->setHidden();
}

void DesktopIniManipulator::setHidden() {
    this->m_iniSettings->sync();

    SetFileAttributesA(this->m_iniPath->toStdString().c_str(), 0x2);
    // std::cout << "setHidden: " << retur << " for "
    //   << this->m_iniPath->toStdString().c_str() << "\n";

    DWORD error = GetLastError();
    std::cout << "Error: " << error << "\n";
}

// STATIC METHODS
bool DesktopIniManipulator::readDeskIniFile(QIODevice& device,
                                            QSettings::SettingsMap& map) {
    // auto ret = new QMessageBox(QMessageBox::Icon::Information,
    //                            QString("Paused"), QString("Preparing to
    //                            Read"), QMessageBox::StandardButton::Ok);
    // ret->exec();

    QString section;

    qDebug() << "[---------- start READING ---------]";

    // QTextStream in(&device);
    while (!device.atEnd()) {
        QString line = device.readLine();

        QRegularExpressionMatch section_match = section_re.match(line);

        if (section_match.hasMatch()) {
            section = section_match.captured(1);
            // map.insert(section, QMap<QString, QVariant>{});

            qDebug() << "Section matched: " << section;

            continue;
        };

        QRegularExpressionMatch key_value_match = key_value_re.match(line);

        if (key_value_match.hasMatch()) {
            QString key = key_value_match.captured(1);
            QStringList value = key_value_match.captured(2).split(",");
            // check if the list is only 1 item, if it is then just return that
            // item or if the list is 1 or more item, if it is then just return
            // the list
            qDebug() << "Key matched: " << key;

            // map[section].insert(key, value);
            map.insert((section + "/" + key), value);
            qDebug() << "key: " << (section + "/" + key) << "value: " << value;

            continue;
        };

        // process_line(line);
    }

    qDebug() << "Reading: " << map;
    qDebug() << "[----------- end READING ----------]";

    // auto ret2 = QMessageBox(QMessageBox::Icon::Information,
    // QString("Paused"), QString("Preparing to Exit Read"));
    // ret2.exec();

    return true;
}

bool DesktopIniManipulator::writeDeskIniFile(
    QIODevice& device,
    const QSettings::SettingsMap& map) {
    // auto ret = QMessageBox(QMessageBox::Icon::Information, QString("Paused"),
    //    QString("Preparing to Write"));
    // ret.exec();

    QString section;
    // QMapIterator<QString, QVariant> map_iter(map);

    qDebug() << "[---------- start WRITING ---------]";
    QMap<QString, QMap<QString, QVariant> > restructured_map;

    // QMapIterator<QString, QMap<QString, QVariant> > restructured_map_iter(
    // restructured_map);

    qDebug() << "map: " << map;  //.isValidIterator(restructured_map_iter);

    for (auto i = map.constKeyValueBegin(); i != map.constKeyValueEnd(); ++i) {
        // map_iter.next();
        qDebug() << (*i).first << ": " << (*i).second << Qt::endl;

        QString keypath = i->first;
        QStringList keypath_list = keypath.split("/");

        QString key = keypath_list.takeLast();
        // qsizetype
        QString section = keypath_list.join("/");

        restructured_map[section][key] = i->second;
        // restructured_map.insert(section, QMap<>);
    };

    // qDebug() << "Writing: " <<
    qDebug() << "Restructured map: " << restructured_map << "\n\n";

    // QChar openbr = '[';

    for (auto i = restructured_map.constKeyValueBegin();
         i != restructured_map.constKeyValueEnd(); ++i) {
        const QString key = i->first;
        const QByteArray section = ("[" + key.toLocal8Bit() + "]\n");

        qDebug() << "In section: " << section;
        std::cout << "std::string: " << key.toStdString() << std::endl;
        qDebug() << "utf: " << key.toUtf8() << "\n";
        device.write(section);

        // QMapIterator<QString, QVariant>
        // section_iter(restructured_map[key]);
        for (auto j = restructured_map[key].constKeyValueBegin();
             j != restructured_map[key].constKeyValueEnd(); ++j) {
            // for (auto k = (j->second).constKeyValueBegin()) {

            // }
            // if () {  // check if toString exists
            // bool has_toString = requires(j) { j.toString(); };

            // qDebug() << j->second.canConvert<QStringList>();

            /////////////////
            std::string value;
            if (j->second.canConvert<QStringList>()) {
                QStringList valueList = j->second.value<QStringList>();

                value = valueList.join(",").toStdString();

            } else {
                value = j->second.toString().toStdString();
            }  ////////

            // } else {
            // qDebug() << "Error doesn't have a '.toString()'";
            // }
            auto kiy = j->first.toStdString();

            QString prop = (kiy + "=" + value + "\n").c_str();

            qDebug() << "In key: " << kiy.c_str()
                     << "With value: " << value.c_str();
            //  << "\nActuall contents"
            //  << prop << "\nTechnically: " << prop.toStdString().c_str();
            // std::cout << "\nstd::string: " << prop.toStdString();
            device.write(prop.toStdString().c_str());
        }
    }

    qDebug() << "[---------- end WRITING ---------]";
    // auto ret2 = QMessageBox(QMessageBox::Icon::Information,
    // QString("Paused"), QString("Preparing to Exit` Write"));
    // ret2.exec();
    return true;
}
