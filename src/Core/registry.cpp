#include "Core/registry.h"

void RegistryManipulator::createRegistryKey(HKEY hKeyRoot,
                                            LPCSTR subKey,
                                            LPCSTR valueName,
                                            LPCSTR value) {
    HKEY hKey;
    LONG result =
        RegCreateKeyExA(hKeyRoot, subKey, 0, NULL, REG_OPTION_NON_VOLATILE,
                        KEY_WRITE, NULL, &hKey, NULL);
    if (result == ERROR_SUCCESS) {
        RegSetValueExA(hKey, valueName, 0, REG_SZ, (const BYTE*)value,
                       strlen(value) + 1);
        RegCloseKey(hKey);
    } else {
        std::cerr << "Error creating registry key: " << result << std::endl;
    }
}

void RegistryManipulator::installRegistry() {
    auto settings = Settings::getInstance();

    // Setup context menu item for click on right panel
    std::string rootMenu =
        R"(Software\Classes\directory\shell\Folder Customizer)";

    // icon path
    createRegistryKey(
        HKEY_CURRENT_USER, rootMenu.c_str(), "icon",
        R"("C:\Program Files\Folder Customizer\Icons\Folder Customizer.ico")");
    // set up to have submenu
    createRegistryKey(HKEY_CURRENT_USER, rootMenu.c_str(), "SubCommands", "");

    // root name
    createRegistryKey(HKEY_CURRENT_USER, rootMenu.c_str(), "MUIVerb",
                      "Folder Customizer");

    // command
    std::string commandKey = rootMenu + R"(\command)";
    createRegistryKey(
        HKEY_CURRENT_USER, commandKey.c_str(), "",
        R"("C:\Program Files\Folder Customizer\Folder Customizer.exe" "%V")");

    for (std::string tone : settings.tones) {
        std::string toneKeyPath = rootMenu + "\\shell\\" + tone;
        createRegistryKey(HKEY_CURRENT_USER, toneKeyPath.c_str(), "", "");

        createRegistryKey(HKEY_CURRENT_USER, toneKeyPath.c_str(), "SubCommands",
                          "");

        for (std::string color : settings.colors) {
            std::string colorKeyPath =
                rootMenu + "\\shell\\" + tone + "\\shell\\" + color;
            createRegistryKey(HKEY_CURRENT_USER, colorKeyPath.c_str(), "", "");
        }
    }

    // Setup context menu item for click on folders tree item
    // createRegistryKey(
    //     HKEY_CURRENT_USER,
    //     R"(Software\Classes\directory\shell\Folder Customizer\command)", "",
    //     R"("C:\Program Files\Folder Customizer\Folder Customizer.exe"
    //     "%1")");
    // createRegistryKey(HKEY_CURRENT_USER,
    //                   R"(Software\Classes\directory\shell\Folder
    //                   Customizer)", "icon", R"("C:\Program Files\Folder
    //                   Customizer\Icons\Folder
    //     Customizer.ico")");
}

void RegistryManipulator::uninstallRegistry() {}