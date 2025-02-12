#pragma once

#include <QtCore/QString>
#include <iostream>

#include <windows.h>

#include "Customizer/settings.h"

class RegistryManipulator {
   public:
    void createRegistryKey(HKEY hKeyRoot,
                           LPCSTR subKey,
                           LPCSTR valueName,
                           LPCSTR value);
    void installRegistry();
    void uninstallRegistry();
};