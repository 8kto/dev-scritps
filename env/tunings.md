# Terminal tunings
#### Smart incremental history search
The first two commands bind your up and down cursor keys to incrementally search your history. 
The second two ensure that left and right continue to work correctly.
```
# ~/.inputrc or /etc/inputrc for all users

# arrow up
"\e[A":history-search-backward
# arrow down
"\e[B":history-search-forward

# ~/.bashrc
# These simply set your history to be very large so that you have a huge bank of commands to search.
export HISTSIZE=100000
export HISTFILESIZE=100000000
```


#### Colored prompt for root 
```
# ~/.bashrc
export PS1="\[$(tput bold)\]\[\033[38;5;196m\]\u@\h\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;15m\]:\[$(tput sgr0)\]\[\033[38;5;129m\]\w\[$(tput sgr0)\]\[\033[38;5;15m\]\\$ \[$(tput sgr0)\]"
```


#### Current git branch in prompt + current base dir (instead of full path)
```sh
# Add git branch if it's present to PS1
parse_git_branch() {
 git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}
if [ "$color_prompt" = yes ]; then
  # Comment out one the next PS1s:
  # Git branch
  PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[01;31m\]$(parse_git_branch)\[\033[00m\]\$ '
  # Git branch + short path
  PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u:\[\033[01;34m\]\W\[\033[01;31m\]$(parse_git_branch)\[\033[00m\]\$ '
else
  PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w$(parse_git_branch)\$ '
fi
unset color_prompt force_color_prompt
```


#### Generate your own bash prompt
Use this online tool: http://bashrcgenerator.com/


#### Misc enhancements
Docs:
+ EN: https://wiki.bash-hackers.org/commands/builtin/shopt
+ EN: https://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html
+ RU: http://xgu.ru/wiki/shopt
+ RU: https://habr.com/ru/post/452522/

```sh
# ~/.bashrc
shopt -s cdspell    # fix typos in commands
shopt -s autocd     # change disk wo `cd` typing
shopt -s checkjobs  # no exit when running tasks
shopt -s histverify # when `!!` - show command first
shopt -s no_empty_cmd_completion # No search in PATH for empty console by TAB+TAB
```


#### Set default editor for CLI
`vim` recommended 😏
```sh
sudo update-alternatives --config editor
```
