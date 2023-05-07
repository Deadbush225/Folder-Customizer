import subprocess

folder = r"C:\Users\Eliaz\Desktop\New folder"

subprocess.run([r"C:\Program Files\Folder Customizer\DeskEdit.exe", fr"/F={folder}", r"/D"])