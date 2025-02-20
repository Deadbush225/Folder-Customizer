#ifndef TAGGER_H
#define TAGGER_H

#include <QtCore/QByteArray>
#include <QtCore/QMap>
#include <QtCore/QMapIterator>
#include <QtCore/QtCore>
#include <QtWidgets/QMessageBox>

#include <QtCore/QSettings>

#include <experimental/type_traits>
#include <iostream>

#include <errhandlingapi.h>
#include <fileapi.h>

class DesktopIniManipulator {
   public:
    DesktopIniManipulator(QString folder);
    // void tagFolder(QString tag);

    void removeSection(QString section);
    void resetAllSection();

    void setHidden();

    QSettings* getInternalSettings();

   private:
    const QString* m_iniPath;
    const QSettings::Format* m_iniFormat;
    QSettings* m_iniSettings;

    bool static readDeskIniFile(QIODevice& device, QSettings::SettingsMap& map);
    bool static writeDeskIniFile(QIODevice& device,
                                 const QSettings::SettingsMap&);
};

class Tagger : DesktopIniManipulator {
   public:
    using DesktopIniManipulator::DesktopIniManipulator;

    void tagFolder(QString tag);
};

#endif