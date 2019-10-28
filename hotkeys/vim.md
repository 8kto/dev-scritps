#### Open vim in different modes
+ `-o[N]`   Open N windows (default: one for each file)
+ `-O[N]`   Like -o but split vertically
+ `-p`      Open in tabs (`gt` for switching)	


#### Screen split
+ `Ctrl+W, S (upper case)` for horizontal splitting
+ `Ctrl+W, v (lower case)` for vertical splitting
+ `Ctrl+W, Q` to close one
+ `Ctrl+W, Ctrl+W` to switch between windows/splits
+ `Ctrl+W, J (or K, H, L)` to switch to adjacent window (intuitively up, down, left, right)


#### Misc hotkeys
```
dw " Remove word
dd " Remove line

Ctrl+W " Remove word back when Edit mode

gf                " Open file by name under cursor
Ctrl+O / Ctrl+^   " Back from opened file to the previous one

G     " To the bottom of file
gg    " To the top of file
42G   " Go to line (42G for 42nd line and so on)                 
```


#### How to quit vim
Keep calm and hit these ;)
```
ZZ          " Save file & quit
ZQ          " Exit without saving, same as :q!
:xa         " Save all files & quit vim
:qa!        " Quit all files without saving 
```
