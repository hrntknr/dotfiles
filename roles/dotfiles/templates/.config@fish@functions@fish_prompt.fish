function gitStatus
  # local branch_name st branch_status
  if [ ! -e  ".git" ]
    echo
    return
  end

  set branch_name (git rev-parse --abbrev-ref HEAD 2> /dev/null)
  set st (git status 2> /dev/null)
  if test 0 != (echo "$st" | grep "nothing to" | grep -c \^)
    set branch_status (set_color green)
  else if test 0 != (echo "$st" | grep "Untracked files" | grep -c \^)
    set branch_status (printf '%s?' (set_color red))
  else if test 0 != (echo "$st" | grep "Changes not staged for commit" | grep -c \^)
    set branch_status (printf '%s+' (set_color red))
  else if test 0 != (echo "$st" | grep "Changes to be committed" | grep -c \^)
    set branch_status (printf '%s!' (set_color yellow))
  else if test 0 != (echo "$st" | grep "rebase in progress" | grep -c \^)
    printf '%s!(no branch)' (set_color red)
    return
  else
    set branch_status (set_color magenta)
  end
  printf "%s[%s]%s" $branch_status $branch_name (set_color normal)
end

function fish_prompt -d 'Write out the prompt'
  if type md5sum > /dev/null 2>&1
    set HOSTCOLOR (set_color (hostname|md5sum|cut -c1-6))
  else if type md5 > /dev/null 2>&1
    set HOSTCOLOR (set_color (hostname|md5|cut -c1-6))
  else
    set HOSTCOLOR (set_color normal)
  end
  printf '\n%s %s %s\n%s' \
    (printf '%s@%s%s%s' (whoami) $HOSTCOLOR (hostname) (set_color normal)) \
    (prompt_pwd) \
    (gitStatus) \
    (printf '%s%s%s%s' '❯❯❯' (set_color $fish_color_cwd) ' $ ' (set_color normal))
end

function ignore
  curl -f https://raw.githubusercontent.com/github/gitignore/master/(echo $argv[1]|awk '{print toupper(substr($1,1,1))substr($1,2)}').gitignore >> .gitignore
end
