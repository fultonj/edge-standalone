# Edge Development Environment

This automates (https://specs.openstack.org/openstack/tripleo-specs/specs/rocky/split-controlplane.html)[my edge development environment]. YMMV.

- Clone 3 VMs with playbook in [ansible](ansible/clone.yml)
- [bootstrap](bootstrap.sh) every VM
- [deploy central controller node](standalone-central.sh)
- [extract data for remote computes](create-compute-stack-env.sh)
- [deploy external computes](standalone-edge.sh)
- [test it](test.sh)
