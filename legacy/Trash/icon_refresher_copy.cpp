#include <iostream>
#include <Shlobj.h>
#include <string>

int main(int argc, char* argv[]) {

    std::string folder_path = "C:\\Users\\Eliaz\\Desktop\\NF";
    std::string tone = "Light";
    std::string color = "Red";

    std::string program_path = "C:\\Program Files\\Folder Customizer";
    std::string strin = program_path + "\\Icons\\" + tone + "\\" + color + ".ico";
    std::cout << "C:\\Program Files\\Folder Customizer\\Icons\\" + tone + "\\" + color + ".ico" << std::endl;
   
    // str_to_lpwstr_st(LPWSTR_folder_path, folder_path); // <--------- BUGGGGGGG
    // wchar_t* LPWSTR_folder_path; 

    const char * CHAR_folder_path = folder_path.c_str();
    size_t CHAR_folder_path_len = strlen(CHAR_folder_path) + 1;

    wchar_t WCHART_folder_path[CHAR_folder_path_len];
    // LPWSTR WCHART_folder_path;
    // std::mbstowcs(WCHART_folder_path, folder_path.c_str(), folder_path.length());
    std::mbstowcs(WCHART_folder_path, CHAR_folder_path, CHAR_folder_path_len);
    LPCWSTR LPWSTR_folder_path = WCHART_folder_path;

    // wchar_t* LPWSTR_folder_path1 = WCHART_folder_path;

    // LPCWSTR LPWSTR_folder_path = L"C:\\Users\\Eliaz\\Desktop\\NF";
    // std::wstring wstring = StringToWString(folder_path);

    SHFOLDERCUSTOMSETTINGS fcs;

    fcs.dwSize = sizeof(SHFOLDERCUSTOMSETTINGS); // <---------
    fcs.dwMask = FCSM_ICONFILE; // <---------

    // wchar_t* LPWSTR_icon_path;

    // LPWSTR LPWSTR_icon_path = StringToWString(strin);
    
    const char* CHAR_icon_path = strin.c_str();
    size_t CHAR_icon_path_len = strlen(CHAR_icon_path) + 1;

    wchar_t WCHART_icon_path[CHAR_icon_path_len];
    // LPWSTR WCHART_icon_path;
    std::mbstowcs(WCHART_icon_path, CHAR_icon_path, CHAR_icon_path_len);
    LPWSTR LPWSTR_icon_path = WCHART_icon_path;
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

    std::cout << "C:\\Program Files\\Folder Customizer\\Icons\\" + tone + "\\" + color + ".ico" << std::endl;
}