# from pathlib import *
import subprocess
# import fileinput

# def scan_for_tags(ini_path):
# 	with fileinput.input(ini_path, inplace=True, encoding="utf-8") as file:
# 		guid_found = prop_found = False
# 		for line in file:
# 			if ("[{{F29F85E0-4FF9-1068-AB91-08002B27B3D9}}]" in line):
# 				guid_found = True
# 			elif "Prop5=31," in line:
# 				prop_found = True
		
# 		file.close()
# 		return guid_found and prop_found

# def tagFolder(folder, tag):
# 	ini_path: Path = Path(folder, "desktop.ini")
# 	if not ini_path.exists():
# 		with open(ini_path, "w") as new_ini:
# 			new_ini.close()

# 	subprocess.run(['attrib', '-s', '-h', str(ini_path)])

# 	tag_found = scan_for_tags(ini_path) # check if tag were already set

# 	if tag_found:
# 		with fileinput.input(ini_path, inplace=True, encoding="utf-8") as file:
# 			for line in file:

# 				# if remove_tag:
# 				# 	if ("[{{F29F85E0-4FF9-1068-AB91-08002B27B3D9}}]" in line) and remove_tag:
# 				# 		continue
# 				# 	elif ("Prop5=31," in line) and remove_tag:
# 				# 		continue
					
# 					# print(line, end='')
						
# 				if tag:
# 					if ("[{{F29F85E0-4FF9-1068-AB91-08002B27B3D9}}]" in line):
# 						tag_found = True
# 					elif "Prop5=31," in line:
# 						print(f"Prop5=31,{tag}")
					
# 					print(line, end='')
# 	elif not tag_found:
# 		with open(ini_path, "w+", encoding="utf-8") as ini:
# # 			# ini.write(f"[.ShellClassInfo]\nIconFile=C:\\Program Files\\FolderPainter\\Icons\\Pack_06\\06.ico\nIconIndex=0\n\n")
# 			ini.write(f"[{{F29F85E0-4FF9-1068-AB91-08002B27B3D9}}]\nProp5=31,{tag}\n\n")
# 			ini.close()

def tagFolder(folder, tag):
	subprocess.run([r"C:\Program Files\Folder Customizer\DeskEdit.exe", fr"/F={folder}", "/S={F29F85E0-4FF9-1068-AB91-08002B27B3D9}", fr"/L=Prop5={tag}"])