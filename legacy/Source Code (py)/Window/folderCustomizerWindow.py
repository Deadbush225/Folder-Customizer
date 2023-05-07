from PyQt5.QtWidgets import QWidget, QPushButton, QHBoxLayout, QVBoxLayout, \
	QComboBox, QLabel, QCheckBox, QLineEdit
from pathlib import Path
import shutil

from Window._subclass import *
from Helper.Operator import resetFolder, folderColorizerTagger
from Helper.Registry import install_key, uninstall_key

program_path = "C:\\Program Files\\Folder Customizer"
program_path = Path(program_path)

colors = ["Default", "Red", "Brown", "Orange", "Lemon", "Green", "Azure", "Blue", "Pink", "Violet", "White", "Gray", "Black"]
tones = ["Default", "Light", "Normal", "Dark"]

class FolderCustomizerWindow(QWidget):
	# global program_path
	def __init__(self):
		super().__init__()
		# self.resize(1200, 600)

		# -- check if the icons are in the Program Files
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
		self.install_key_btn.clicked.connect(install_key)
		self.install_key_btn.setHidden(True)

		self.uninstall_key_btn = QPushButton('Remove from context menu')
		self.uninstall_key_btn.clicked.connect(uninstall_key)
		self.uninstall_key_btn.setHidden(True)

		self.seperator_horizontal = QHSeperationLine()
		self.seperator_horizontal.setHidden(True)

		# -> tone combo box
		self.tone_comboBox_Layout = QVBoxLayout()
		self.tone_comboBox_label = QLabel("Tone")

		self.tone_comboBox = QComboBox()
		self.tone_comboBox.addItems(tones)
		self.tone_comboBox.setCurrentIndex(1)

		self.tone_comboBox_Layout.addWidget(self.tone_comboBox_label)
		self.tone_comboBox_Layout.addWidget(self.tone_comboBox)

		# -> color combo cox
		self.color_comboBox_Layout = QVBoxLayout()
		self.color_comboBox_label = QLabel("Color")

		self.color_comboBox = QComboBox()
		self.color_comboBox.addItems(colors)
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

		default = False
		if color == "Default" or tone == "Default":
			default = True

		selected_color_tag = (color if tone == "Normal" else f"{tone} {color}")

		tag = ""

		if not self.no_label.isChecked():
			tag = (self.line_edit.text() if self.line_edit.text().strip() else selected_color_tag)

		print(f"folders: {folders} \n selected_color: {selected_color_tag} \n tag: {tag} \n icon path: {icon_path} \n exist: {exist}")

		for folder in folders:

			path = Path(folder, "desktop.ini")

			folderColorizerTagger(path, folder, tone, color, tag, default=default)
	
	def reset(self):
		folders = self.list_view.getAllItems()

		for folder in folders:
			path = Path(folder, "desktop.ini")

			resetFolder(path)
