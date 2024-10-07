#!/usr/bin/env bash

set -euo pipefail

[ -d /root/manifests ] || mkdir -p /root/manifests
CONFIG_HOST={{ config_host if config_host not in ['127.0.0.1', 'localhost'] else baremetal_net|local_ip }}
if [ -n "$CONFIG_HOST" ] ; then
ssh-keyscan -H $CONFIG_HOST >> ~/.ssh/known_hosts
echo -e "Host=*\nStrictHostKeyChecking=no\n" > ~/.ssh/config
fi

{% if not disconnected %}
PULLSECRET=$(cat /root/openshift_pull.json | tr -d [:space:])
echo -e "pullSecret: |\n  $PULLSECRET" >> /root/install-config.yaml
{% endif %}

if [ ! -f /root/.ssh/id_rsa.pub ] ; then
  ssh-keygen -qt rsa -N '' -f /root/.ssh/id_rsa
fi
SSHKEY=$(cat /root/.ssh/id_rsa.pub)
echo -e "sshKey: |\n  $SSHKEY" >> /root/install-config.yaml
