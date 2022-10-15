import os
import sys
import winreg as reg

def delete_sub_key(root, sub):
    
    try:
        open_key = reg.OpenKey(root, sub, 0, reg.KEY_ALL_ACCESS)
        num, _, _ = reg.QueryInfoKey(open_key)
        for i in range(num):
            child = reg.EnumKey(open_key, 0)
            delete_sub_key(open_key, child)
        try:
           reg.DeleteKey(open_key, '')
        except Exception as e:
           print(f"Error: {e}")
           # log deletion failure
        finally:
           reg.CloseKey(open_key)
    except Exception as e:
        print(f"an error occured: {e}")
        # log opening/closure failure

counter = 1
for tone in ["Light", "Normal", "Dark"]:
    tone_key = f"Directory\\shell\\aColorize - {counter}{tone}"
    # print(f"{tone_key}\\{reg.HKEY_CLASSES_ROOT}")
    delete_sub_key(reg.HKEY_CLASSES_ROOT, tone_key)
    counter += 1