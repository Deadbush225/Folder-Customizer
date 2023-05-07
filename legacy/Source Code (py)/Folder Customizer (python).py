import sys
from PyQt5.QtWidgets import QApplication

from Window.folderCustomizerWindow import FolderCustomizerWindow
from Window.folderCustomizerCommandLine import FolderCustomizerCommandLine

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