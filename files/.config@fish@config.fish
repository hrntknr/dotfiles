set -x LANG en_US.UTF-8
set -x LC_ALL en_US.UTF-8

if [ -e "$HOME/.local/bin" ]
  set -x PATH "$HOME/.local/bin:$PATH"
end

#direnv
if type direnv > /dev/null 2>&1
  eval (direnv hook fish | source)
end

#nvm(node)
# fisher add jorgebucaran/fnm

# adb
if [ -e "$HOME/Library/Android/sdk/platform-tools" ]
  set -x PATH "$HOME/Library/Android/sdk/platform-tools:$PATH"
end

#go
if type go > /dev/null 2>&1
  set -x GO111MODULE on
  if [ -e "$HOME/work" ]
    set -x GOPATH "$HOME/work/go"
  else if [ -e "$HOME/go" ]
    set -x GOPATH "$HOME/go"
  else
    set -x GOPATH "$HOME/.go"
  end
  if [ -e "$GOPATH/bin" ]
    set -x PATH "$PATH:$GOPATH/bin"
  end
end

#ruby
if [ -e "$HOME/.rbenv" ]
  set -x PATH "$HOME/.rbenv/bin:$PATH"
  eval (rbenv init - | source)
end

#python
if [ -e "$HOME/.pyenv" ]
  set -x PYENV_ROOT "$HOME/.pyenv"
  set -x PATH "$PYENV_ROOT/bin:$PATH"
  eval (pyenv init - | source)
end

#rust
if [ -e "$HOME/.cargo" ]
  set -x PATH "$HOME/.cargo/bin:$PATH"
end

#java
if [ -e "/usr/libexec/java_home" ]
  set -x JAVA_HOME (/usr/libexec/java_home)
  set -x PATH "$JAVA_HOME/bin:$PATH"
end

if [ -e "/usr/local/sbin" ]
  set -x PATH "/usr/local/sbin/:$PATH"
end

#fisher add oh-my-fish/plugin-peco
function fish_user_key_bindings
  bind \cr peco_select_history # Bind for prco history to Ctrl+r
end

set __fish_git_prompt_showdirtystate 'yes'
set __fish_git_prompt_showstashstate 'yes'
set __fish_git_prompt_showupstream 'yes'
set __fish_git_prompt_showuntrackedfiles 'yes'
set __fish_git_prompt_show_informative_status 'yes'
set __fish_git_prompt_showcolorhints 'yes'

function fish_prompt
  switch "$USER"
  case root toor
    set prompt_symbol '#'
  case '*'
    set prompt_symbol '$'
  end
  if type md5sum > /dev/null 2>&1
    set host_color (hostname|md5sum|md5sum|cut -c1-6)
  else if type md5 > /dev/null 2>&1
    set host_color (hostname|md5|md5|cut -c1-6)
  else
    set host_color 0
  end
  printf "\n%s@%s%s%s %s %s" (whoami) (set_color $host_color) (hostname) (set_color white) (basename (pwd)) (__fish_git_prompt)
  printf "\n> %s$prompt_symbol%s " (set_color brgreen) (set_color white)
end

alias l='ls -ltrG'
alias ls='ls -G'
if type nvim > /dev/null 2>&1
  alias vim='nvim'
  alias vi='nvim'
end

