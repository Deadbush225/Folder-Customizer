#include "Core/registry.h"
#include <cstdlib>

#include <QtCore/QDebug>

RegistryManipulator::RegistryManipulator() {
    char executableFullPath[MAX_PATH];
    GetModuleFileNameA(NULL, executableFullPath, MAX_PATH);
    std::string path(executableFullPath);
    size_t pos = path.find_last_of("\\/");

    if (pos == std::string::npos) {
        // Log: Error

    } else {
        directory = R"(")" + path.substr(0, pos) + R"(\)" +
                    R"(libFCContextMenuHandler.dll")";
        qDebug() << directory;
    }
}

void RegistryManipulator::installRegistry() {
    std::string command = "regsvr32.exe " + directory;
    system(command.c_str());
}

void RegistryManipulator::uninstallRegistry() {
    std::string command = "regsvr32.exe /u " + directory;
    system(command.c_str());
}