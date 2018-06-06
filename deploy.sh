#!/bin/sh
ansible-playbook -i ./hosts.sh playbook.yml --ask-become-pass
