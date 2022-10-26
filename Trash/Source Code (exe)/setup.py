import os 
# import sys
from pathlib import Path
import shutil
# from PyQt5.QtCore import *
# from PyQt5.QtWidgets import *
# from PyQt5.QtGui import *

# class Installer(QWidget):
#     def __init__(self):
#         super().__init__()
        
program_path = Path("C:\Program Files", "Folder Customizer")

if not program_path.exists():
    shutil.copytree(Path(__file__).resolve().parent, program_path)
else:
    shutil.rmtree(program_path)
    shutil.copytree(Path(__file__).resolve().parent, program_path)

# app = QApplication(sys.argv)
# ex = Installer()
# sys.exit(app.exec_())