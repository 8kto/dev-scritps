# Terminal
#### Colored prompt for root user 
```
# ~/.bashrc
export PS1="\[$(tput bold)\]\[\033[38;5;196m\]\u@\h\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;15m\]:\[$(tput sgr0)\]\[\033[38;5;129m\]\w\[$(tput sgr0)\]\[\033[38;5;15m\]\\$ \[$(tput sgr0)\]"
```

#### Current git branch in prompt + current base dir (not full path)
```sh
# Add git branch if its present to PS1
parse_git_branch() {
 git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}
if [ "$color_prompt" = yes ]; then
 # Colored user prompt
 PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[01;31m\]$(parse_git_branch)\[\033[00m\]\$ '
 # Git branch + short path
 PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u:\[\033[01;34m\]\W\[\033[01;31m\]$(parse_git_branch)\[\033[00m\]\$ '
else
 PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w$(parse_git_branch)\$ '
fi
unset color_prompt force_color_prompt
```

#### Misc enhancements to bash
```sh
# ~/.bashrc

# https://habr.com/ru/post/452522/
shopt -s cdspell    # fix typos
shopt -s autocd     # change disk wo `cd` typing
shopt -s checkjobs  # no exit when running tasks
shopt -s histverify # when `!!` - show command first

# Если включено, bash подставляет имена директорий из переменной во время автодополнения.
# http://xgu.ru/wiki/shopt
shopt -s direxpand 

# No search in PATH for empty console by TAB+TAB
shopt -s no_empty_cmd_completion
```

#### Smart history
```
# /etc/inputrc

# arrow up
"\e[A":history-search-backward
# arrow down
"\e[B":history-search-forward
```

#### Set default editor for CLI (`vim` recommended)
```sh
sudo update-alternatives --config editor
```

----
# Git
#### Aliases (~/.gitconfig)
https://githowto.com/ru/aliases
```
[alias]
  co = checkout
  ci = commit
  st = status
  br = branch
  hist = log --pretty=format:\"%h %ad | %s%d [%an]\" --graph --date=short
  type = cat-file -t
  dump = cat-file -p
```

----
# VIM tunings
```
set ignorecase          " Do case insensitive matching
set number		" Enable line numbers
set splitbelow		" Focus gets to new hor split open | bottom
set splitright 		" Focus gets to new ver split open | right
```

#### File manager
Set an extented view for VIM internal file manager
```
let g:netrw_liststyle = 1
```

By default files will be opened in the same window as the netrw directory browser. 
To change this behaviour the netrw_browse_split option may be set. The options are as follows
* 1 - open files in a new horizontal split
* 2 - open files in a new vertical split
* 3 - open files in a new tab
* 4 - open in previous window

```
let g:netrw_browse_split = 3
```

#### Advanced VIM look setup
Tune vim as a tab-manager with file explorer.
```
" File manager tunings
let g:netrw_liststyle = 1	" Display size, update date
let g:netrw_browse_split = 2	" Horizontal split
let g:netrw_altv = 1		" Open files in file manager in hor split mode
let g:netrw_winsize = 25	" 25% of viewport for file explorer

" On vim open run filemanager and move focus
augroup ProjectDrawer
  autocmd!
  autocmd VimEnter * :Vexplore " open file explorer
  autocmd VimEnter * wincmd l  " set focus to right pane
augroup END
```

