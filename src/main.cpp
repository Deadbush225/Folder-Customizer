
#include <iostream>

#include <QtWidgets/QApplication>

#include "Window/window.h"

int main(int argc, char* argv[]) {
    auto app = new QApplication(argc, argv);

    FolderCustomizerWindow window = FolderCustomizerWindow();
    window.show();

    app->exec();
    delete app;
    // delete window;
};