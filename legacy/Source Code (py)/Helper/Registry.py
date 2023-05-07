import winreg as reg
import os
import sys

program_path = "C:\\Program Files\\Folder Customizer"

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

def install_key():
    # Get path of current working directory and python.exe
    cwd = os.getcwd()
    python_exe = sys.executable

    # optional hide python terminal in windows
    hidden_terminal = '\\'.join(python_exe.split('\\')[:-1])+"\\pythonw.exe"

    key_path = r'Directory\\shell'

    counter = 1
    # Create outer key
    for tone in ["Light", "Normal", "Dark"]:
        tone_key = key_path + f"\\aColorize - {counter}{tone}"
        counter += 1
        key = reg.CreateKey(reg.HKEY_CLASSES_ROOT, tone_key)
        
        # reg.SetValue(key, '', reg.REG_SZ, '')  # default
        reg.SetValueEx(key, 'icon', 2 ,reg.REG_SZ, f'\"{program_path}\\Icons\\Program icon.ico\"') # folder painter icon
        reg.SetValueEx(key, 'MUIVerb', 2, reg.REG_SZ, f'Colorize - {tone}')
        reg.SetValueEx(key, 'SubCommands', 2 ,reg.REG_SZ, '') # additionals
        
        # reg.SetValue(key, 'shell', reg.REG_SZ, '')
        sub_shell_path2 = tone_key + "\\shell"
        key1 = reg.CreateKey(reg.HKEY_CLASSES_ROOT, sub_shell_path2)
        
        counter1 = 1
        for color in ["Red", "Brown", "Orange", "Lemon", "Green", "Azure", "Blue", "Pink", "Violet", "White", "Gray", "Black"]:
            color_key = sub_shell_path2 + f"\\{counter1:02d} {color}"
            counter1 += 1
            key2 = reg.CreateKey(reg.HKEY_CLASSES_ROOT, color_key)

            reg.SetValueEx(key2 ,'icon', 2, reg.REG_SZ, f"\"{program_path}\\Icons\\{tone}\\{color + '.ico'}\"")
            reg.SetValueEx(key2, 'MUIVerb', 2, reg.REG_SZ, color)
            
            command_key = color_key + "\\command"
            key3 = reg.CreateKey(reg.HKEY_CLASSES_ROOT, command_key)
            # reg.SetValue(key3, '', reg.REG_SZ, hidden_terminal + f' "{program_path}\\Folder Customizer.exe" {tone} {color}')
            reg.SetValue(key3, '', reg.REG_SZ, f'"{python_exe}" "{program_path}\\Folder Customizer (python).py" "%V" "{tone}" "{color}"') # using python

            reg.CloseKey(key2)
            reg.CloseKey(key3)
        
        # -- reset -- #
        reset_key = sub_shell_path2 + "\\areset"
        key4 = reg.CreateKey(reg.HKEY_CLASSES_ROOT, reset_key)

        reg.SetValueEx(key4, 'icon', 2, reg.REG_EXPAND_SZ, "%SystemRoot%\system32\shell32.dll,3")
        reg.SetValueEx(key4, 'MUIVerb', 2, reg.REG_SZ, "Reset Icon")
        reg.SetValueEx(key4, 'CommandFlags', 2, reg.REG_DWORD, 32)

        command_key = reset_key + "\\command"
        key5 = reg.CreateKey(reg.HKEY_CLASSES_ROOT, command_key)

        reg.SetValue(key5, '', reg.REG_SZ, f'"{python_exe}" "{program_path}\\Folder Customizer (python).py" "%V" "Reset" "Reset"')

        #-> no reason to add a refresher
        # -- reload icon -- #
        # reload_key = sub_shell_path2 + "\\breload"
        # key4_2 = reg.CreateKey(reg.HKEY_CLASSES_ROOT, reload_key)

        # reg.SetValueEx(key4_2, 'icon', 2, reg.REG_EXPAND_SZ, "%SystemRoot%\system32\shell32.dll,3")
        # reg.SetValueEx(key4_2, 'MUIVerb', 2, reg.REG_SZ, "Refresh Icon")

        # command_key = reload_key + "\\command"
        # key5_2 = reg.CreateKey(reg.HKEY_CLASSES_ROOT, command_key)

        # reg.SetValue(key5_2, '', reg.REG_SZ, f'"{program_path}\\Rexplorer.exe"')

        reg.CloseKey(key4)
        reg.CloseKey(key5)
        
        # reg.CloseKey(key4_2)
        # reg.CloseKey(key5_2)
        
        reg.CloseKey(key)
        reg.CloseKey(key1)

def uninstall_key():
    counter = 1
    for tone in ["Light", "Normal", "Dark"]:
        tone_key = f"Directory\\shell\\aColorize - {counter}{tone}"
        # print(f"{tone_key}\\{reg.HKEY_CLASSES_ROOT}")
        delete_sub_key(reg.HKEY_CLASSES_ROOT, tone_key)
        counter += 1