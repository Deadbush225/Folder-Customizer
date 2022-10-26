import sys, os, shutil
from pathlib import Path
from PyQt5.QtWidgets import *
from PyQt5.QtCore import *
import fileinput
import subprocess
import winreg as reg

class QHSeperationLine(QFrame):
	'''
	a horizontal seperation line\n
	'''
	def __init__(self):
		super().__init__()
		# self.setMinimumWidth(1)
		self.setFixedHeight(2)
		self.setFrameShape(QFrame.HLine)
		self.setFrameShadow(QFrame.Sunken)
		self.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Minimum)

def folderColorizerTagger(path, folder, tone, color, tag):
	"""adds custom icon and tag to the folder

	Args:
		path (_Path_ object of the ini): Path() object of the ini file inside the selected folder
		folder (str): path of the folder to colorize
		tone (str): tone of the color [light, normal, dark]
		color (str): color to be set in the folder 
		tag (str): can be the custom tag or the default tag (tone color)
	"""	
	icon_path = Path(program_path, tone, color + ".ico")

	print(f"ini already exists? {path.exists()}")

	if path.exists():
		os.system(f'attrib -s -h \"{str(path)}\"')
		os.system(f'attrib -r \"{folder}\"')

		# -> check if file contains the keys
		icon_set = False
		tag_set = False
		with open(path, "r", encoding="utf-8") as ini:
			for item in ini:
				if "[.ShellClassInfo]" in item:
					icon_set = True
					# break
				elif "[{F29F85E0-4FF9-1068-AB91-08002B27B3D9}]" in item:
					tag_set = True
			
			ini.close()
		
		print(f"icon set: {icon_set}, tag set: {tag_set}")

		if icon_set:
			# -> replace the icon
			with fileinput.input(path, inplace=True, encoding="utf-8") as file:
				# icon_detected = False
				for line in file:
					# new_line = line.replace(search_text, new_text)
					# if "[.ShellClassInfo]" in line:
					# 	icon_detected = True
					if "IconFile=" in line:
						# print(f"IconFile={icon_path}", end='')
						print(f"IconFile={icon_path}")
					# elif icon_detected:
					# 	print(f"IconFile={icon_path}")
					elif "IconIndex=" in line:
						print(f"IconIndex=0")
					else:
						print(line, end='')
		
		elif not icon_set:
			# -> append the icon
			with open(path, "a", encoding="utf-8") as ini:
				# ini.write(f"[.ShellClassInfo]\nIconFile=C:\\Program Files\\FolderPainter\\Icons\\Pack_06\\06.ico\nIconIndex=0\n\n")
				ini.write(f"[.ShellClassInfo]\nIconFile={icon_path}\nIconIndex=0\n")
				ini.close()

		if tag_set:
			# -> replace the tag
			with fileinput.input(path, inplace=True, encoding="utf-8") as file:
				# tag_detected = False
				for line in file:
					# new_line = line.replace(search_text, new_text)
					# if "[{{F29F85E0-4FF9-1068-AB91-08002B27B3D9}}]" in line:
					# 	tag_detected = True
					if "Prop5=31," in line:
						# print(f"Prop5=31,{tag}", end='')
						print(f"Prop5=31,{tag}")
					# elif tag_detected:
					# 	print(f"Prop5,")
					else:
						print(line, end='')

		elif not tag_set:
			# -> append the tag
			with open(path, "a", encoding="utf-8") as ini:
				# ini.write(f"[.ShellClassInfo]\nIconFile=C:\\Program Files\\FolderPainter\\Icons\\Pack_06\\06.ico\nIconIndex=0\n\n")
				ini.write(f"[{{F29F85E0-4FF9-1068-AB91-08002B27B3D9}}]\nProp5=31,{tag}\n")
				ini.close()
				
		os.system(f'attrib +s +h \"{str(path)}\"')
		os.system(f'attrib +r \"{folder}\"')

	else:
		with open(path, "w", encoding="utf-8") as ini:
			# ini.write(f"[.ShellClassInfo]\nIconFile=C:\\Program Files\\FolderPainter\\Icons\\Pack_06\\06.ico\nIconIndex=0\n\n")
			ini.write(f"[.ShellClassInfo]\nIconFile={icon_path}\nIconIndex=0\n\n")
			ini.write(f"[{{F29F85E0-4FF9-1068-AB91-08002B27B3D9}}]\nProp5=31,{tag}")
			ini.close()
		
		os.system(f'attrib +s +h \"{str(path)}\"')
		os.system(f'attrib +r \"{folder}\"')

	# -- restart file explorer -- #
	# subprocess.call([f'{program_path}\\restart file explorer.bat'])
	print("rebuilfing icon cache")
	# subprocess.call([f'{program_path}\\Rexplorer.exe', '/I', '/F'])
	# subprocess.call([f'{program_path}\\Rexplorer.exe', '/I'])
	subprocess.call([f'{program_path}\\Rexplorer.exe'])
	# subprocess.call(['nircmd.exe sysrefresh'])
	# subprocess.call(['ie4uinit.exe', '-show'])

def resetFolder(path):
	"""reset folder icon and tag

	Args:
		path (_path_): Path object of the ini file inside the folder to reset
	"""	

	print('reseting')

	if path.exists():
		with fileinput.input(path, inplace=True, encoding="utf-8") as file:
			for line in file:
				if "[.ShellClassInfo]" in line:
					continue
				elif "IconFile=" in line:
					continue
				elif "IconIndex=" in line:
					continue
				elif "[{F29F85E0-4FF9-1068-AB91-08002B27B3D9}]" in line:
					continue
				elif "Prop5=31," in line:
					continue
				else:
					print(line, end='')
	
	print("rebuilfing icon cache")
	# subprocess.call([f'{program_path}\\Rexplorer.exe', '/I', '/F'])
	subprocess.call([f'{program_path}\\Rexplorer.exe'])

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

program_path = "C:\\Program Files\\Folder Customizer"

class ModQHBoxLayout(QHBoxLayout):
	def __init__(self):
		super().__init__()
		self.setAlignment(Qt.AlignTop)

class ModQLabel(QLabel):
	def __init__(self, str):
		super().__init__(str)

		self.setSizePolicy(QSizePolicy.Maximum, QSizePolicy.Maximum)
		self.setAlignment(Qt.AlignHCenter | Qt.AlignTop)

class MessageBoxwLabel(QDialog):
	folder_name = None

	def __init__(self, folder):
		super().__init__()

		self.mainlayout = QVBoxLayout()

		folder_label = QLabel(f"Folder: {folder}")
		self.mainlayout.addWidget(folder_label)

		self.addtag = QCheckBox("Don't add a tag")
		self.mainlayout.addWidget(self.addtag)

		label = QLabel("Custom Tag?")
		self.mainlayout.addWidget(label)

		self.lineedit = QLineEdit()
		self.mainlayout.addWidget(self.lineedit)

		self.button = QPushButton("Done")
		self.mainlayout.addWidget(self.button)
		self.button.clicked.connect(self.click)

		self.setLayout(self.mainlayout)
		
		self.returned = self.exec_()
	
	def click(self):
		print("click")

		self.tag_from_popup = self.lineedit.text().strip()
		self.addtag = self.addtag.isChecked()
		self.done(1)


class ListBoxWidget(QListWidget):
	dir_list = []

	def __init__(self):
		super().__init__()
		self.viewport().setAcceptDrops(True)
		self.setSizePolicy(QSizePolicy.Expanding,QSizePolicy.Expanding)
		self.setSelectionMode(QAbstractItemView.ExtendedSelection)
		self.setDragDropMode(QAbstractItemView.DragDrop)
		self.setDropIndicatorShown(True)

	def dragEnterEvent(self, event):
		self.passed_m = event.mimeData()
		event.accept()

	def dragMoveEvent(self, event):
		# print("dragMoveEvent")
		if not event.mimeData().hasUrls():
			# print("no urls")
			event.ignore()
			return
		event.accept()

	def dropEvent(self, event):
		if event.mimeData().hasUrls():
			# event.setDropAction(Qt.CopyAction)
			event.accept()

			links = []
			for url in event.mimeData().urls():
				# https://doc.qt.io/qt-5/qurl.html
				if url.isLocalFile():
					links.append(str(url.toLocalFile()))
				else:
					links.append(str(url.toString()))
			self.addItems(links)
		else:
			event.ignore()
	
	def getAllItems(self):
		for item in range(self.count()):
			dir = self.item(item).text()
			self.dir_list.append(dir)

		ret = self.dir_list 
		self.dir_list = []
		return ret

class FolderCustomizerWindow(QWidget):
	global program_path
	def __init__(self):
		super().__init__()
		# self.resize(1200, 600)

		# -- check if the icons are in the Program Files
		program_path = Path("C:\Program Files", "Folder Customizer")
		if not program_path.exists():
			shutil.copytree(Path().absolute(), program_path)

		# -- dnd layout -- #
		self.list_view = ListBoxWidget()
		# self.list_view.addItems(["1","2","3","4"])
		# self.list_view.addItem(r"C:\Users\Eliaz\Desktop\MAth apth")

		self.buttonLayout = QHBoxLayout()

		self.btn_Del = QPushButton('Delete')
		self.btn_Del.clicked.connect(lambda: self.deleteSelectedItem())
		self.buttonLayout.addWidget(self.btn_Del)

		self.btn_ClearAll = QPushButton('Clear All')
		self.btn_ClearAll.clicked.connect(lambda: self.clearAll())
		self.buttonLayout.addWidget(self.btn_ClearAll)

		self.dnd_layout = QVBoxLayout()
		self.dnd_layout.addLayout(self.buttonLayout)
		self.dnd_layout.addWidget(self.list_view)
		
		# -- customization layout -- #
		self.show_more = QPushButton('Show Advanced Settings')
		self.show_more.clicked.connect(self.hide_show_advanced_settings)

		self.install_key_btn = QPushButton('Add to context menu')
		self.install_key_btn.clicked.connect(self.install_key)
		self.install_key_btn.setHidden(True)

		self.uninstall_key_btn = QPushButton('Remove from context menu')
		self.uninstall_key_btn.clicked.connect(self.uninstall_key)
		self.uninstall_key_btn.setHidden(True)

		self.seperator_horizontal = QHSeperationLine()
		self.seperator_horizontal.setHidden(True)

		# -> tone combo box
		self.tone_comboBox_Layout = QVBoxLayout()
		self.tone_comboBox_label = QLabel("Tone")

		self.tone_comboBox = QComboBox()
		self.tone_comboBox.addItems(["Light", "Normal", "Dark"])
		self.tone_comboBox.setCurrentIndex(1)

		self.tone_comboBox_Layout.addWidget(self.tone_comboBox_label)
		self.tone_comboBox_Layout.addWidget(self.tone_comboBox)

		# -> color combo cox
		self.color_comboBox_Layout = QVBoxLayout()
		self.color_comboBox_label = QLabel("Color")

		self.color_comboBox = QComboBox()
		self.color_comboBox.addItems(["Red", "Brown", "Orange", "Lemon", "Green", "Azure", "Blue", "Pink", "Violet", "White", "Gray", "Black"])
		self.color_comboBox.setCurrentIndex(0)

		self.color_comboBox_Layout.addWidget(self.color_comboBox_label)
		self.color_comboBox_Layout.addWidget(self.color_comboBox)

		# -> combo box layout
		self.combo_layout = QHBoxLayout()
		self.combo_layout.addLayout(self.tone_comboBox_Layout)
		self.combo_layout.addLayout(self.color_comboBox_Layout)
		
		# -> no label checkbox
		self.no_label_layout = QHBoxLayout()
		self.no_label = QCheckBox("Don't Make a Tag?")

		self.no_label_layout.addWidget(self.no_label)

		# -> line edit layout
		self.line_edit_layout = QHBoxLayout()
		self.line_edit_label = QLabel("Custom Tag")
		self.line_edit = QLineEdit()

		self.line_edit_layout.addWidget(self.line_edit_label)
		self.line_edit_layout.addWidget(self.line_edit)

		# -> apply button
		self.apply_button = QPushButton("Apply")
		self.apply_button.clicked.connect(self.apply)

		# -> reset button
		self.reset_button = QPushButton("Reset")
		self.reset_button.clicked.connect(self.reset)

		# -> customization layout
		self.costumization_layout = QVBoxLayout()
		self.costumization_layout.addWidget(self.install_key_btn)
		self.costumization_layout.addWidget(self.uninstall_key_btn)
		self.costumization_layout.addWidget(self.seperator_horizontal)
		self.costumization_layout.addWidget(self.show_more)
		self.costumization_layout.addLayout(self.combo_layout)
		self.costumization_layout.addLayout(self.no_label_layout)
		self.costumization_layout.addLayout(self.line_edit_layout)
		# self.costumization_layout.addSpacerItem(QSpacerItem(2,30))
		self.costumization_layout.addStretch()
		self.costumization_layout.addWidget(self.apply_button)
		self.costumization_layout.addWidget(self.reset_button)

		# -- main layout -- #
		self.main_layout = QHBoxLayout()
		self.main_layout.addLayout(self.dnd_layout, 7)
		self.main_layout.addLayout(self.costumization_layout)

		self.setLayout(self.main_layout)

	def hide_show_advanced_settings(self):
		self.install_key_btn.setHidden(not self.install_key_btn.isHidden())
		self.uninstall_key_btn.setHidden(not self.uninstall_key_btn.isHidden())
		self.seperator_horizontal.setHidden(not self.seperator_horizontal.isHidden())

	def install_key(self):
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
				# reg.SetValue(key3, '', reg.REG_SZ, hidden_terminal + f' "{program_path}\\Folder Customizer.exe" {tone} {color}')
				reg.SetValue(key3, '', reg.REG_SZ, f'"{python_exe}" "{program_path}\\Folder Customizer.py" "%V" "{tone}" "{color}"') # using python

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

			reg.SetValue(key5, '', reg.REG_SZ, f'"{python_exe}" "{program_path}\\Folder Customizer.py" "%V" "Reset" "Reset"')

			# -- reload icon -- #
			reload_key = sub_shell_path2 + "\\breload"
			key4_2 = reg.CreateKey(reg.HKEY_CLASSES_ROOT, reload_key)

			reg.SetValueEx(key4_2, 'icon', 2, reg.REG_EXPAND_SZ, "%SystemRoot%\system32\shell32.dll,3")
			reg.SetValueEx(key4_2, 'MUIVerb', 2, reg.REG_SZ, "Reload Icon")

			command_key = reload_key + "\\command"
			key5_2 = reg.CreateKey(reg.HKEY_CLASSES_ROOT, command_key)

			reg.SetValue(key5_2, '', reg.REG_SZ, f'"{program_path}\\Rexplorer.exe"')

			reg.CloseKey(key4)
			reg.CloseKey(key5)
			
			reg.CloseKey(key4_2)
			reg.CloseKey(key5_2)
			
			reg.CloseKey(key)
			reg.CloseKey(key1)

	def uninstall_key(self):
		counter = 1
		for tone in ["Light", "Normal", "Dark"]:
			tone_key = f"Directory\\shell\\aColorize - {counter}{tone}"
			# print(f"{tone_key}\\{reg.HKEY_CLASSES_ROOT}")
			delete_sub_key(reg.HKEY_CLASSES_ROOT, tone_key)
			counter += 1

	def deleteSelectedItem(self):
		selected = self.list_view.selectedIndexes()
		selected = [item.row() for item in selected]
		
		selected.sort(reverse=True)

		for item in selected:
			self.list_view.takeItem(item)

	def clearAll(self):
		self.list_view.clear()

	def apply(self):
		tone = self.tone_comboBox.currentText()
		color = self.color_comboBox.currentText()
		folders = self.list_view.getAllItems()
		icon_path = Path(program_path, tone, color + ".ico")
		exist = icon_path.exists()

		selected_color_tag = (color if tone == "Normal" else f"{tone} {color}")

		tag = ""

		if not self.no_label.isChecked():
			tag = (self.line_edit.text() if self.line_edit.text().strip() else selected_color_tag)

		print(f"folders: {folders} \n selected_color: {selected_color_tag} \n tag: {tag} \n icon path: {icon_path} \n exist: {exist}")

		for folder in folders:

			path = Path(folder, "desktop.ini")

			folderColorizerTagger(path, folder, tone, color, selected_color_tag)
	
	def reset(self):
		folders = self.list_view.getAllItems()

		for folder in folders:
			path = Path(folder, "desktop.ini")

			resetFolder(path)

class FolderCustomizerCommandLine(QWidget):
	global program_path
	def __init__(self):
		super().__init__()

		color = sys.argv[3]
		tone = sys.argv[2]
		folder = sys.argv[1]

		path = Path(folder, "desktop.ini")

		if (color == "Reset") and (tone == "Reset"):
			resetFolder(path)
			quit()

		# key = "{F29F85E0-4FF9-1068-AB91-08002B27B3D9}"
		# icon_path = Path(program_path, tone, color + ".ico")

		tag = ""

		# print(f"preprocessing - color: {color}, tag: {tag}, folder: {folder}")

		tagpopup = MessageBoxwLabel(folder)
		if tagpopup.returned == QDialog.Accepted:
			if not tagpopup.addtag:
				if tagpopup.tag_from_popup:
					tag = tagpopup.tag_from_popup
				elif tone == "Normal":
					tag = color
				else:
					tag = f"{tone} {color}"

		print(f"folderColorizerTagger: {path}, {folder}, {tone}, {color}, {tag})")
		folderColorizerTagger(path, folder, tone, color, tag)

		quit()


if __name__ == '__main__':
	app = QApplication(sys.argv)

	print(len(sys.argv))
	print(sys.argv)

	if len(sys.argv) == 1:
		print("len == 1")
		demo = FolderCustomizerWindow()
		demo.show()
	else:
		print("len != 1")
		cm = FolderCustomizerCommandLine()
	
	sys.exit(app.exec_())