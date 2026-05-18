AreaSnap
=========
The program is designed to replace the default tools (ScreenSketch/Snipping Tool) in Windows, extend its functionality, and improve performance.

![AreaSnap Demo](docs/demo.gif)

Control
--------
* Press `Shift+Alt+Q` to activate the capture overlay
* Press and hold `MOUSE1` to capture an area for the snap
* ~~Press `TAB` to switch between record/capture~~ 	
* ~~Move `MOUSE3` when capturing to extend an area for the snap~~
* Press `1-5` to change the image file extension to `.png` / `.gif` / `.jpeg` / `.bmp` / `.tiff` respectively
* Press `CTRL+V` to paste the captured screenshot from clipboard
* Press `ESC` to close the capture overlay

About
=====
The program uses an internet connection every time it is launched, which may trigger antivirus software.             
For image capture, it uses WinAPI functions, while the encoder provides various output file formats.                   
Double buffering is also implemented to ensure smooth animation.     
`Update checks run in a separate thread — no UI lag.`      

Json
-----
The GitHub API response is parsed using a custom SSE4.2-optimized JSON parser.

Code Soon.

Startup
-------
The program automatically adds itself to the Windows startup registry key "SOFTWARE\Microsoft\Windows\CurrentVersion\Run" on first launch. This means AreaSnap will start every time you log into Windows, ready to capture screenshots with the global hotkey `Shift+Alt+Q`.

Autoupdate
----------
The program also features automatic updates and `hash verification`, so once downloaded, it will update itself when a new release is available.