// #include "icon_refresher.h"n
#include <iostream>
#include <windows.h>
// #include <shlobj_core.h> 
#include <Shlobj.h>
#include <string>
#include <boost/program_options.hpp>

namespace po = boost::program_options;

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

LPWSTR str_to_lpwstr(std::string string) {
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

    std::string folder_path;
    std::string tone;
    std::string color;

    std::cout << "initialization" << std::endl;

    po::options_description desc("Arguments");
    desc.add_options()
        // Option 'buffer-size' and 'b' are equivalent. 
        ("h", doc::usage.c_str())

        ("f", po::value<std::string>(& folder_path), "The folders path")
        // Option 'priority' and 'p' are equivalent.
        ("t", po::value<std::string>(& tone)->default_value("Default"), "The tone to apply")
        // Option 'timeout' and 't' are equivalent.
        ("c", po::value<std::string>(& color)->default_value("Default"), "The color to apply")
        ;

    std::cout << " -f " << folder_path << " -t " << tone << " -c " << color << std::endl;

    po::variables_map vm;
    // po::store (po::command_line_parser (argc, argv).options (desc).run (), vm);
    po::store(po::parse_command_line(argc, argv, desc), vm);
    po::notify(vm);


    // if (vm.count("f")) {
    folder_path = vm["f"].as<std::string>();
    std::cout << "Folder path: " << folder_path << std::endl;
    // }

    // if (vm.count("t")) {
    tone = vm["t"].as<std::string>();
    std::cout << "Tone: " <<  tone << std::endl;
    // }

    // if (vm.count("c")) {
    color = vm["c"].as<std::string>();
    std::cout << "Color: " << color << std::endl;
    // }

    LPWSTR LPWSTR_folder_path = str_to_lpwstr(folder_path);
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

    std::string str = program_path + "\\Icons\\" + tone + "\\" + color + ".ico";
    std::cout << "str: " << str << std::endl;
    // std::mbstowcs(fcs.pszIconFile, str.c_str(), str.length());
    fcs.pszIconFile = str_to_lpwstr(str);
    fcs.cchIconFile = 0; // to write the whole string
    fcs.iIconIndex = 0;


    LPSHFOLDERCUSTOMSETTINGS pfcs = &fcs;

    SHGetSetFolderCustomSettings(pfcs, LPWSTR_folder_path, FCS_FORCEWRITE);

}

// #include <boost/program_options.hpp>
// #include <string>
// #include <iostream>
// namespace po = boost::program_options;
// int main(int argc, char** argv) {
//     // Arguments will be stored here
//     std::string input;
//     std::string output;
    
//     // Configure options here
//     po::options_description desc ("Allowed options");
//     desc.add_options ()
//         ("help,h", "print usage message")
//         ("input,i", po::value(&input), "Input file")
//         ("output,o", po::value(&output), "Output file");

//     // Parse command line arguments
//     po::variables_map vm;
//     po::store (po::command_line_parser (argc, argv).options (desc).run (), vm);
//     po::notify (vm);

//     // Check if there are enough args or if --help is given
//     if (vm.count ("help") || !vm.count ("input") || !vm.count ("output")) {
//         std::cerr << desc << "\n";
//         return 1;
//     }
//     std::cout << "The rest of the code will be here";
// }