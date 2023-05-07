    from ctypes import sizeof

    STGM_READWRITE = 0x00000002

    def addTag(folder):

        _clsid = None # should to be the CLSID from the SHFOLDERCUSTOMSETTINGS

        # ↓↓↓↓↓↓ I can't find where should I get IPropertySetStorage
        IPropertySetStorage.Create("{F29F85E0-4FF9-1068-AB91-08002B27B3D9}", _clsid, 0, STGM_READWRITE)

        rglpwstrName = ["Dark White"]
        rgpropid = ["prop5"]
        cpropid = sizeof(rgpropid)

        # ↓↓↓↓↓↓ I can't find where should I get IPropertySetStorage
        IPropertyStorage.WritePropertyNames(cpropid, rgpropid, rglpwstrName)

    addTag(r"C:\Users\Eliaz\Desktop\New folder")