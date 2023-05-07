from PyQt5.QtWidgets import QWidget, QDialog
from pathlib import Path
import sys

from Window._subclass import MessageBoxwLabel
from Helper.Operator import resetFolder, folderColorizerTagger

class FolderCustomizerCommandLine(QWidget):
	# global program_path
	def __init__(self):
		super().__init__()

		color = sys.argv[3]
		tone = sys.argv[2]
		folder = sys.argv[1]

		path = Path(folder, "desktop.ini")

		if (color == "Reset") and (tone == "Reset"):
			resetFolder(path)
			quit()

		tag = ""
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