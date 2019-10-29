#### Modes 101
There are 3 modes in `vim`: 
+ *Command* or normal mode, when `vim` just opened
+ *Edit mode* — type one of `I i A a O o` to enter
+ *Execution mode* — type `:` to enter  

Tip: if you feel lost, hit double `Esc` to escape from any of depths back to normal mode.


#### Useful open options
+ `-o[N]`   Open N windows (default: one for each file)
+ `-O[N]`   Like -o but split vertically
+ `-p`      Open in tabs (`gt` for switching)	


#### Navigation
+ `gf`                Open file by name under cursor
+ `Ctrl+O / Ctrl+^`   Back from opened file to the previous one
+ `G`     To the bottom of file
+ `gg`    To the top of file
+ `42G`   Go to line (42G for 42nd line and so on)                 


#### Editing
+ `dw` Remove word
+ `dd` Remove line
+ `Ctrl+W` Remove word back when Edit mode
+ `V` Select a line (`v` for selecting by character)
+ `y` Copy selected text
+ `p` Paste selected text
+ `u` Undo
+ `.` Redo


#### How to quit vim
Keep calm and hit these ;)
+ `ZZ`    Save file & quit
+ `ZQ`    Exit without saving, same as :q!
+ `:xa`   Save all files & quit vim
+ `:qa!`  Quit all files without saving 


#### Screen split
+ `Ctrl+W, S (upper case)` for horizontal splitting
+ `Ctrl+W, v (lower case)` for vertical splitting
+ `Ctrl+W, Q` to close one
+ `Ctrl+W, Ctrl+W` to switch between windows/splits
+ `Ctrl+W, arrow or J (or K, H, L)` to switch to adjacent window (intuitively up, down, left, right)
