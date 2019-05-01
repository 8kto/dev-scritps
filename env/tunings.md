#Colored prompt for root user 
## ~/.bashrc
```
export PS1="\[$(tput bold)\]\[\033[38;5;196m\]\u@\h\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;15m\]:\[$(tput sgr0)\]\[\033[38;5;129m\]\w\[$(tput sgr0)\]\[\033[38;5;15m\]\\$ \[$(tput sgr0)\]"
```

# Smart history
## /etc/inputrc
```
# arrow up
"\e[A":history-search-backward
# arrow down
"\e[B":history-search-forward
```

# Git aliases
## ~/.gitconfig
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

# Set default editor for CLI (`vim` recommended)
```sh
sudo update-alternatives --config editor
```

# vim tunings
```
set ignorecase          " Do case insensitive matching
set number		" Enable line numbers

# Set an extented view for VIM internal file manager
let g:netrw_liststyle = 1

# By default files will be opened in the same window as the netrw directory browser. 
# To change this behaviour the netrw_browse_split option may be set. The options are as follows
# 1 - open files in a new horizontal split
# 2 - open files in a new vertical split
# 3 - open files in a new tab
# 4 - open in previous window
let g:netrw_browse_split = 3

```

# Mount ntfs partitions
```
apt install ntfs-config
```

# Install LAMP stack
https://www.linode.com/docs/web-servers/lamp/install-lamp-stack-on-ubuntu-18-04/



