#!/usr/bin/env bash

set -eux

cd ansible
ansible-playbook --diff main.yml -i inventory/hosts
