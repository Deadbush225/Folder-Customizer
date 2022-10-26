import os
import sys
import winreg as reg

# Get path of current working directory and python.exe
cwd = os.getcwd()
python_exe = sys.executable

# optional hide python terminal in windows
hidden_terminal = '\\'.join(python_exe.split('\\')[:-1])+"\\pythonw.exe"

program_path = "C:\\Program Files\\Folder Customizer"

# Set the path of the context menu (right-click menu)
key_path = r'Directory\\shell' # Change 'Organiser' to the name of your project

# main = reg.CreateKey(reg.HKEY_CLASSES_ROOT, key_path)

# reg.SetValueEx(main, 'icon', 2 ,reg.REG_SZ, f'{program_path}\\Program icon.ico') # folder painter icon
# reg.SetValueEx(main, 'MUIVerb', 2, reg.REG_SZ, 'Folder colorizer')
# reg.SetValueEx(main, 'SubCommands', 2 ,reg.REG_SZ, '') # additionals

# sub_shell_path = key_path + "\\shell"
# key1 = reg.CreateKey(reg.HKEY_CLASSES_ROOT, sub_shell_path)

counter = 1
# Create outer key
for tone in ["Light", "Normal", "Dark"]:
    tone_key = key_path + f"\\aColorize - {counter}{tone}"
    counter += 1
    key = reg.CreateKey(reg.HKEY_CLASSES_ROOT, tone_key)
    
    # reg.SetValue(key, '', reg.REG_SZ, '')  # default
    reg.SetValueEx(key, 'icon', 2 ,reg.REG_SZ, f'\"{program_path}\\Program icon.ico\"') # folder painter icon
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

        reg.SetValueEx(key2 ,'icon', 2, reg.REG_SZ, f"\"{program_path}\\{tone}\\{color + '.ico'}\"")
        reg.SetValueEx(key2, 'MUIVerb', 2, reg.REG_SZ, color)
        
        command_key = color_key + "\\command"
        key3 = reg.CreateKey(reg.HKEY_CLASSES_ROOT, command_key)
        # reg.SetValue(key3, '', reg.REG_SZ, hidden_terminal + f' "{program_path}\\Folder Customizer.py" {tone} {color}')
        reg.SetValue(key3, '', reg.REG_SZ, f'start "" "{program_path}\\Folder Customizer (exe).exe" "%V" "{tone}" "{color}"') # using python
        # reg.SetValue(key3, '', reg.REG_SZ, f'"{program_path}\\Folder Customizer.exe" "%V" "{tone}" "{color}"')

        reg.CloseKey(key2)
        reg.CloseKey(key3)
    
    # -- reset -- #
    reset_key = sub_shell_path2 + "\\areset"
    key4 = reg.CreateKey(reg.HKEY_CLASSES_ROOT, reset_key)

    reg.SetValueEx(key4, 'icon', 2, reg.REG_EXPAND_SZ, "%SystemRoot%\system32\shell32.dll,3")
    reg.SetValueEx(key4, 'MUIVerb', 2, reg.REG_SZ, "Reset Icon")
    reg.SetValueEx(key4, 'CommandFlags', 2, reg.REG_DWORD, 32)
    # reg.SetValueEx(key4, 'SeparatorAfter', 2, reg.REG_SZ, "")

    command_key = reset_key + "\\command"
    key5 = reg.CreateKey(reg.HKEY_CLASSES_ROOT, command_key)

    reg.SetValue(key5, '', reg.REG_SZ, f'start "" "{program_path}\\Folder Customizer (exe).exe" "%V" "Reset" "Reset"')

    # -- reload icon -- #
    reload_key = sub_shell_path2 + "\\breload"
    key4_2 = reg.CreateKey(reg.HKEY_CLASSES_ROOT, reload_key)

    reg.SetValueEx(key4_2, 'icon', 2, reg.REG_EXPAND_SZ, "%SystemRoot%\system32\shell32.dll,3")
    reg.SetValueEx(key4_2, 'MUIVerb', 2, reg.REG_SZ, "Reload Icon")
    # reg.SetValueEx(key4, 'SeparatorBefore', 2, reg.REG_SZ, "")
    # reg.SetValueEx(key4, 'SeparatorAfter', 2, reg.REG_SZ, "")

    command_key = reload_key + "\\command"
    key5_2 = reg.CreateKey(reg.HKEY_CLASSES_ROOT, command_key)

    reg.SetValue(key5_2, '', reg.REG_SZ, f'"{program_path}\\Rexplorer.exe"')

    reg.CloseKey(key4)
    reg.CloseKey(key5)
    
    reg.CloseKey(key4_2)
    reg.CloseKey(key5_2)
    
    reg.CloseKey(key)
    reg.CloseKey(key1)
# create inner key
# key1 = reg.CreateKey(key, r"command")
# reg.SetValue(key1, '', reg.REG_SZ, python_exe + f' "{cwd}\\file_organiser.py"') # change 'file_organiser.py' to the name of your script
#reg.SetValue(key1, '', reg.REG_SZ, hidden_terminal + f' "{cwd}\\file_organiser.py"')  # use to to hide terminal
