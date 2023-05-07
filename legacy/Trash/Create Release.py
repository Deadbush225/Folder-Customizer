import shutil
from pathlib import *
import subprocess

cwd = Path().cwd()
print(cwd)

release = cwd / "Release"
sources = cwd / "Source Code"

if release.exists():
    shutil.rmtree(release)

shutil.copytree(sources / "Dark", release / "Dark")
shutil.copytree(sources / "Light", release / "Light")
shutil.copytree(sources / "Normal", release / "Normal")

shutil.copy(sources / "Program icon.ico", release)

shutil.copy(sources / "key installer (exe).py", release)
shutil.copy(sources / "key uninstaller.py", release)

shutil.copy(sources / "setup.py", release)

shutil.copy(sources / "Rexplorer.exe", release)

subprocess.call(["pyinstaller", "--noconfirm", "--onefile", "--console", "--distpath", f"{release.resolve()}", "D:/CODING RELATED/Projects/Folder Customizer/Source Code/Folder Customizer (exe).py"])