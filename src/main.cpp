#include <iostream>

#include <QtCore/QCommandLineParser>
#include <QtCore/QDebug>
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
#if HAVE_BOOST_PROGRAM_OPTIONS
#include <boost/program_options.hpp>
#endif

#include "UserInterface/cli.h"
#include "UserInterface/window.h"

#if HAVE_BOOST_PROGRAM_OPTIONS
namespace po = boost::program_options;
#endif

int main(int argc, char* argv[]) {
    // FolderCustomizer <Folder> -F Dark -C Red -T

#if HAVE_BOOST_PROGRAM_OPTIONS
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
        return 0;
    }

#if (defined(_WIN32) && defined(NDEBUG))
    ::ShowWindow(::GetConsoleWindow(),
                 SW_HIDE);  // hide console window in release builds
#endif

    auto app = new QApplication(argc, argv);
    CLI* cli = nullptr;
    FolderCustomizerWindow* window = nullptr;

    if (vm.count("folder")) {
        cli = new CLI(vm);
    } else {
        QApplication::setWindowIcon(QIcon(":/icons/Folder Customizer.ico"));

        QPixmap pm(":/icons/Folder Customizer.ico");
        qDebug() << "Icon valid?" << !pm.isNull();

        window = new FolderCustomizerWindow();
        window->show();
    }

#else
    // Fallback: use Qt's QCommandLineParser if Boost is unavailable
    QCommandLineParser parser;
    parser.setApplicationDescription("Folder Customizer");
    parser.addHelpOption();
    QCommandLineOption folderOpt({"f", "folder"}, "set folder path", "path");
    QCommandLineOption toneOpt({"T", "tone"}, "set folder tone", "tone");
    QCommandLineOption colorOpt({"C", "color"}, "set folder color", "color");
    QCommandLineOption tagOpt({"L", "tag"}, "set folder tag", "tag");
    parser.addOption(folderOpt);
    parser.addOption(toneOpt);
    parser.addOption(colorOpt);
    parser.addOption(tagOpt);
    parser.process(*app);

    if (parser.isSet(folderOpt)) {
        // Build a minimal variables_map replacement for CLI ctor overload
        QString folderPath = parser.value(folderOpt);
        QString tone = parser.value(toneOpt);
        QString color = parser.value(colorOpt);
        QString tag = parser.value(tagOpt);

        // Directly apply customization without CLI helper (to avoid Boost
        // types)
        FolderCustomizer::colorizeTag(folderPath, tone, color, tag);
        return 0;
    } else {
        QIcon testIcon(":/icons/Folder Customizer.png");
        qDebug() << "Icon null?" << testIcon.isNull();
        QApplication::setWindowIcon(testIcon);

        QApplication::setWindowIcon(QIcon(":/icons/Folder Customizer.png"));
        window = new FolderCustomizerWindow();
        window->show();
    }
#endif

    app->exec();

    // clean up
    delete cli;
    delete window;
    delete app;
};
