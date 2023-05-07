#include "icon_refresher.h"

wchar_t* str_to_lpwstr_st(std::string string) {
    std::cout << "Function called" << std::endl;

    const char* CHAR_string = string.c_str();
    size_t CHAR_string_len = strlen(CHAR_string) + 1;

    wchar_t* WCHART_string = new wchar_t[CHAR_string_len];
    std::mbstowcs(WCHART_string, CHAR_string, CHAR_string_len);

    return WCHART_string;
}

void changeIcon(QString folder_path, QString tone, QString color) {
    // std::string folder_path;
    // std::string tone;
    // std::string color;

    // std::cout << "initialization" << std::endl;

    // po::options_description desc("Optional Arguments");
    // desc.add_options()("help,h", "display help message")(
    //     "folder-path,f", po::value<std::string>(&folder_path),
    //     "The folders path")(
    //     "tone,t", po::value<std::string>(&tone)->default_value("Default"),
    //     "The tone to apply")(
    //     "color,c", po::value<std::string>(&color)->default_value("Default"),
    //     "The color to apply");

    // po::variables_map vm;
    // po::store(po::parse_command_line(argc, argv, desc), vm);
    // po::notify(vm);

    // if (vm.count("help")) {
    //     std::cout << doc::usage << "\n";
    //     return 0;
    // }

    /*
     * [0] - exe path
     * [1] - folder path
     * [2] - tone
     * [3] - color
     * [4] - tag
     */

    // std::cout << argc << std::endl;
    // std::cout << "arguments:" << argv[0] << " " << argv[1] << " " << argv[2]
    // << " " << argv[3] << std::endl;

    QString program_path = "C:\\Program Files\\Folder Customizer";
    QString strin = program_path + "\\Icons\\" + tone + "\\" + color + ".ico";
    // qDebug() << "C:\\Program Files\\Folder Customizer\\Icons\\" + tone + "\\"
    // +
    //                 color + ".ico"
    //          << "\n";
    // qDebug() << strin;

    // LPCWSTR LPWSTR_folder_path = str_to_lpwstr_st(folder_path);
    const wchar_t* wchar_t_folder_path = folder_path.toStdWString().c_str();
    // qDebug() << "wchar_t" << wchar_t_folder_path;
    LPCWSTR LPWSTR_folder_path = wchar_t_folder_path;
    // qDebug() << LPWSTR_folder_path;

    // LPCWSTR LPWSTR_folder_path = L"C:\\Users\\Eliaz\\Desktop\\NF";
    // std::wstring wstring = StringToWString(folder_path);

    SHFOLDERCUSTOMSETTINGS fcs;

    fcs.dwSize = sizeof(SHFOLDERCUSTOMSETTINGS);
    fcs.dwMask = FCSM_ICONFILE;

    // LPWSTR LPWSTR_icon_path = str_to_lpwstr_st(strin);
    LPWSTR LPWSTR_icon_path =
        const_cast<wchar_t*>(strin.toStdWString().c_str());
    fcs.pszIconFile = LPWSTR_icon_path;
    fcs.cchIconFile = 0;  // to write the whole string
    fcs.iIconIndex = 0;

    LPSHFOLDERCUSTOMSETTINGS pfcs = &fcs;

    HRESULT ret =
        SHGetSetFolderCustomSettings(pfcs, LPWSTR_folder_path, FCS_FORCEWRITE);

    // std::cout << ret << std::endl;
}

// int main(int argc, char const* argv[]) {
//     changeIcon("C:\\Users\\Eliaz\\Desktop\\Test", "Light", "Red");
//     return 0;
// }
