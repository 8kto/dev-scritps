# VIM tunings
Config file: `/etc/vim/vimrc` 

```vim
set ignorecase      " Do case insensitive matching
set number          " Enable line numbers
set splitbelow      " Focus gets to new hor split open | bottom
set splitright      " Focus gets to new ver split open | right
set showmatch       " Show matching brackets  
set ignorecase      " Do case insensitive matching
```

#### File manager
Set an extented view for VIM internal file manager
+ 0: Thin, one file per line
+ 1: Long, one file per line with file size and time stamp
+ 2: Wide, which is files in columns
+ 3: Tree style

```vim
let g:netrw_liststyle = 1
```

By default files will be opened in the same window as the netrw directory browser. 
To change this behaviour the netrw_browse_split option may be set. The options are as follows
+ 1: Open files in a new horizontal split
+ 2: Open files in a new vertical split
+ 3: Open files in a new tab
+ 4: Open in previous window

```vim
let g:netrw_browse_split = 2
```

#### Advanced VIM look setup
Tune vim as a tab-manager with file explorer.
```vim
" File manager tunings
let g:netrw_liststyle = 1       " Display size, update date
let g:netrw_browse_split = 2    " Horizontal split
let g:netrw_altv = 1            " Open files in file manager in hor split mode
let g:netrw_winsize = 25        " 25% of viewport for file explorer

" On vim open run filemanager and move focus
augroup ProjectDrawer
  autocmd!
  autocmd VimEnter * :Vexplore      " open file explorer
  autocmd VimEnter * wincmd l       " set focus to right pane (instead of file explorer)
augroup END
```
Cons:
+ More noisy look of the screen every time you open `vim`, even when you don't need it
+ You have to hit a bit longer commands to save/quit

Pros:
+ Useful file explorer which saves time and enables you to see/navigate through files on the same level with the opened one,
without opening an additional tab/running `:bash`
+ Smarter screen's space distribution, especially for the wide screens 
