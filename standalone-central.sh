#!/usr/bin/env bash

export ZONE=central
export INTERFACE=eth0
export IP=$(ip a s $INTERFACE | grep 192 | awk {'print $2'} | sed s/\\/24//g)
export NETMASK=24
export DNS_SERVERS=192.168.122.1
export NTP_SERVERS=pool.ntp.org

sudo sh -c "echo standalone-${ZONE} > /etc/hostname ; hostname -F /etc/hostname"

cat <<EOF > $HOME/standalone_parameters.yaml
parameter_defaults:
  CertmongerCA: local
  CloudName: $IP
  ControlPlaneStaticRoutes: []
  Debug: true
  DeploymentUser: $USER
  DnsServers: $DNS_SERVERS
  NtpServer: $NTP_SERVERS
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
    oslo_messaging_notify_use_ssl: false
    oslo_messaging_rpc_use_ssl: false
EOF

if [ ! -f $HOME/ceph_parameters.yaml ]; then
  cat <<EOF > $HOME/ceph_parameters.yaml
parameter_defaults:
  CephAnsibleDisksConfig:
    devices:
      - /dev/loop3
    journal_size: 1024
  CephAnsibleExtraConfig:
    osd_scenario: collocated
    osd_objectstore: filestore
    cluster_network: 192.168.24.0/24
    public_network: 192.168.24.0/24
  CephPoolDefaultPgNum: 32
  CephPoolDefaultSize: 1
  CephAnsiblePlaybookVerbosity: 3
  LocalCephAnsibleFetchDirectoryBackup: /root/ceph_ansible_fetch
EOF
fi

cat <<EOF > $HOME/central_parameters.yaml
parameter_defaults:
  GlanceBackend: swift
  StandaloneExtraConfig:
    cinder::backend_host: ''
EOF

if [[ ! -d ~/templates ]]; then
    ln -s /usr/share/openstack-tripleo-heat-templates ~/templates
fi

sudo pkill -9 heat-all # Remove any previously running heat processes
sudo openstack tripleo deploy \
  --templates ~/templates \
  --local-ip=$IP/$NETMASK \
  -e ~/templates/environments/standalone.yaml \
  -e ~/templates/environments/ceph-ansible/ceph-ansible.yaml \
  -r ~/templates/roles/Standalone.yaml \
  -e ~/containers-prepare-parameters.yaml \
  -e ~/standalone_parameters.yaml \
  -e ~/ceph_parameters.yaml \
  -e ~/central_parameters.yaml \
  --output-dir $HOME \
  --keep-running \
  --standalone $@
