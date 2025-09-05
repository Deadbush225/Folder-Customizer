#ifndef TAGGER_H
#define TAGGER_H

#include <QtCore/QByteArray>
#include <QtCore/QMap>
#include <QtCore/QMapIterator>
#include <QtCore/QtCore>
#include <QtWidgets/QMessageBox>

#include <QtCore/QSettings>

#include <iostream>
#include <type_traits>

#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <errhandlingapi.h>
#include <fileapi.h>
#include <windows.h>
#endif

#ifdef _WIN32
class DesktopIniManipulator {
   public:
    DesktopIniManipulator(QString folder);
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
#endif

#ifdef _WIN32
class Tagger : DesktopIniManipulator {
   public:
    using DesktopIniManipulator::DesktopIniManipulator;
    void tagFolder(QString tag);
};
#else
// On non-Windows, Tagger writes the Comment to a .directory file in the folder
class Tagger {
   public:
    explicit Tagger(QString folder) : m_folder(std::move(folder)) {}
    void tagFolder(QString tag);

   private:
    QString m_folder;
};
#endif

#endif