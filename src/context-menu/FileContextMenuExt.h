/* The code sample demonstrates creating a Shell context menu handler with C++.

A context menu handler is a shell extension handler that adds commands to an
existing context menu. Context menu handlers are associated with a particular
file class and are called any time a context menu is displayed for a member
of the class. While you can add items to a file class context menu with the
registry, the items will be the same for all members of the class. By
implementing and registering such a handler, you can dynamically add items to
an object's context menu, customized for the particular object.

The example context menu handler adds the menu item "Display File Name (C++)"
to the context menu when you right-click a .cpp file in the Windows Explorer.
Clicking the menu item brings up a message box that displays the full path
of the .cpp file. */

#pragma once

#include <shlobj.h>  // For IShellExtInit and IContextMenu
#include <windows.h>

#include "Customizer/settings.h"

#include <gdiplus.h>
#pragma comment(lib, "gdiplus.lib")

class FileContextMenuExt : public IShellExtInit, public IContextMenu {
   public:
    // IUnknown
    IFACEMETHODIMP QueryInterface(REFIID riid, void** ppv);
    IFACEMETHODIMP_(ULONG) AddRef();
    IFACEMETHODIMP_(ULONG) Release();

    // IShellExtInit
    IFACEMETHODIMP Initialize(LPCITEMIDLIST pidlFolder,
                              LPDATAOBJECT pDataObj,
                              HKEY hKeyProgID);

    // IContextMenu
    IFACEMETHODIMP QueryContextMenu(HMENU hMenu,
                                    UINT indexMenu,
                                    UINT idCmdFirst,
                                    UINT idCmdLast,
                                    UINT uFlags);
    IFACEMETHODIMP InvokeCommand(LPCMINVOKECOMMANDINFO pici);
    IFACEMETHODIMP GetCommandString(UINT_PTR idCommand,
                                    UINT uFlags,
                                    UINT* pwReserved,
                                    LPSTR pszName,
                                    UINT cchMax);

    FileContextMenuExt(void);

   protected:
    ~FileContextMenuExt(void);

   private:
    // Reference count of component.
    long m_cRef;

    // The name of the selected file.
    wchar_t m_szSelectedFile[MAX_PATH];

    // The method that handles the "display" verb.
    void OnSubMenuItemSelected(HWND hWnd, int itemId);

    void OnVerbDisplayFileName(HWND hWnd);

    Settings settings;

    HBITMAP ImagesDump[50];

    PCWSTR m_pszMenuText;
    HBITMAP m_hMenuBmp;
    PCSTR m_pszVerb;
    PCWSTR m_pwszVerb;
    PCSTR m_pszVerbCanonicalName;
    PCWSTR m_pwszVerbCanonicalName;
    PCSTR m_pszVerbHelpText;
    PCWSTR m_pwszVerbHelpText;

    Gdiplus::GdiplusStartupInput gdiplusStartupInput;
    ULONG_PTR gdiplusToken;

    wchar_t filePath[MAX_PATH];
};