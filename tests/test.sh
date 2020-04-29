#!/bin/bash
set -e

vagrant up --provision

export ANSIBLE_CONFIG=ansible.cfg
export ANSIBLE_DISPLAY_SKIPPED_HOSTS=False

echo "Waiting for answer on port 22..."
while ! timeout 1 nc -z 192.168.33.82 22; do
  sleep 0.2
done

ansible-playbook -i inventory.ini test.yml $*

ansible-playbook -i inventory.ini test.yml \
  | grep -q 'changed=0.*failed=0' \
  && (echo 'Idempotence test: pass' && exit 0) \
  || (echo 'Idempotence test: fail' && exit 1)

#vagrant destroy -f
