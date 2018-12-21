#!/usr/bin/env bash

export IP=$(ip a s eth0 | grep 192 | awk {'print $2'} | sed s/\\/24//g)
export NETMASK=24
export INTERFACE=eth0
export GATEWAY=192.168.122.1

cat <<EOF > $HOME/standalone_parameters.yaml
parameter_defaults:
  CloudName: $IP
  StandaloneHomeDir: $HOME
  DeploymentUser: $USER
  DockerInsecureRegistryAddress:
  - $IP:8787
  ControlPlaneStaticRoutes:
    - ip_netmask: 0.0.0.0/0
      next_hop: $GATEWAY
      default: true
  NeutronPublicInterface: $INTERFACE
  # static
  DnsServers:
    - 8.8.4.4
    - 8.8.8.8
  CertmongerCA: local
  Debug: true
  # needed for vip & pacemaker
  KernelIpNonLocalBind: 1
  # domain name used by the host
  NeutronDnsDomain: localdomain
  # re-use ctlplane bridge for public net
  NeutronBridgeMappings: datacentre:br-ctlplane
  NeutronPhysicalBridge: br-ctlplane
  # enable to force metadata for public net
  #NeutronEnableForceMetadata: true
  # Needed if running in a VM
  NovaComputeLibvirtType: qemu
  # role specific
  StandaloneEnableRoutedNetworks: false
  StandaloneLocalMtu: 1400
  # Do I need this? 
  # StandaloneExtraConfig:
  #   nova::compute::libvirt::services::libvirt_virt_type: qemu
  #   nova::compute::libvirt::libvirt_virt_type: qemu
  #   oslo_messaging_notify_use_ssl: false
  #   oslo_messaging_rpc_use_ssl: false
EOF

if [[ ! -d ~/templates ]]; then
    ln -s /usr/share/openstack-tripleo-heat-templates ~/templates
fi

sudo openstack tripleo deploy \
  --templates ~/templates \
  --local-ip=$IP/$NETMASK \
  -r ~/templates/roles/Standalone.yaml \
  -e ~/templates/environments/standalone.yaml \
  -e ~/templates/environments/ceph-ansible/ceph-ansible.yaml \
  -e ~/edge/environments/ceph_parameters.yaml \
  -e ~/edge/environments/central_parameters.yaml \
  -e ~/containers-prepare-parameters.yaml \
  -e ~/standalone_parameters.yaml \
  --output-dir $HOME \
  --standalone \
  --keep-running

# use --keep-runing so it doesn't destroy the heat processes
# which create-compute-stack-env.sh depends on
# if you need to redeploy, first kill those heat processes
