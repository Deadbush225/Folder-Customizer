
#include <iostream>

#include <QtWidgets/QApplication>
// #include <QtWidgets/QWidget>

// #include <QtCore/QDebug>

#include <stdio.h>
#include <windows.h>

#include "Window/window.h"

int main(int argc, char* argv[]) {
#if defined(Q_OS_WIN)
    ::ShowWindow(::GetConsoleWindow(), SW_HIDE);  // hide console window
#endif

    auto app = new QApplication(argc, argv);

    FolderCustomizerWindow window = FolderCustomizerWindow();
    window.show();

    // QWidget window = QWidget();
    // window.show();

    // qDebug() << "test";

    app->exec();
    delete app;
    // delete window;
};