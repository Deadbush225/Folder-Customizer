#include <iostream>

#include <QApplication>
#include <QColor>
#include <QIcon>
#include <QPalette>
#include <QWidget>
#include <Qt>

#include <stdio.h>
#include <windows.h>

#include "../Include/Window/window.h"

int main(int argc, char* argv[]) {
#if defined(Q_OS_WIN)
    // ::ShowWindow(::GetConsoleWindow(), SW_HIDE);  // hide console window
#endif

    auto app = new QApplication(argc, argv);
    QApplication::setWindowIcon(QIcon(":/icons/Folder Customizer.png"));

    QApplication::setStyle("Fusion");

    QPalette* dark_palette = new QPalette();
    dark_palette->setColor(QPalette::Window, QColor(53, 53, 53));
    dark_palette->setColor(QPalette::WindowText, Qt::white);
    dark_palette->setColor(QPalette::Base, QColor(35, 35, 35));
    dark_palette->setColor(QPalette::AlternateBase, QColor(53, 53, 53));
    dark_palette->setColor(QPalette::ToolTipBase, QColor(25, 25, 25));
    dark_palette->setColor(QPalette::ToolTipText, Qt::white);
    dark_palette->setColor(QPalette::Text, Qt::white);
    dark_palette->setColor(QPalette::Button, QColor(53, 53, 53));
    dark_palette->setColor(QPalette::ButtonText, Qt::white);
    dark_palette->setColor(QPalette::BrightText, Qt::red);
    dark_palette->setColor(QPalette::Link, QColor(42, 130, 218));
    dark_palette->setColor(QPalette::Highlight, QColor(42, 130, 218));
    dark_palette->setColor(QPalette::HighlightedText, QColor(35, 35, 35));
    dark_palette->setColor(QPalette::Active, QPalette::Button,
                           QColor(53, 53, 53));
    dark_palette->setColor(QPalette::Disabled, QPalette::ButtonText,
                           Qt::darkGray);
    dark_palette->setColor(QPalette::Disabled, QPalette::WindowText,
                           Qt::darkGray);
    dark_palette->setColor(QPalette::Disabled, QPalette::Text, Qt::darkGray);
    dark_palette->setColor(QPalette::Disabled, QPalette::Light,
                           QColor(53, 53, 53));
    QApplication::setPalette(*dark_palette);

    // FolderCustomizer.exe <Folder> -F Dark -C Red -T

    for (int i = 0; i < argc; i++) {
        qDebug() << argv[i];
    }

    // QString folderPath;
    // QString folderColor;
    // QString folderTextColor;

    // for (int i = 1; i < argc; ++i) {
    //     if (strcmp(argv[i], "-F") == 0 && i + 1 < argc) {
    //         folderColor = argv[++i];
    //     } else if (strcmp(argv[i], "-C") == 0 && i + 1 < argc) {
    //         folderTextColor = argv[++i];
    //     } else if (folderPath.isEmpty()) {
    //         folderPath = argv[i];
    //     } else {
    //         std::cerr << "Unknown option or argument: " << argv[i] << "\n";
    //         return 1;
    //     }
    // }

    FolderCustomizerWindow window = FolderCustomizerWindow();
    window.show();

    app->exec();
    delete app;
    // delete window;
};
