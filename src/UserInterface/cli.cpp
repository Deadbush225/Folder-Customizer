#include "UserInterface/cli.h"

#if HAVE_BOOST_PROGRAM_OPTIONS
namespace po = boost::program_options;

CLI::CLI(po::variables_map vm) {
    QString folderPath;
    QString color;
    QString tone;
    QString tag;

    if (vm.count("folder")) {
        folderPath = QString::fromStdString(vm["folder"].as<std::string>());
    }
    if (vm.count("color")) {
        color = QString::fromStdString(vm["color"].as<std::string>());
    }
    if (vm.count("tone")) {
        tone = QString::fromStdString(vm["tone"].as<std::string>());
    }
    if (vm.count("tag")) {
        tag = QString::fromStdString(vm["tag"].as<std::string>());
    }

    qDebug() << "Customizing...";

    FolderCustomizer::colorizeTag(folderPath, tone, color, tag);

    qDebug() << "Quitting...";
    QApplication::quit();
    exit(0);
}
#else
// No Boost - no CLI implementation.
#endif