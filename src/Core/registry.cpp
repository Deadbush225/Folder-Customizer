#include "Core/registry.h"
#include <cstdlib>

#include <QtCore/QDebug>

#ifdef _WIN32
void executeCommand(const std::string& command) {
    STARTUPINFOA si = {sizeof(STARTUPINFOA)};
    PROCESS_INFORMATION pi = {};
    si.dwFlags = STARTF_USESHOWWINDOW;
    si.wShowWindow = SW_HIDE;  // Hide the window

    if (CreateProcessA(NULL, const_cast<char*>(command.c_str()), NULL, NULL,
                       FALSE, 0, NULL, NULL, &si, &pi)) {
        // Wait for the process to complete
        WaitForSingleObject(pi.hProcess, INFINITE);
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
    } else {
        // Log: Error
        qDebug() << "Failed to execute command.";
    }
}

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
        // qDebug() << directory;
    }
}

void RegistryManipulator::installRegistry() {
    executeCommand("regsvr32.exe " + directory);
}
void RegistryManipulator::uninstallRegistry() {
    executeCommand("regsvr32.exe /u " + directory);
}

#else
// Non-Windows: no-op implementations
RegistryManipulator::RegistryManipulator() {}
void RegistryManipulator::installRegistry() {}
void RegistryManipulator::uninstallRegistry() {}
#endif