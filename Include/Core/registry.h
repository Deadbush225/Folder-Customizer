#pragma once

#include <QtCore/QString>
#include <iostream>

#include <windows.h>

#include "Customizer/settings.h"

class RegistryManipulator {
   public:
    RegistryManipulator();
    void installRegistry();
    void uninstallRegistry();

   private:
    std::string directory;
};