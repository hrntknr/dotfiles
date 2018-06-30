#!/bin/bash
set -eu

HOST=${HOST:-localhost}
BASE=${BASE:-true}
CUI=${CUI:-false}
GUI=${GUI:-false}
CONNECTION=
[ ${HOST} = "localhost" ] && CONNECTION="local" || CONNECTION="ssh"
# echo "Target host: ${HOST}"
# echo "Base: ${BASE}"
# echo "CUI: ${CUI}"
# echo "GUI: ${GUI}"
# echo "Connection: ${CONNECTION}"

json=`cat << EOS
{
  "local": {
    "hosts": [
      "${HOST}"
    ],
    "vars": {
      "ansible_connection": "${CONNECTION}",
      "config_dotfiles": {
        "base": ${BASE},
        "cui": ${CUI},
        "gui": ${GUI}
      },
      "config_install": {
        "base": ${BASE},
        "cui": ${CUI},
        "gui": ${GUI}
      }
    }
  }
}
EOS
`

echo "${json}"
