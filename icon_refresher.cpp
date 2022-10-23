#include "icon_refresher.h"

namespace po = boost::program_options;

// arg

int main(int argc, char* argv[]) {



    std::cout << "Arguments:" << " [0] " << argv[0] << " [1] " << argv[1] << " [2] " << argv[2] << " [3] " << argv[3] << std::endl;

    SHFOLDERCUSTOMSETTINGS fcs;
    // pfcs = &fcs;

    fcs.dwSize = sizeof(SHFOLDERCUSTOMSETTINGS);
    fcs.dwMask = FCSM_ICONFILE;

    // wchar_t wtext[20];
    // std::mbstowcs(wtext, text.c_str(), text.length());//includes null
    // LPWSTR ptr = wtext;

    fcs.pszIconFile = L"D:\\CODING RELATED\\Projects\\Folder Customizer\\Source Code (py)\\Icons\\Dark\\Orange.ico";
    fcs.cchIconFile = 0; // to write the whole string
    fcs.iIconIndex = 0;

    LPSHFOLDERCUSTOMSETTINGS pfcs = &fcs;

    SHGetSetFolderCustomSettings(pfcs, L"C:\\Users\\Eliaz\\Desktop\\New folder", FCS_FORCEWRITE);


    // std::cout << "Am I still worthy?";
}

// make a make file later