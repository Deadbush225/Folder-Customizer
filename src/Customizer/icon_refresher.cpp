#include "Customizer/icon_refresher.h"

wchar_t* str_to_lpwstr_st(std::string string) {
    std::cout << "Function called" << std::endl;

    const char* CHAR_string = string.c_str();
    size_t CHAR_string_len = strlen(CHAR_string) + 1;

    wchar_t* WCHART_string = new wchar_t[CHAR_string_len];
    std::mbstowcs(WCHART_string, CHAR_string, CHAR_string_len);

    return WCHART_string;
}

void changeIcon(QString folder_path, QString tone, QString color) {
    /*
     * [0] - exe path
     * [1] - folder path
     * [2] - tone
     * [3] - color
     */

    QString program_path = "C:\\Program Files\\Folder Customizer";
    QString strin = program_path + "\\Icons\\" + tone + "\\" + color + ".ico";

    // const wchar_t* wchar_t_folder_path = folder_path.toStdWString().c_str();
    // qDebug() << "wchar_t" << wchar_t_folder_path;
    // LPCWSTR LPWSTR_folder_path = wchar_t_folder_path;

    LPCWSTR LPWSTR_folder_path = str_to_lpwstr_st(folder_path.toStdString());
    // qDebug() << LPWSTR_folder_path;

    SHFOLDERCUSTOMSETTINGS fcs;

    fcs.dwSize = sizeof(SHFOLDERCUSTOMSETTINGS);
    fcs.dwMask = FCSM_ICONFILE;

    // LPWSTR LPWSTR_icon_path = str_to_lpwstr_st(strin);
    LPWSTR LPWSTR_icon_path = str_to_lpwstr_st(strin.toStdString());
    // const_cast<wchar_t*>(strin.toStdWString().c_str());
    fcs.pszIconFile = LPWSTR_icon_path;
    fcs.cchIconFile = 0;  // to write the whole string
    fcs.iIconIndex = 0;

    LPSHFOLDERCUSTOMSETTINGS pfcs = &fcs;

    const HRESULT ret =
        SHGetSetFolderCustomSettings(pfcs, LPWSTR_folder_path, FCS_FORCEWRITE);

    // std::cout << ret << std::endl;

    delete LPWSTR_folder_path;
    delete LPWSTR_icon_path;
}
