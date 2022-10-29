// #include "icon_refresher.h"n
#include <iostream>
// #include <windows.h>
// #include <shlobj_core.h> 
#include <Shlobj.h>
#include <string>
#include <boost/program_options.hpp>
#include <boost/format.hpp>

#include <typeinfo.h>

namespace po = boost::program_options;
typedef boost::format ftm;

namespace doc {
    std::string usage = R"(
icon_refresher.exe -f <folder path> [Options]
        
Options:
    -f, - the folder path that the effects will be applied
    -t, - the tone to apply [Default, Light, Normal, Dark]
    -c, - the color to apply [Default, Red, Brown, Orange, Lemon, Green, Azure, Blue, Pink, Violet, White, Gray, Black]

Generic Options:    
    -h, --help, - to display this message
    )";
};

LPWSTR str_to_lpwstr_st(std::string string) {
    LPWSTR lpwstr;
    std::mbstowcs(lpwstr, string.c_str(), string.length());
    return lpwstr;
}
// arg

int main(int argc, char* argv[]) {


    /*
     * [0] - exe path
     * [1] - folder path
     * [2] - tone
     * [3] - color
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
        // ("h", doc::usage.c_str())

        ("sasss,f", po::value<std::string>(& folder_path), "The folders path")
        // Option 'priority' and 'p' are equivalent.
        ("sass,t", po::value<std::string>(& tone)->default_value("Default"), "The tone to apply")
        // Option 'timeout' and 't' are equivalent.
        ("sas,c", po::value<std::string>(& color)->default_value("Default"), "The color to apply")
        ;

    po::variables_map vm;
    po::store(po::parse_command_line(argc, argv, desc), vm);
    po::notify(vm);

    std::cout << " -f " << folder_path << " -t " << tone << " -c " << color << std::endl;

    std::cout << "Folder path: " << folder_path << std::endl;
    

    std::cout << " -f " << folder_path << " -t " << tone << " -c " << color << std::endl;

    LPWSTR LPWSTR_folder_path = str_to_lpwstr_st(folder_path);
    // std::cout << "Arguments:" << " [0] " << argv[0] << " [1] " << argv[1] << " [2] " << argv[2] << " [3] " << argv[3] << std::endl;
    // std::cout << "Arguments:" << " folder_path[0] " << folder_path << " tone[1] " << tone << " color[2] " << color << std::endl;


    std::string program_path = "C:\\Program Files\\Folder Customizer";
    // std::string folder_path = argv[1];
    // std::string tone = "Light"; //argv[2];
    // std::string color = "Red";//argv[3];

    SHFOLDERCUSTOMSETTINGS fcs;
    // pfcs = &fcs;

    fcs.dwSize = sizeof(SHFOLDERCUSTOMSETTINGS);
    fcs.dwMask = FCSM_ICONFILE;

    // wchar_t wtext[20];
    // std::mbstowcs(wtext, text.c_str(), text.length());//includes null
    // LPWSTR ptr = wtext;

    
    std::string strin; 
    // strin = program_path + "\\Icons\\" + tone + "\\" + color + ".ico";
    strin.append(program_path); 
    strin.append("\\Icons\\"); 
    strin.append(tone); 
    strin.append("\\"); 
    strin.append(color); 
    strin.append(".ico");
    // std::string strin = (ftm("%1%\\Icons\\%2%\\%3%.ico") % program_path % tone % color).str();

    // std::cout << typeid(strin).name() << std::endl;

    std::cout << "C:\\Program Files\\Folder Customizer\\Icons\\Light\\Red.ico" << std::endl;
    std::cout << "str: " << strin << std::endl;

    fcs.pszIconFile = str_to_lpwstr_st(strin);
    fcs.cchIconFile = 0; // to write the whole string
    fcs.iIconIndex = 0;


    LPSHFOLDERCUSTOMSETTINGS pfcs = &fcs;

    SHGetSetFolderCustomSettings(pfcs, LPWSTR_folder_path, FCS_FORCEWRITE);

}