// #include "icon_refresher.h"n
#include <iostream>
// #include <windows.h>
// #include <shlobj_core.h> 
#include <Shlobj.h>
#include <string>
#include <boost/program_options.hpp>
// #include <boost/format.hpp>

// #include <typeinfo.h>

namespace po = boost::program_options;
// typedef boost::format ftm;

namespace doc {
    std::string usage = R"(
icon_refresher.exe -f <folder path> [Options]
        
Options:
    -f, --folder-path   - the path of the folder where the effects will be applied
    -t, --tag           - the tone to apply [Default, Light, Normal, Dark]
    -c, --color         - the color to apply [Default, Red, Brown, Orange, Lemon, Green, Azure, Blue, Pink, Violet, White, Gray, Black]

Generic Options:    
    -h, --help, - to display this message
    )";
};

wchar_t* str_to_lpwstr_st(std::string string) {
    // LPWSTR lpwstr;
    std::cout << "Function called" << std::endl;
    // std::cout << string.length();
    // std::cout << string.c_str();
    // std::cout << strlen(string.c_str());

    const char * CHAR_string = string.c_str();
    size_t CHAR_string_len = strlen(CHAR_string) + 1;

    wchar_t* WCHART_string = new wchar_t[CHAR_string_len];
    // LPWSTR WCHART_folder_path;
    // std::mbstowcs(WCHART_folder_path, folder_path.c_str(), folder_path.length());
    std::mbstowcs(WCHART_string, CHAR_string, CHAR_string_len);

    // wchar_t lpwstr[string.length()];
    // std::mbstowcs(lpwstr, string.c_str(), string.length());
    return WCHART_string;
}

int main(int argc, char* argv[]) {
    /*
     * [0] - exe path
     * [1] - folder path
     * [2] - tone
     * [3] - color
     * [4] - tag
     */

    std::cout << argc << std::endl;
    // std::cout << "arguments:" << argv[0] << " " << argv[1] << " " << argv[2] << " " << argv[3] << std::endl;

    std::string folder_path;
    std::string tone;
    std::string color;

    std::cout << "initialization" << std::endl;

    po::options_description desc("Optional Arguments");
    desc.add_options()
        // Option 'buffer-size' and 'b' are equivalent. 
        ("help,h", "display help message")

        ("folder-path,f", po::value<std::string>(& folder_path), "The folders path")
        // Option 'priority' and 'p' are equivalent.
        ("tone,t", po::value<std::string>(& tone)->default_value("Default"), "The tone to apply")
        // Option 'timeout' and 't' are equivalent.
        ("color,c", po::value<std::string>(& color)->default_value("Default"), "The color to apply")
        ;

    po::variables_map vm;
    po::store(po::parse_command_line(argc, argv, desc), vm);
    po::notify(vm);

    if (vm.count("help")) {
        std::cout << doc::usage << "\n";
        return 1;
    }

    std::string program_path = "C:\\Program Files\\Folder Customizer";
    std::string strin = program_path + "\\Icons\\" + tone + "\\" + color + ".ico";
    std::cout << "C:\\Program Files\\Folder Customizer\\Icons\\" + tone + "\\" + color + ".ico" << std::endl;
   
    // const char * CHAR_folder_path = folder_path.c_str();
    // size_t CHAR_folder_path_len = strlen(CHAR_folder_path) + 1;

    // wchar_t WCHART_folder_path[CHAR_folder_path_len];
    // LPWSTR WCHART_folder_path;
    // std::mbstowcs(WCHART_folder_path, folder_path.c_str(), folder_path.length());
    // std::mbstowcs(WCHART_folder_path, CHAR_folder_path, CHAR_folder_path_len);
    // LPCWSTR LPWSTR_folder_path = WCHART_folder_path;
    // wchar_t* LPWSTR_folder_path1 = WCHART_folder_path;

    LPCWSTR LPWSTR_folder_path = str_to_lpwstr_st(folder_path);

    // LPCWSTR LPWSTR_folder_path = L"C:\\Users\\Eliaz\\Desktop\\NF";
    // std::wstring wstring = StringToWString(folder_path);

    SHFOLDERCUSTOMSETTINGS fcs;

    fcs.dwSize = sizeof(SHFOLDERCUSTOMSETTINGS); // <---------
    fcs.dwMask = FCSM_ICONFILE; // <---------

    // wchar_t* LPWSTR_icon_path;

    // LPWSTR LPWSTR_icon_path = StringToWString(strin);
    
    // const char* CHAR_icon_path = strin.c_str();
    // size_t CHAR_icon_path_len = strlen(CHAR_icon_path) + 1;

    // wchar_t WCHART_icon_path[CHAR_icon_path_len];
    // LPWSTR WCHART_icon_path;
    // std::mbstowcs(WCHART_icon_path, CHAR_icon_path, CHAR_icon_path_len);
    LPWSTR LPWSTR_icon_path = str_to_lpwstr_st(strin);
    // wchar_t* LPWSTR_icon_path1 = WCHART_icon_path;
    
    // LPWSTR LPWSTR_icon_path = L"C:\\Program Files\\Folder Customizer\\Icons\\Light\\Red.ico";

    //

    // str_to_lpwstr_st(LPWSTR_icon_path, strin);
    fcs.pszIconFile = LPWSTR_icon_path;

    // fcs.pszIconFile = str_to_lpwstr_st(strin); // <---------
    fcs.cchIconFile = 0; // to write the whole string // <---------
    fcs.iIconIndex = 0; // <---------

    LPSHFOLDERCUSTOMSETTINGS pfcs = &fcs; // <---------

    HRESULT ret = SHGetSetFolderCustomSettings(pfcs, LPWSTR_folder_path, FCS_FORCEWRITE); // <---------

    std::cout << ret << std::endl;

}