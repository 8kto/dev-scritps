# Git
#### Aliases: beginner
Add these into `~/.gitconfig` 
(https://githowto.com/aliases)
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

#### Aliases: PRO

```shell script
#!/bin/bash
# ~/.profile

alias gs='git status '
alias ga='git add '
alias gb='git branch '
alias gc='git commit'
alias gd='git diff'
alias gp='git push'
alias go='git checkout ' 
alias gk='gitk --all&'
alias gx='gitx --all'

alias got='git '
alias get='git '

# Enable autocompletion for the aliases above
[ -f /usr/share/bash-completion/completions/git ] && . /usr/share/bash-completion/completions/git
__git_complete ga _git_add
__git_complete gc _git_commit
__git_complete gp _git_push
__git_complete go _git_checkout
__git_complete gb _git_branch
```
