#!/usr/bin/env bash

export IP=$(ip a s eth0 | grep 192 | awk {'print $2'} | sed s/\\/24//g)
export NETMASK=24
export INTERFACE=eth0
export GATEWAY=192.168.122.1

cat <<EOF > $HOME/standalone_parameters.yaml
parameter_defaults:
  CloudName: $IP
  ComputeHomeDir: $HOME
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
  ComputeEnableRoutedNetworks: false
  ComputeLocalMtu: 1400
EOF

if [[ ! -d ~/templates ]]; then
    ln -s /usr/share/openstack-tripleo-heat-templates ~/templates
fi

sudo openstack tripleo deploy \
  --templates ~/templates \
  --local-ip=$IP/$NETMASK \
  -r ~/edge/roles/Standalone-Compute.yaml \
  -e ~/templates/environments/standalone/standalone-tripleo.yaml \
  -e ~/templates/environments/ceph-ansible/ceph-ansible.yaml \
  -e ~/edge/environments/ceph_parameters.yaml \
  -e ~/edge/environments/standalone-edge.yaml \
  -e ~/containers-prepare-parameters.yaml \
  -e ~/standalone_parameters.yaml \
  -e ~/export_control_plane/passwords.yaml \
  -e ~/export_control_plane/endpoint-map.json \
  -e ~/export_control_plane/all-nodes-extra-map-data.json \
  -e ~/export_control_plane/extra-host-file-entries.json \
  -e ~/export_control_plane/oslo.yaml \
  --output-dir $HOME \
  --standalone $@
