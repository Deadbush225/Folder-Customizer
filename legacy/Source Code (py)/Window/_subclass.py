from PyQt5.QtWidgets import QFrame, QSizePolicy, QLabel, QHBoxLayout, QDialog, QVBoxLayout, \
	QCheckBox, QLineEdit, QPushButton, QListWidget, QAbstractItemView
from PyQt5.QtCore import Qt


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
		# self.passed_m = event.mimeData()
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
