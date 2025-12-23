ZDOTDIR=${ZDOTDIR:-$HOME}

if locale -a | grep en_US.UTF-8 >/dev/null; then
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
  export LANGUAGE=en_US:en
fi

if [ -e "$ZDOTDIR/.zprofile.local" ]; then
  . "$ZDOTDIR/.zprofile.local"
fi
