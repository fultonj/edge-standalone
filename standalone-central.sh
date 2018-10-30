#!/usr/bin/env bash

export IP=$(ip a s eth0 | grep 192 | awk {'print $2'} | sed s/\\/24//g)
export NETMASK=24
export INTERFACE=eth0
export GATEWAY=192.168.122.1

cat <<EOF > $HOME/standalone_parameters.yaml
parameter_defaults:
  CertmongerCA: local
  CloudName: $IP
  ContainerImagePrepare:
  - set:
      ceph_image: daemon
      ceph_namespace: docker.io/ceph
      ceph_tag: v3.1.0-stable-3.1-luminous-centos-7-x86_64
      name_prefix: centos-binary-
      name_suffix: ''
      namespace: docker.io/tripleomaster
      neutron_driver: null
      tag: current-tripleo
    tag_from_label: rdo_version
  # default gateway
  ControlPlaneStaticRoutes:
    - ip_netmask: 0.0.0.0/0
      next_hop: $GATEWAY
      default: true
  Debug: true
  DeploymentUser: $USER
  DnsServers:
    - 8.8.4.4
    - 8.8.8.8
  # needed for vip & pacemaker
  KernelIpNonLocalBind: 1
  DockerInsecureRegistryAddress:
  - $IP:8787
  NeutronPublicInterface: $INTERFACE
  # domain name used by the host
  NeutronDnsDomain: localdomain
  # re-use ctlplane bridge for public net
  NeutronBridgeMappings: datacentre:br-ctlplane
  NeutronPhysicalBridge: br-ctlplane
  # enable to force metadata for public net
  #NeutronEnableForceMetadata: true
  StandaloneEnableRoutedNetworks: false
  StandaloneHomeDir: $HOME
  StandaloneLocalMtu: 1400
  # Needed if running in a VM
  StandaloneExtraConfig:
    nova::compute::libvirt::services::libvirt_virt_type: qemu
    nova::compute::libvirt::libvirt_virt_type: qemu
EOF

if [[ ! -d ~/templates ]]; then
    ln -s /usr/share/openstack-tripleo-heat-templates ~/templates
fi

sudo openstack tripleo deploy \
  --templates ~/templates \
  --local-ip=$IP/$NETMASK \
  -e ~/templates/environments/standalone.yaml \
  -r ~/templates/roles/Standalone.yaml \
  -e $HOME/standalone_parameters.yaml \
  --output-dir $HOME \
  --standalone \
  --keep-running

# use --keep-runing so it doesn't destroy the heat processes
# which create-compute-stack-env.sh depends on
# if you need to redeploy, first kill those heat processes
