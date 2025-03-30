# Building

For each tone:
There's `PNG` folder containing the source image to be converted into `.ico` of one 32, 48, and 256 px, and one 16 px.

# forgot the command, try to create a powershell script to populate the ICO folder, using image magick

There's `ICO` folder output of the previous process containing 2 source icons.

Combine these icons using `icobundl.exe`

just call the `bundle.ps1`

~~There's `BMP` folder that is used exclusively for windows context menu api since it deals with `.bmp`. We need to convert the 16px ico so you can use the first ico in the root dir (`image.png[0]`) or the `-16` ico in the `ICO` dir~~

~just call the `toBmp.ps1`~

We can just use the icon in the context menu by loading it as BMP
