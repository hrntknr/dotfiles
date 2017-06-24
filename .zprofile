if [ -e "$HOME/bin" ];then  
  export PATH=$HOME/bin:$PATH
fi

#nvm(node)
if [ -e "$HOME/.nvm" ]; then
  export NVM_DIR="$HOME/.nvm"
  if [ -e "/usr/local/opt/nvm/nvm.sh" ]; then
    . "/usr/local/opt/nvm/nvm.sh"
  elif [ -e "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
  fi
fi

#ruby
if [ -e "$HOME/.rbenv" ]; then
  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init -)"
fi

#python
if [ -e "$HOME/.pyenv/shims" ]; then
  export PATH=$HOME/.pyenv/shims:$PATH
fi

if [ -e "$HOME/.pyenv/bin" ]; then
  export PATH=$HOME/.pyenv/bin:$PATH
fi