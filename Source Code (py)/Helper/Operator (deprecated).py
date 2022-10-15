# from PyQt5.QtCore import QFile
import os
# import shutil
import subprocess
from pathlib import Path
import fileinput

from Customizer.Colorizer import setIcon
from Customizer.Tagger import tagFolder

program_path = "C:\\Program Files\\Folder Customizer"

def folderColorizerTagger(path, folder, tone, color, tag):
	"""adds custom icon and tag to the folder

	Args:
		folder (str): path of the folder to colorize
		tone (str): tone of the color [light, normal, dark]
		color (str): color to be set in the folder 
		tag (str): can be the custom tag or the default tag (tone color)
	"""	
	icon_path = Path(program_path, "Icons", tone, color + ".ico")

	print(f"ini already exists? {Path(folder).exists()}")
	
	tagFolder(folder, tag)
	setIcon(folder, str(icon_path), 0)

	subprocess.run(['attrib', '+s', '+h', str(path)])
	subprocess.run(['attrib', '+r', folder])

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
				elif "IconResource=" in line:
					continue
				elif "IconIndex=" in line:
					continue
				elif "Flags=" in line:
					continue
				elif "[{F29F85E0-4FF9-1068-AB91-08002B27B3D9}]" in line:
					continue
				elif "Prop5=" in line:
					continue
				else:
					print(line, end='')
			file.close()

		# check if the ini file is just blank
		with open(path, "r", encoding="utf-8") as file:
			contents = file.read()
			print(f"contents: '{contents}'")
			print(f"content is space: {contents.isspace()}")

			if (contents.isspace()) or (contents == ''):
				print("ini is now blank. (Deleting)")
				# subprocess.run(['attrib', '-s', '-h', str(path)])
				# subprocess.run(['attrib', '-r', str(path.parent)])

				file.close()
				# dfile = QFile(str(path))
				# ret = dfile.moveToTrash()
				os.remove(path)
				# print(f"moved to trash. {ret}")
			
		print("rebuilfing icon cache")
	
