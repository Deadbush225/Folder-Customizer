#include "FileContextMenuExt.h"
#include <Shlwapi.h>
#include <strsafe.h>

// #include "resource.h"
// #include "../../Include/Customizer/settings.h"
#include <string>
#include <vector>

#pragma comment(lib, "shlwapi.lib")

extern HINSTANCE g_hInst;
extern long g_cDllRef;

#define IDM_DISPLAY 0  // The command's identifier offset

FileContextMenuExt::FileContextMenuExt(void)
    : m_cRef(1),
      m_pszMenuText(L"&Display File Name (C++)"),
      m_pszVerb("cppdisplay"),
      m_pwszVerb(L"cppdisplay"),
      m_pszVerbCanonicalName("CppDisplayFileName"),
      m_pwszVerbCanonicalName(L"CppDisplayFileName"),
      m_pszVerbHelpText("Display File Name (C++)"),
      m_pwszVerbHelpText(L"Display File Name (C++)") {
    InterlockedIncrement(&g_cDllRef);

    settings = Settings::getInstance();

    int SUBMENU_IDENTIFIER = 0;

    for (int i = 0; i < settings.tones.size(); i++) {
        std::wstring toneWStr =
            std::wstring(settings.tones[i].begin(), settings.tones[i].end());

        for (int j = 0; j < settings.colors.size(); j++) {
            std::wstring colorWStr = std::wstring(settings.colors[j].begin(),
                                                  settings.colors[j].end());

            std::wstring iconpath =
                (L"D:\\System\\Coding\\Projects\\folder-customizer\\Icons\\" +
                 toneWStr + L"\\BMP\\" + colorWStr + L".bmp");

            ImagesDump[SUBMENU_IDENTIFIER] = (HBITMAP)LoadImage(
                g_hInst,

                iconpath.c_str(), IMAGE_BITMAP, 0, 0,
                LR_LOADFROMFILE | LR_DEFAULTSIZE | LR_LOADTRANSPARENT);

            SUBMENU_IDENTIFIER++;
        }
    }

    // Load the bitmap for the menu item.
    // If you want the menu item bitmap to be transparent, the color depth of
    // the bitmap must not be greater than 8bpp.
    m_hMenuBmp = (HBITMAP)LoadImage(
        g_hInst,
        L"D:\\System\\Coding\\Projects\\folder-"
        L"customizer\\Icons\\Normal\\BMP\\Orange.bmp",
        IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE | LR_DEFAULTSIZE);

    // m_hMenuBmp = LoadImage(g_hInst, MAKEINTRESOURCE(L"OK.bmp"), IMAGE_BITMAP,
    // 0,
    //    0, LR_DEFAULTSIZE | LR_LOADTRANSPARENT);
}

FileContextMenuExt::~FileContextMenuExt(void) {
    if (m_hMenuBmp) {
        DeleteObject(m_hMenuBmp);
        m_hMenuBmp = NULL;
    }

    InterlockedDecrement(&g_cDllRef);
}

void FileContextMenuExt::OnVerbDisplayFileName(HWND hWnd) {
    wchar_t szMessage[300];
    if (SUCCEEDED(StringCchPrintf(szMessage, ARRAYSIZE(szMessage),
                                  L"The selected file is:\r\n\r\n%s",
                                  this->m_szSelectedFile))) {
        MessageBox(hWnd, szMessage, L"CppShellExtContextMenuHandler", MB_OK);
    }
}

void FileContextMenuExt::OnSubMenuItemSelected(HWND hWnd, int itemId) {
    unsigned int tone, color;

    tone = itemId / 12;
    color = itemId % 12;

    // wchar_t szMessage[300];
    std::string message = settings.tones[tone] + " " + settings.colors[color];

    // HRESULT ret = StringCchPrintf(
    //     szMessage, ARRAYSIZE(szMessage), L"id: %d tone: %s color: %s",
    //     itemId, settings.tones[tone].c_str(),
    //     settings.colors[color].c_str());

    // if (SUCCEEDED(ret)) {
    std::wstring wmessage(message.begin(), message.end());
    MessageBox(hWnd, wmessage.c_str(), L"CppShellExtContextMenuHandler", MB_OK);
    // }
}

#pragma region IUnknown

// Query to the interface the component supported.
IFACEMETHODIMP FileContextMenuExt::QueryInterface(REFIID riid, void** ppv) {
    static const QITAB qit[] = {
        QITABENT(FileContextMenuExt, IContextMenu),
        QITABENT(FileContextMenuExt, IShellExtInit),
        {0},
    };
    return QISearch(this, qit, riid, ppv);
}

// Increase the reference count for an interface on an object.
IFACEMETHODIMP_(ULONG) FileContextMenuExt::AddRef() {
    return InterlockedIncrement(&m_cRef);
}

// Decrease the reference count for an interface on an object.
IFACEMETHODIMP_(ULONG) FileContextMenuExt::Release() {
    ULONG cRef = InterlockedDecrement(&m_cRef);
    if (0 == cRef) {
        delete this;
    }

    return cRef;
}

#pragma endregion

#pragma region IShellExtInit

// Initialize the context menu handler.
IFACEMETHODIMP FileContextMenuExt::Initialize(LPCITEMIDLIST pidlFolder,
                                              LPDATAOBJECT pDataObj,
                                              HKEY hKeyProgID) {
    if (NULL == pDataObj) {
        return E_INVALIDARG;
    }

    HRESULT hr = E_FAIL;

    FORMATETC fe = {CF_HDROP, NULL, DVASPECT_CONTENT, -1, TYMED_HGLOBAL};
    STGMEDIUM stm;

    // The pDataObj pointer contains the objects being acted upon. In this
    // example, we get an HDROP handle for enumerating the selected files
    // and folders.
    if (SUCCEEDED(pDataObj->GetData(&fe, &stm))) {
        // Get an HDROP handle.
        HDROP hDrop = static_cast<HDROP>(GlobalLock(stm.hGlobal));
        if (hDrop != NULL) {
            // Determine how many files are involved in this operation. This
            // code sample displays the custom context menu item when only
            // one file is selected.
            UINT nFiles = DragQueryFile(hDrop, 0xFFFFFFFF, NULL, 0);
            if (nFiles == 1) {
                // Get the path of the file.
                if (0 != DragQueryFile(hDrop, 0, m_szSelectedFile,
                                       ARRAYSIZE(m_szSelectedFile))) {
                    hr = S_OK;
                }
            }

            GlobalUnlock(stm.hGlobal);
        }

        ReleaseStgMedium(&stm);
    }

    // If any value other than S_OK is returned from the method, the context
    // menu item is not displayed.
    return hr;
}

#pragma endregion

#pragma region IContextMenu

//
//   FUNCTION: FileContextMenuExt::QueryContextMenu
//
//   PURPOSE: The Shell calls IContextMenu::QueryContextMenu to allow the
//            context menu handler to add its menu items to the menu. It
//            passes in the HMENU handle in the hmenu parameter. The
//            indexMenu parameter is set to the index to be used for the
//            first menu item that is to be added.
//
IFACEMETHODIMP FileContextMenuExt::QueryContextMenu(HMENU hMenu,
                                                    UINT indexMenu,
                                                    UINT idCmdFirst,
                                                    UINT idCmdLast,
                                                    UINT uFlags) {
    // If uFlags include CMF_DEFAULTONLY then we should not do anything.
    if (CMF_DEFAULTONLY & uFlags) {
        return MAKE_HRESULT(SEVERITY_SUCCESS, 0, USHORT(0));
    }

    // Create submenus
    HMENU rootMenu = CreateMenu();

    int SUBMENU_IDENTIFIER = 0;

    for (int i = 0; i < settings.tones.size(); i++) {
        HMENU hSubMenu = CreateMenu();

        std::wstring toneWStr =
            std::wstring(settings.tones[i].begin(), settings.tones[i].end());

        InsertMenu(rootMenu, i, MF_BYPOSITION | MF_POPUP, (UINT_PTR)hSubMenu,
                   toneWStr.c_str());

        for (int j = 0; j < settings.colors.size(); j++) {
            std::wstring colorWStr = std::wstring(settings.colors[j].begin(),
                                                  settings.colors[j].end());
            InsertMenu(hSubMenu, j, MF_BYPOSITION,
                       idCmdFirst + SUBMENU_IDENTIFIER, colorWStr.c_str());

            MENUITEMINFO mii = {sizeof(MENUITEMINFO)};
            mii.fMask = MIIM_BITMAP;
            mii.hbmpItem = ImagesDump[SUBMENU_IDENTIFIER];

            SetMenuItemInfo(hSubMenu, j, TRUE, &mii);

            SUBMENU_IDENTIFIER++;
        }
    }

    InsertMenu(hMenu, indexMenu, MF_BYPOSITION | MF_POPUP, (UINT_PTR)rootMenu,
               L"Folder Colorizer 1");

    // Set the icon for the menu item
    MENUITEMINFO mii = {sizeof(MENUITEMINFO)};
    mii.fMask = MIIM_BITMAP;
    mii.hbmpItem = m_hMenuBmp;
    SetMenuItemInfo(hMenu, indexMenu, TRUE, &mii);

    // Return an HRESULT value with the severity set to SEVERITY_SUCCESS.
    // Set the code value to the offset of the largest command identifier
    // that was assigned, plus one (1).
    return MAKE_HRESULT(SEVERITY_SUCCESS, 0, USHORT(SUBMENU_IDENTIFIER + 1));
}

//
//   FUNCTION: FileContextMenuExt::InvokeCommand
//
//   PURPOSE: This method is called when a user clicks a menu item to tell
//            the handler to run the associated command. The lpcmi parameter
//            points to a structure that contains the needed information.
//
IFACEMETHODIMP FileContextMenuExt::InvokeCommand(LPCMINVOKECOMMANDINFO pici) {
    BOOL fUnicode = FALSE;

    // Determine which structure is being passed in, CMINVOKECOMMANDINFO or
    // CMINVOKECOMMANDINFOEX based on the cbSize member of lpcmi. Although
    // the lpcmi parameter is declared in Shlobj.h as a CMINVOKECOMMANDINFO
    // structure, in practice it often points to a CMINVOKECOMMANDINFOEX
    // structure. This struct is an extended version of CMINVOKECOMMANDINFO
    // and has additional members that allow Unicode strings to be passed.
    if (pici->cbSize == sizeof(CMINVOKECOMMANDINFOEX)) {
        if (pici->fMask & CMIC_MASK_UNICODE) {
            fUnicode = TRUE;
        }
    }

    // Determines whether the command is identified by its offset or verb.
    // There are two ways to identify commands:
    //
    //   1) The command's verb string
    //   2) The command's identifier offset
    //
    // If the high-order word of lpcmi->lpVerb (for the ANSI case) or
    // lpcmi->lpVerbW (for the Unicode case) is nonzero, lpVerb or lpVerbW
    // holds a verb string. If the high-order word is zero, the command
    // offset is in the low-order word of lpcmi->lpVerb.

    // For the ANSI case, if the high-order word is not zero, the command's
    // verb string is in lpcmi->lpVerb.
    // MessageBox(pici->hwnd, L"Invoke Command", L"Invoke Command", MB_OK);

    if (!fUnicode && HIWORD(pici->lpVerb)) {
        MessageBox(pici->hwnd, L"Test 1", L"Test 1", MB_OK);

        // Is the verb supported by this context menu extension?
        if (StrCmpIA(pici->lpVerb, m_pszVerb) == 0) {
            OnVerbDisplayFileName(pici->hwnd);
        } else {
            // If the verb is not recognized by the context menu handler, it
            // must return E_FAIL to allow it to be passed on to the other
            // context menu handlers that might implement that verb.
            return E_FAIL;
        }
    }

    // For the Unicode case, if the high-order word is not zero, the
    // command's verb string is in lpcmi->lpVerbW.
    else if (fUnicode && HIWORD(((CMINVOKECOMMANDINFOEX*)pici)->lpVerbW)) {
        MessageBox(pici->hwnd, L"Test 2", L"Test 2", MB_OK);
        // Is the verb supported by this context menu extension?
        if (StrCmpIW(((CMINVOKECOMMANDINFOEX*)pici)->lpVerbW, m_pwszVerb) ==
            0) {
            OnVerbDisplayFileName(pici->hwnd);
        } else {
            // If the verb is not recognized by the context menu handler, it
            // must return E_FAIL to allow it to be passed on to the other
            // context menu handlers that might implement that verb.
            return E_FAIL;
        }
    }

    // If the command cannot be identified through the verb string, then
    // check the identifier offset.
    else {
        // Is the command identifier offset supported by this context menu
        // extension?
        MessageBox(pici->hwnd, L"Test 3", L"Test 3", MB_OK);

        // if (LOWORD(pici->lpVerb) == IDM_DISPLAY) {
        // OnVerbDisplayFileName(pici->hwnd);
        // } else
        if (LOWORD(pici->lpVerb) >= 0 && LOWORD(pici->lpVerb) <= 40) {
            OnSubMenuItemSelected(pici->hwnd, LOWORD(pici->lpVerb));
        } else {
            // If the verb is not recognized by the context menu handler, it
            // must return E_FAIL to allow it to be passed on to the other
            // context menu handlers that might implement that verb.
            return E_FAIL;
        }
    }

    return S_OK;
}

//
//   FUNCTION: CFileContextMenuExt::GetCommandString
//
//   PURPOSE: If a user highlights one of the items added by a context menu
//            handler, the handler's IContextMenu::GetCommandString method
//            is called to request a Help text string that will be displayed
//            on the Windows Explorer status bar. This method can also be
//            called to request the verb string that is assigned to a
//            command. Either ANSI or Unicode verb strings can be requested.
//            This example only implements support for the Unicode values of
//            uFlags, because only those have been used in Windows Explorer
//            since Windows 2000.
//
IFACEMETHODIMP FileContextMenuExt::GetCommandString(UINT_PTR idCommand,
                                                    UINT uFlags,
                                                    UINT* pwReserved,
                                                    LPSTR pszName,
                                                    UINT cchMax) {
    HRESULT hr = E_INVALIDARG;

    if (idCommand == IDM_DISPLAY) {
        switch (uFlags) {
            case GCS_HELPTEXTW:
                // Only useful for pre-Vista versions of Windows that have a
                // Status bar.
                hr = StringCchCopy(reinterpret_cast<PWSTR>(pszName), cchMax,
                                   m_pwszVerbHelpText);
                break;

            case GCS_VERBW:
                // GCS_VERBW is an optional feature that enables a caller to
                // discover the canonical name for the verb passed in
                // through idCommand.
                hr = StringCchCopy(reinterpret_cast<PWSTR>(pszName), cchMax,
                                   m_pwszVerbCanonicalName);
                break;

            default:
                hr = S_OK;
        }
    }

    // If the command (idCommand) is not supported by this context menu
    // extension handler, return E_INVALIDARG.

    return hr;
}

#pragma endregion