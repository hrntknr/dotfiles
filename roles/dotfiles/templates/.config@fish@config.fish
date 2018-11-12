#direnv
if type direnv > /dev/null 2>&1
  eval (direnv hook fish)
end

alias l='ls -ltrG'
alias ls='ls -G'
alias sl='ls -G'
alias la='ls -laG'
alias ll='ls -lG'
alias git-wc='git ls-files | xargs -n1 git --no-pager blame -w | wc'
alias git-lg="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
alias git-lga="git log --graph --all --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"

switch (uname)
case Darwin
  alias netstat-lntp='lsof -nP -iTCP -sTCP:LISTEN'
  alias top='top -u -s5'
  alias c='pbpaste | vipe | pbcopy'
  alias subl='/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl'
case Linux
  alias open='xdg-open'
end

if type docker > /dev/null 2>&1
  alias redis='docker run -p 127.0.0.1:6379:6379 -d --rm --name redis redis'
  alias mysqld='docker run -p 127.0.0.1:3306:3306 -d --rm --name mysql -e MYSQL_ROOT_PASSWORD=pass mysql'
  if type mysql > /dev/null 2>&1
    alias mysql_='mysql -h 127.0.0.1 -u root --password=pass'
  end
  alias docker-mongo='docker run -p 127.0.0.1:27017:27017 -d --rm --name mongo mongo'
  alias docker-mongo-express='docker run -p 127.0.0.1:8081:8081 -d --rm --name mongo-express --link mongo:mongo mongo-express'
end
