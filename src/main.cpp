#include <iostream>

#include <QtCore/Qt>
#include <QtGui/QColor>
#include <QtGui/QIcon>
#include <QtGui/QPalette>
#include <QtWidgets/QApplication>
#include <QtWidgets/QWidget>

#include <stdio.h>
#include <windows.h>
#include <boost/program_options.hpp>

#include "../Include/UserInterface/window.h"

namespace po = boost::program_options;

void setDarkTheme() {
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
}  // namespace boost::program

int main(int argc, char* argv[]) {
#if defined(Q_OS_WIN)
    ::ShowWindow(::GetConsoleWindow(), SW_HIDE);  // hide console window
#endif

    // FolderCustomizer.exe <Folder> -F Dark -C Red -T

    po::options_description desc("Allowed options");
    desc.add_options()("help,h", "produce help message")(
        "folder,F", po::value<std::string>(), "set folder path")(
        "tone,T", po::value<std::string>(), "set folder tone")(
        "color,C", po::value<std::string>(), "set folder color");

    po::variables_map vm;
    po::store(po::parse_command_line(argc, argv, desc), vm);
    po::notify(vm);

    if (vm.count("help")) {
        std::cout << desc << "\n";
        return 1;
    }

    QString folderPath;
    QString folderColor;
    QString folderTextColor;

    if (vm.count("folder")) {
        folderPath = QString::fromStdString(vm["folder"].as<std::string>());
    }
    if (vm.count("color")) {
        folderColor = QString::fromStdString(vm["color"].as<std::string>());
    }
    if (vm.count("tone")) {
        folderTextColor = QString::fromStdString(vm["tone"].as<std::string>());
    }

    // auto app = new QApplication(argc, argv);

    // // GUI
    // setDarkTheme();
    // QApplication::setWindowIcon(QIcon(":/icons/Folder Customizer.png"));

    // FolderCustomizerWindow window = FolderCustomizerWindow();
    // window.show();

    // app->exec();
    // delete app;
    // delete window;
};
