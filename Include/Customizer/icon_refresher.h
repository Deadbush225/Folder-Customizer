#ifndef ICON_REFRESHER_H
#define ICON_REFRESHER_H

#include <iostream>
// #include <windows.h>
#include <Shlobj.h>
#include <string>

#include <QtCore/QDebug>
#include <QtCore/QString>
// #include <boost/format.hpp>

// namespace po = boost::program_options;
// // typedef boost::format ftm;

// namespace doc {
// std::string usage = R"(
// icon_refresher.exe -f <folder path> [Options]

// Options:
//     -f, --folder-path   - the path of the folder where the effects will be
//     applied -t, --tag           - the tone to apply [Default, Light, Normal,
//     Dark] -c, --color         - the color to apply [Default, Red, Brown,
//     Orange, Lemon, Green, Azure, Blue, Pink, Violet, White, Gray, Black]

// Generic Options:
//     -h, --help, - to display this message
//     )";
// };

wchar_t* str_to_lpwstr_st(std::string string);
void changeIcon(QString folder_path, QString tone, QString color);

#endif