import subprocess
# import os
# import ctypes
# from ctypes import POINTER, Structure, c_wchar, c_int, sizeof, byref
# from ctypes.wintypes import BYTE, WORD, DWORD, LPWSTR, LPSTR

# HICON = c_int
# LPTSTR = LPWSTR
# TCHAR = c_wchar
# MAX_PATH = 260  

# class GUID(Structure):
#     _fields_ = [
#         ('Data1', DWORD),
#         ('Data2', WORD),
#         ('Data3', WORD),
#         ('Data4', BYTE * 8)]

# class SHFOLDERCUSTOMSETTINGS(Structure):
#     _fields_ = [
#         ('dwSize', DWORD),
#         ('dwMask', DWORD),
#         ('pvid', POINTER(GUID)),
#         ('pszWebViewTemplate', LPTSTR),
#         ('cchWebViewTemplate', DWORD),
#         ('pszWebViewTemplateVersion', LPTSTR),
#         ('pszInfoTip', LPTSTR),
#         ('cchInfoTip', DWORD),
#         ('pclsid', POINTER(GUID)),
#         ('dwFlags', DWORD),
#         ('pszIconFile', LPTSTR),
#         ('cchIconFile', DWORD),
#         ('iIconIndex', c_int),
#         ('pszLogo', LPTSTR),
#         ('cchLogo', DWORD)]

# FCSM_ICONFILE = 0x00000010
# FCS_FORCEWRITE = 0x00000002
# STGM_READWRITE = 0x00000002

# def setIcon(folderpath, iconpath, iconindex):
#     """Set folder icon.

#     >>> seticon(".", "C:\\Windows\\system32\\SHELL32.dll", 10)

#     """
#     shell32 = ctypes.windll.shell32

#     fcs = SHFOLDERCUSTOMSETTINGS()
#     fcs.dwSize = sizeof(fcs)
#     fcs.dwMask = FCSM_ICONFILE
#     fcs.pszIconFile = iconpath
#     fcs.cchIconFile = 0
#     fcs.iIconIndex = iconindex
#     _clsid = fcs.pclsid

#     hr = shell32.SHGetSetFolderCustomSettings(byref(fcs), folderpath, FCS_FORCEWRITE)
    
#     # cr_gu = ole32.Create("{F29F85E0-4FF9-1068-AB91-08002B27B3D9}", _clsid, 0, STGM_READWRITE)
#     # rglpwstrName = ["Dark White"]
#     # rgpropid = ["prop5"]
#     # cpropid = sizeof(rgpropid)
#     # cr_wr = shell32.IPropertyStorage.WritePropertyNames(cpropid, rgpropid, rglpwstrName)

# # seticon(r"C:\Users\Eliaz\Desktop\New folder", r"C:\Program Files\Folder Customizer\Dark\Blue.ico", 0)

def setIcon(folder, iconpath, iconindex=0, default=False):
    if default: 
        subprocess.run([r"C:\Program Files\Folder Customizer\DeskEdit.exe", fr"/F={folder}", "/S=.ShellClassinfo", fr"/L=IconResource"])
    else:
        subprocess.run([r"C:\Program Files\Folder Customizer\DeskEdit.exe", fr"/F={folder}", "/S=.ShellClassinfo", fr"/L=IconResource={iconpath},0"])