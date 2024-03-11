#!/usr/bin/env bash

{% set spoke = ztp_spokes[index] %}
{% set spoke_name = spoke.name %}
{% set spoke_api_ip = spoke.get('api_ip') %}
{% set spoke_ingress_ip = spoke.get('ingress_ip') %}
{% set spoke_ctlplanes_number = spoke.get('ctlplanes_number', 1) %}
{% set spoke_workers_number = spoke.get('workers_number', 0) %}
{% set spoke_deploy = spoke.get('deploy', True) %}
{% set spoke_network_type = spoke.get('network_type', ztp_spoke_network_type) %}

echo export SPOKE={{ spoke_name }} >> /root/.bashrc
{% if spoke_ctlplanes_number > 1 and spoke_api_ip != None and spoke_ingress_ip != None %}
echo {{ spoke_api_ip}} api.{{ spoke_name }}.{{ domain }} >> /etc/hosts
{% endif %}
OCP_RELEASE=$(openshift-install version | head -1 | cut -d' ' -f2)-x86_64
export MINOR=$(echo $OCP_RELEASE | cut -d. -f1,2)
export PULLSECRET=$(cat /root/openshift_pull.json | tr -d [:space:])
export SPOKE={{ spoke_name }}
export DOMAIN={{ domain }}

export MASTERS_NUMBER={{ spoke_ctlplanes_number }}
export WORKERS_NUMBER={{ spoke_workers_number }}
export SSH_PUB_KEY=$(cat /root/.ssh/id_rsa.pub)

[ -d /root/spoke_$SPOKE/manifests ] && /root/spoke_$SPOKE/manifests.sh
envsubst < /root/spoke_$SPOKE/spoke.sample.yml >> /root/spoke_$SPOKE/spoke.yml

{% if spoke_deploy %}
oc create namespace $SPOKE
[ -f /root/spoke_$SPOKE/nmstate.yaml ] && oc create -n $SPOKE -f /root/spoke_$SPOKE/nmstate.yaml
[ -f /root/spoke_$SPOKE/manifests.yml ] && oc create -n $SPOKE -f /root/spoke_$SPOKE/manifests.yml
oc create -f /root/spoke_$SPOKE/spoke.yml
bash /root/spoke_$SPOKE/bmc.sh
{% endif %}
