#pragma once

#include <QtCore/QString>
#include <iostream>

#ifdef _WIN32
#include <windows.h>
#endif

#include "Customizer/settings.h"

class RegistryManipulator {
   public:
    RegistryManipulator();
    void installRegistry();
    void uninstallRegistry();

   private:
    std::string directory;
};