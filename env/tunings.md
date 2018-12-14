# ~/.bashrc

## Colored prompt for root user 
```
export PS1="\[$(tput bold)\]\[\033[38;5;196m\]\u@\h\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;15m\]:\[$(tput sgr0)\]\[\033[38;5;129m\]\w\[$(tput sgr0)\]\[\033[38;5;15m\]\\$ \[$(tput sgr0)\]"
```

# /etc/inputrc

## Smart history
```
## arrow up
"\e[A":history-search-backward
## arrow down
"\e[B":history-search-forward
```

# Git aliases
# ~/.gitconfig
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
