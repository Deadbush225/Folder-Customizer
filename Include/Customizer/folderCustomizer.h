#pragma once

#include <QtCore/QString>

#include "Customizer/icon_refresher.h"
#include "Customizer/tagger.h"

class FolderCustomizer {
   public:
    void static colorizeTag(QString folderPath,
                            QString tone,
                            QString color,
                            QString tag);
    void static reset(QString folderPath, bool resetIcon, bool resetTag);
};