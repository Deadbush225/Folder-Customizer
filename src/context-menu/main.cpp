#include <shlobj.h>
#include <windows.h>
#include <vector>

// Define the CLSID for the context menu handler
const CLSID CLSID_MyContextMenu = {
    0xf5b8e666,
    0x6638,
    0x4de6,
    {0xb1, 0xbb, 0x1e, 0xa5, 0xd0, 0xd9, 0xc7, 0x8c}};

class CMyContextMenu : public IContextMenu, public IShellExtInit {
   public:
    CMyContextMenu() : m_refCount(1) {}

    // IUnknown methods
    STDMETHODIMP QueryInterface(REFIID riid, void** ppv);
    STDMETHODIMP_(ULONG) AddRef();
    STDMETHODIMP_(ULONG) Release();

    // IContextMenu methods
    STDMETHODIMP QueryContextMenu(HMENU hMenu,
                                  UINT indexMenu,
                                  UINT idCmdFirst,
                                  UINT idCmdLast,
                                  UINT uFlags);
    STDMETHODIMP InvokeCommand(LPCMINVOKECOMMANDINFO pici);
    STDMETHODIMP GetCommandString(UINT_PTR idCmd,
                                  UINT uType,
                                  UINT* pReserved,
                                  LPSTR pszName,
                                  UINT cchMax);

    // IShellExtInit methods
    STDMETHODIMP Initialize(LPCITEMIDLIST pidlFolder,
                            IDataObject* pdtobj,
                            HKEY hkeyProgID);

   private:
    LONG m_refCount;
    void AddSubMenu(HMENU hMenu,
                    UINT indexMenu,
                    UINT idCmdFirst,
                    LPCTSTR name,
                    std::vector<LPCTSTR> items);
};

// Implementation of IUnknown methods
STDMETHODIMP CMyContextMenu::QueryInterface(REFIID riid, void** ppv) {
    if (IsEqualIID(riid, IID_IUnknown) || IsEqualIID(riid, IID_IContextMenu) ||
        IsEqualIID(riid, IID_IShellExtInit)) {
        *ppv = static_cast<IContextMenu*>(this);
        AddRef();
        return S_OK;
    }
    *ppv = nullptr;
    return E_NOINTERFACE;
}

STDMETHODIMP_(ULONG) CMyContextMenu::AddRef() {
    return InterlockedIncrement(&m_refCount);
}

STDMETHODIMP_(ULONG) CMyContextMenu::Release() {
    ULONG refCount = InterlockedDecrement(&m_refCount);
    if (refCount == 0) {
        delete this;
    }
    return refCount;
}

// Implementation of IShellExtInit::Initialize
STDMETHODIMP CMyContextMenu::Initialize(LPCITEMIDLIST pidlFolder,
                                        IDataObject* pdtobj,
                                        HKEY hkeyProgID) {
    return S_OK;
}

// Helper function to add sub-menus
void CMyContextMenu::AddSubMenu(HMENU hMenu,
                                UINT indexMenu,
                                UINT idCmdFirst,
                                LPCTSTR name,
                                std::vector<LPCTSTR> items) {
    HMENU hSubMenu = CreatePopupMenu();
    for (size_t i = 0; i < items.size(); ++i) {
        InsertMenu(hSubMenu, i, MF_BYPOSITION | MF_STRING, idCmdFirst + i,
                   items[i]);
    }
    InsertMenu(hMenu, indexMenu, MF_BYPOSITION | MF_POPUP, (UINT_PTR)hSubMenu,
               name);
}

// Implementation of IContextMenu::QueryContextMenu
STDMETHODIMP CMyContextMenu::QueryContextMenu(HMENU hMenu,
                                              UINT indexMenu,
                                              UINT idCmdFirst,
                                              UINT idCmdLast,
                                              UINT uFlags) {
    std::vector<LPCTSTR> colors = {TEXT("red"), TEXT("green"), TEXT("orange"),
                                   TEXT("violet"), TEXT("azure")};

    AddSubMenu(hMenu, indexMenu, idCmdFirst, TEXT("dark"), colors);
    AddSubMenu(hMenu, indexMenu + 1, idCmdFirst + 5, TEXT("light"), colors);
    AddSubMenu(hMenu, indexMenu + 2, idCmdFirst + 10, TEXT("normal"), colors);

    return MAKE_HRESULT(SEVERITY_SUCCESS, FACILITY_NULL,
                        15);  // Return the number of menu items added
}

// Implementation of IContextMenu::InvokeCommand
STDMETHODIMP CMyContextMenu::InvokeCommand(LPCMINVOKECOMMANDINFO pici) {
    int id = LOWORD(pici->lpVerb);
    switch (id) {
        case 0:
        case 1:
        case 2:
        case 3:
        case 4:  // dark colors
            MessageBox(pici->hwnd, TEXT("Dark color selected"),
                       TEXT("Context Menu"), MB_OK);
            break;
        case 5:
        case 6:
        case 7:
        case 8:
        case 9:  // light colors
            MessageBox(pici->hwnd, TEXT("Light color selected"),
                       TEXT("Context Menu"), MB_OK);
            break;
        case 10:
        case 11:
        case 12:
        case 13:
        case 14:  // normal colors
            MessageBox(pici->hwnd, TEXT("Normal color selected"),
                       TEXT("Context Menu"), MB_OK);
            break;
    }
    return S_OK;
}

// Implementation of IContextMenu::GetCommandString
STDMETHODIMP CMyContextMenu::GetCommandString(UINT_PTR idCmd,
                                              UINT uType,
                                              UINT* pReserved,
                                              LPSTR pszName,
                                              UINT cchMax) {
    if (uType == GCS_HELPTEXTA) {
        strncpy_s(pszName, cchMax, "Color selection item", _TRUNCATE);
        return S_OK;
    }
    return E_INVALIDARG;
}

// DLL entry point
extern "C" BOOL APIENTRY DllMain(HMODULE hModule,
                                 DWORD ul_reason_for_call,
                                 LPVOID lpReserved) {
    switch (ul_reason_for_call) {
        case DLL_PROCESS_ATTACH:
        case DLL_THREAD_ATTACH:
        case DLL_THREAD_DETACH:
        case DLL_PROCESS_DETACH:
            break;
    }
    return TRUE;
}

// Exported function to create the context menu handler
extern "C" HRESULT __stdcall DllGetClassObject(REFCLSID rclsid,
                                               REFIID riid,
                                               LPVOID* ppv) {
    if (IsEqualCLSID(rclsid, CLSID_MyContextMenu)) {
        CMyContextMenu* pContextMenu = new CMyContextMenu();
        return pContextMenu->QueryInterface(riid, ppv);
    }
    return CLASS_E_CLASSNOTAVAILABLE;
}

// Exported function to register the DLL
extern "C" HRESULT __stdcall DllRegisterServer() {
    // Registration code here
    return S_OK;
}

// Exported function to unregister the DLL
extern "C" HRESULT __stdcall DllUnregisterServer() {
    // Unregistration code here
    return S_OK;
}