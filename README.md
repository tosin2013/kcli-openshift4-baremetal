## Purpose

This repository provides a plan which deploys a vm where:

- openshift-baremetal-install is downloaded with the specific version and tag specified (and renamed openshift-install)
- stop the nodes to deploy through redfish
- launch the install against a set of baremetal nodes. Virtual ctlplanes and workers can also be deployed.

The automation can be used for additional scenarios:

- only deploying the virtual infrastructure needed for a baremetal ipi deployment
- deploying a spoke cluster (either multinodes or SNO) through ZTP on top of the deployed Openshift

## Why

- To deploy baremetal using `bare minimum` on the provisioning node
- To ease deployments by providing an automated mechanism

### Requirements

#### for kcli

- kcli installed (for rhel8/cento8/fedora, look [here](https://kcli.readthedocs.io/en/latest/#package-install-method))
- an openshift pull secret (stored by default in openshift_pull.json)
- a valid openshift pull secret for ACM downstream if using ZTP this way.

#### on the provisioning node

- libvirt daemon (with fw_cfg support)
- two physical bridges:
    - baremetal with a nic from the external network
- If you're not running as root, configure extra permissions with `sudo setfacl -m u:$(id -un):rwx /var/lib/libvirt/openshift-images/*`

Here's a script you can run on the provisioning node for that (adjust the nics variable as per your environment)

```
export MAIN_CONN=eno2
sudo nmcli connection add ifname baremetal type bridge con-name baremetal
sudo nmcli con add type bridge-slave ifname $MAIN_CONN master baremetal
sudo nmcli con down $MAIN_CONN; sudo pkill dhclient; sudo dhclient baremetal
```

## Launch

Prepare a valid parameter file with the information needed. At least, you need to specify the following elements:

- api_ip
- ingress_ip
- bmc_user (for real baremetal)
- bmc_password (for real baremetal)
- an array of your ctlplanes (if thet are not virtual). Each entry in this array needs at least the provisioning_mac and redfish_address. Optionally you can indicate for each entry a specific bmc_user, bmc_password and disk (to be used as rootdevice hint) either as /dev/XXX or simply XXX
- an array of your workers (can be left empty if you only want to deploy ctlplanes). The format of those entries follow the one indicated for ctlplanes.

Here's a snippet what the workers variable might look like:

```
workers:
- ipmi_address: 192.168.1.5
  provisioning_mac: 98:03:9b:62:ab:19
- redfish_address: 192.168.1.6
  provisioning_mac: 98:03:9b:62:ab:17
  disk: /dev/sde
```

You can have a look at:

- [parameters.yml](samples/parameters.yml) for a parameter file targetting baremetal nodes only
- [parameters_virtual.yml](samples/parameters_virtual.yml) for one combining virtual ctlplanes and physical workers.

Call the resulting file `kcli_parameters.yml` to avoid having to specify it in the creation command.

Then you can launch deployment with:

```
kcli create plan
```

## Interacting in the vm

The deployed vm comes with a set of helpers for you:

- scripts deploy.sh and clean.sh allow you to manually launch an install or clean a failed one
- you can run *baremetal node list* during deployment to check the status of the provisioning of the nodes (Give some time after launching an install before ironic is accessible).
- script *redfish.py* to check the power status of the baremetal node or to stop them (using `redfish.py off`

## Parameters

### virtual infrastructure only parameters

Note that you can use the baseplan `kcli_plan_infra.yml` to deploy the infrastructure only

|Parameter                           |Default Value   |
|------------------------------------|--------------  |
|api_ip                              |None            |
|baremetal\_bootstrap\_mac           |None            |
|baremetal_cidr                      |None            |
|baremetal_ips                       |[]              |
|baremetal_macs                      |[]              |
|baremetal_net                       |baremetal       |
|cluster                             |openshift       |
|disk_size                           |30              |
|domain                              |karmalabs.corp  |
|dualstack                           |False           |
|dualstack_cidr                      |None            |
|extra_disks                         |[]              |
|http_proxy                          |None            |
|ingress_ip                          |None            |
|keys                                |[]              |
|lab                                 |False           |
|ctlplanes                            |[]              |
|memory                              |32768           |
|model                               |dell            |
|no_proxy                            |None            |
|numcpus                             |16              |
|pool                                |default         |
|virtual_ctlplanes                    |True            |
|virtual\_ctlplanes\_baremetal\_mac\_prefix|aa:aa:aa:cc:cc|
|virtual\_ctlplanes\_mac\_prefix       |aa:aa:aa:aa:aa  |
|virtual\_ctlplanes\_memory            |32768           |
|virtual\_ctlplanes\_number            |3               |
|virtual\_ctlplanes\_numcpus           |8               |
|virtual_protocol                    |ipmi            |
|virtual_workers                     |False           |
|virtual\_workers\_baremetal\_mac\_prefix|aa:aa:aa:dd:dd|
|virtual\_workers\_deploy            |True            |
|virtual\_workers\_mac_prefix        |aa:aa:aa:bb:bb  |
|virtual\_workers\_memory            |16384           |
|virtual\_workers\_number            |1               |
|virtual\_workers\_numcpus           |8               |
|workers                             |[]              |
|wait_for_workers                    |True            |
|wait_for_workers_number             |True            |
|wait_for_workers_exit_if_error      |False           |

### additional parameters

The following parameters are available when deploying the default plan

|Parameter                                    |Default Value                             |
|---------------------------------------------|------------------------------------------|
|bmc_password                                 |calvin                                    |
|bmc_user                                     |root                                      |
|cas                                          |[]                                        |
|deploy_openshift                             |True                                      |
|disconnected                                 |False                                     |
|disconnected_operators                       |[]                                        |
|disconnected\_operators\_deploy\_after\_openshift|False                                     |
|disconnected_password                        |dummy                                     |
|disconnected_user                            |dummy                                     |
|dualstack                                    |False                                     |
|dualstack_cidr                               |None                                      |
|fips                                         |False                                     |
|go_version                                   |1.13.8                                    |
|http_proxy                                   |None                                      |
|image                                        |centos8stream                             |
|image_url                                    |None                                      |
|imagecontentsources                          |[]                                        |
|imageregistry                                |False                                     |
|installer_mac                                |None                                      |
|installer_wait                               |False                                     |
|keys                                         |[]                                        |
|lab                                          |False                                     |
|launch_steps                                 |True                                      |
|model                                        |dell                                      |
|nbde                                         |False                                     |
|network_type                                 |OVNKubernetes                             |
|nfs                                          |True                                      |
|no_proxy                                     |None                                      |
|notify                                       |True                                      |
|notifyscript                                 |notify.sh                                 |
|ntp                                          |False                                     |
|ntp_server                                   |0.rhel.pool.ntp.org                       |
|numcpus                                      |16                                        |
|openshift_image                              |                                          |
|pullsecret                                   |openshift_pull.json                       |
|registry_image                               |quay.io/karmab/registry:amd64             |
|rhnregister                                  |True                                      |
|rhnwait                                      |30                                        |
|tag                                          |4.15                                      |
|version                                      |stable                                    |

### Node parameters

when specifying *ctlplanes* or *workers* as an array (for baremetal nodes), the specification can be created with something like this

```
- redfish_address: 192.168.123.45
  provisioning_mac: 98:03:9b:62:81:49
```

The following parameters can be used in this case:

- ipmi_address. Ipmi url
- redfish_address. Redfish url
- provisioning_mac. It needs to be set to the mac to use along with provisioning network or any of the macs of the node when provisioning is disabled
- boot_mode (optional). Should either be set to Legacy, UEFI or UEFISecureBoot
- bmc_user. If not specified, global bmc_password variable is used
- bmc_password.  If not specified, global bmc_password variable is used
- disk. Optional rootDeviceHint disk device
- ip, nic, gateway. Those attributes can be provided to set static networking using nmstate. Nic can be omitted. If gateway isn't provided, the static_gateway is used or gateway is guessed from baremetal_cidr
- network_config. Specific network config for the corresponding node, in nmstate format. (Requires 4.10+)

A valid network_config snippet would be

```
  network_config: |-
    routes:
      config:
      - destination: 0.0.0.0/0
        next-hop-address: 192.168.129.1
        next-hop-interface: ens3
    dns-resolver:
      config:
        search:
        - lab.karmalabs.corp
        server:
        - 192.168.129.1
    interfaces:
    - name: ens3
      type: ethernet
      state: up
      ipv4:
        address:
        - ip: "192.168.129.20"
          prefix-length: 24
        enabled: true
    interfaces:
    - name: ens3
      macAddress: aa:aa:aa:aa:bb:03
```

## Lab runthrough

A lab available [here](https://ocp-baremetal-ipi-lab.readthedocs.io/en/latest) is provided to get people familiarized with Baremetal Ipi workflow.

## Deploying a cluster through ZTP on top of your cluster

You can use the plan `kcli_plan_ztp.yml` for this purpose, along with the following parameters:

|Parameter                            |Default Value           |
|-------------------------------------|------------------------|
|ztp_nodes                             |[]                     |
|ztp\_spoke\_api\_ip                      |None                   |
|ztp\_spoke\_deploy                      |True                   |
|ztp\_spoke\_ingress\_ip                  |None                   |
|ztp\_spoke\_ctlplanes\_number              |1                      |
|ztp\_spoke\_name                        |mgmt-spoke1            |
|ztp\_spoke\_wait                        |False                  |
|ztp\_spoke\_wait_time                   |3600                   |
|ztp\_spoke\_workers_number              |0                      |
|ztp\_virtual\_nodes                     |False                  |
|ztp\_virtual\_nodes\_baremetal\_mac\_prefix|aa:aa:aa:cc:cc         |
|ztp\_virtual\_nodes\_disk\_size           |120                    |
|ztp\_virtual_nodes\_memory              |38912                  |
|ztp\_virtual\_nodes\_number              |1                      |
|ztp\_virtual\_nodes\_numcpus             |8                      |

## Sample parameter files

The following sample parameter files are available for you to deploy (on libvirt):

- [lab.yml](lab.yml) This deploys 3 ctlplanes in a dedicated ipv4 network
- [lab_ipv6.yml](lab_ipv6.yml) This deploys 3 ctlplanes in a dedicated ipv6 network (hence in a disconnected manner)
- [lab_ipv6_ztp.yml](lab_ipv6_ztp.yml) This deploys the ipv6 lab, and released acm on top, and then a SNO spoke
- [lab_ipv6_ztp_downstream.yml](lab_ipv6_ztp_downstream.yml) This is is the same as the ipv6 ztp lab, but the ACM bits are downstream one (this requires a dedicated pull secret)

## Running through github actions

Workflow files are available to deploy pipelines as a github action by using a self hosted runner. Just clone the repo and make use of them

- [lab.yml](.github/workflows/lab.yml)
- [lab_ipv6.yml](.github/workflows/lab_ipv6.yml)
- [lab_ipv6_ztp.yml](.github/workflows/lab_ipv6_ztp.yml)
- [lab_ipv6_ztp_downstream.yml](.github/workflows/lab_ipv6_ztp_downstream.yml)
- [lab_without_installer.yml](.github/workflows/lab_without_installer.yml) This deploys the infrastructure used in the lab plan (through the baseplan kcli_plan_infra.yml), it then deploys openshift without using an installer vm, but `kcli create cluster openshift` insteadusing `-P ipi=true -P ipi_platform=baremetal`

Note that you will use to store you pull secret somewhere in your runner, (`/root/openshift_pull.json` is the default location used in the workflow, which can be changed when launching the pipeline)

## Running on tekton

A pipeline and its corresponding run yaml files are available to deploy pipeline through tekton

- [pipeline.yml](extras/tekton/pipeline.yml)
- [run_lab.yml](extras/tekton/run_lab.yml)
- [run_lab_ipv6.yml](extras/tekton/run_lab_ipv6.yml)
- [run_lab_ipv6_ztp.yml](extras/tekton/run_lab_ipv6_ztp.yml)

You will need to create a configmap in target namespace to hold kcli configuration and make sure it points to a remote hypervisor

First copy your pull secret and a valid priv/pub key in the corresponding directory

Then make sure your config.yml contain something similar to the following

```
default:
  client: mykvm
mykvm:
  type: kvm
  host: 192.168.1.10
```

Create the relevant configmap

```
oc create configmap kcli-config --from-file=$HOME/.kcli
```

Then you can create the pipeline definition with `oc create -f pipeline.yml` and run a pipeline instance with `oc create -f run_lab.yml` for instance
