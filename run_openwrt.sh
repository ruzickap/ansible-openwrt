#!/bin/bash -eux

ansible-playbook --diff main.yml -i inventory/hosts
