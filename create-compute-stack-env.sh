#!/usr/bin/env bash
DIR=export_control_plane

if [[ -d $DIR ]]; then rm -rf $DIR; fi
mkdir $DIR

export OS_AUTH_TYPE=none
export OS_ENDPOINT=http://127.0.0.1:8006/v1/admin

openstack stack output show standalone EndpointMap --format json | jq '{"parameter_defaults": {"EndpointMapOverride": .output_value}}' > $DIR/endpoint-map.json

openstack stack output show standalone AllNodesConfig --format json | jq '{"parameter_defaults": {"AllNodesExtraMapData": .output_value}}' > $DIR/all-nodes-extra-map-data.json

openstack stack output show standalone HostsEntry -f json | jq -r '{"parameter_defaults":{"ExtraHostFileEntries": .output_value}}' > $DIR/extra-host-file-entries.json

# use ~/tripleo-undercloud-passwords.yaml as the following won't work
# openstack object save standalone plan-environment.yaml
cp ~/tripleo-undercloud-passwords.yaml $DIR/passwords.yaml

echo "parameter_defaults:" > $DIR/oslo.yaml
echo "  ComputeExtraConfig:" >> $DIR/oslo.yaml
egrep "oslo.*password"  /etc/puppet/hieradata/service_configs.json | sed -e s/\"//g -e s/,//g >> $DIR/oslo.yaml

tar cvfz $DIR.tar.gz $DIR/
