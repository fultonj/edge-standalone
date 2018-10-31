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
  ComputeEnableRoutedNetworks: false
  ComputeHomeDir: $HOME
  ComputeLocalMtu: 1400
  # Needed if running in a VM
  ComputeExtraConfig:
    nova::compute::libvirt::services::libvirt_virt_type: qemu
    nova::compute::libvirt::libvirt_virt_type: qemu
    # oslo_messaging_notify_node_names: standalone-central.internalapi.localdomain
    # oslo_messaging_rpc_node_names: standalone-central.internalapi.localdomain
    # oslo_messaging_notify_password: JfMz1jMaQ5rtT9UxvgbjntizI
    # oslo_messaging_rpc_password: JfMz1jMaQ5rtT9UxvgbjntizI
    oslo_messaging_notify_use_ssl: false
    oslo_messaging_rpc_use_ssl: false
EOF

if [[ ! -d ~/templates ]]; then
    ln -s /usr/share/openstack-tripleo-heat-templates ~/templates
fi

sudo openstack tripleo deploy \
  --templates ~/templates \
  --local-ip=$IP/$NETMASK \
  -e ~/templates/environments/standalone.yaml \
  -r ~/edge/roles/Standalone-Compute.yaml \
  -e ~/edge/environments/standalone-edge.yaml \
  -e ~/standalone_parameters.yaml \
  -e ~/export_control_plane/passwords.yaml \
  -e ~/export_control_plane/endpoint-map.json \
  -e ~/export_control_plane/all-nodes-extra-map-data.json \
  -e ~/export_control_plane/extra-host-file-entries.json \
  -e ~/export_control_plane/oslo.yaml \
  --output-dir $HOME \
  --standalone $@
