#!/bin/env sh

yum install ansible-core podman openssl -y
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install containers.podman

