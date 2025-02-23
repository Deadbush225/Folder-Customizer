#include "Core/registry.h"
#include <cstdlib>

RegistryManipulator::RegistryManipulator() {
    char fullPath[MAX_PATH];
    GetModuleFileNameA(NULL, fullPath, MAX_PATH);
    std::string path(fullPath);
    size_t pos = path.find_last_of("\\/");
    directory = (std::string::npos == pos) ? "" : path.substr(0, pos);
}

void RegistryManipulator::installRegistry() {
    std::string command =
        "regsvr32.exe " + directory + "\\libFCContextMenuHandler.dll";
    system(command.c_str());
}

void RegistryManipulator::uninstallRegistry() {
    std::string command =
        "regsvr32.exe /u " + directory + "\\libFCContextMenuHandler.dll";
    system(command.c_str());
    ;
}