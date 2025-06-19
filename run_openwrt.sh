#!/usr/bin/env bash

set -eux

cd ansible || exit
ansible-playbook --diff main.yml -i inventory/hosts
