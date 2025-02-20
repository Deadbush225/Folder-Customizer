#include "Customizer/folderCustomizer.h"

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
        changeIcon(folderPath, tone, color);
    }
}

void FolderCustomizer::reset(QString folderPath,
                             bool resetIcon,
                             bool resetTag) {
    DesktopIniManipulator* desktopManip = new DesktopIniManipulator(folderPath);

    if (resetIcon) {
        qDebug() << "Reseting icon";
        desktopManip->removeSection(".ShellClassInfo");
    }

    if (resetTag) {
        qDebug() << "Reseting tag";
        desktopManip->removeSection("{F29F85E0-4FF9-1068-AB91-08002B27B3D9}");
    }
}