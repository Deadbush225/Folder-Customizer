#include <iostream>

#include <QtCore/Qt>
#include <QtGui/QColor>
#include <QtGui/QIcon>
#include <QtGui/QPalette>
#include <QtWidgets/QApplication>
#include <QtWidgets/QWidget>

#include <stdio.h>
#ifdef _WIN32
#include <windows.h>
#endif
#include <boost/program_options.hpp>

#include "UserInterface/cli.h"
#include "UserInterface/window.h"

namespace po = boost::program_options;

int main(int argc, char* argv[]) {
#if (defined(_WIN32) && !defined(_DEBUG))
    ::ShowWindow(::GetConsoleWindow(), SW_HIDE);  // hide console window
#endif

    // FolderCustomizer.exe <Folder> -F Dark -C Red -T

    po::options_description desc("Allowed options");
    desc.add_options()("help,h", "produce help message")(
        "folder,F", po::value<std::string>(), "set folder path")(
        "tone,T", po::value<std::string>(), "set folder tone")(
        "color,C", po::value<std::string>(), "set folder color")(
        "tag,L", po::value<std::string>(), "set folder tag");

    po::variables_map vm;
    po::store(po::parse_command_line(argc, argv, desc), vm);
    po::notify(vm);

    if (vm.count("help")) {
        std::cout << desc << "\n";
        return 1;
    }

    auto app = new QApplication(argc, argv);

    CLI* cli = nullptr;
    FolderCustomizerWindow* window = nullptr;

    if (vm.count("folder")) {
        cli = new CLI(vm);
    } else {
        QApplication::setWindowIcon(QIcon(":/icons/Folder Customizer.png"));
        window = new FolderCustomizerWindow();
        window->show();
    }

    app->exec();

    // clean up
    delete cli;
    delete window;
    delete app;
};
