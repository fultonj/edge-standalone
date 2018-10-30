#!/usr/bin/env bash
DIR=export_control_plane

if [[ -d $DIR ]]; then rm -rf $DIR; fi
mkdir $DIR

if [[ ! -e /usr/bin/json2yaml ]]; then
   sudo yum install -y npm
   sudo npm install -g json2yaml
fi

export OS_AUTH_TYPE=none
export OS_ENDPOINT=http://127.0.0.1:8006/v1/admin

openstack stack output show standalone EndpointMap --format json | jq '{"parameter_defaults": {"EndpointMapOverride": .output_value}}' > $DIR/endpoint-map.json

openstack stack output show standalone AllNodesConfig --format json | jq '{"parameter_defaults": {"AllNodesExtraMapData": .output_value}}' > $DIR/all-nodes-extra-map-data.json

openstack stack output show standalone HostsEntry -f json | jq -r '{"parameter_defaults":{"ExtraHostFileEntries": .output_value}}' > $DIR/extra-host-file-entries.json

pushd $DIR
for OLD_FILE in $(ls *.json); do
    NEW_FILE=$(echo $OLD_FILE | sed s/json/yaml/g)
    json2yaml $OLD_FILE > $NEW_FILE
done
rm *.json
popd

# use ~/tripleo-undercloud-passwords.yaml as the following won't work
# openstack object save standalone plan-environment.yaml
cp ~/tripleo-undercloud-passwords.yaml $DIR/passwords.yaml

echo "parameter_defaults:" > $DIR/oslo.yaml
echo "  ComputeExtraConfig:" >> $DIR/oslo.yaml
egrep "oslo.*password"  /etc/puppet/hieradata/service_configs.json | sed -e s/\"//g -e s/,//g >> $DIR/oslo.yaml

tar cvfz $DIR.tar.gz $DIR/
