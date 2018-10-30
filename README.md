# Edge Development Environment

This automates my [split control plane](https://specs.openstack.org/openstack/tripleo-specs/specs/rocky/split-controlplane.html) proof of concept for use with edge deployments. YMMV.

- Clone 3 VMs to deploy with [clone.yml](ansible/clone.yml)
- Deploy 1 central and 2 edge nodes and test with [deploy_and_test.yml](ansible/deploy_and_test.yml)

The [deploy_and_test.yml](ansible/deploy_and_test.yml) playbook calls the following shell scripts on the appropriate nodes:

- [bootstrap](bootstrap.sh) every VM
- [deploy central controller node](standalone-central.sh)
- [extract data for remote computes](create-compute-stack-env.sh)
- [deploy external computes](standalone-edge.sh)
- [test it](test.sh)

## To Do

- clean up Heat environment files and shell scripts
- get it working with Ceph
