#!/usr/bin/env bash
cd /root

ansible-playbook ./playbooks/provision.playbook.yaml
echo "Provisioning done!!!"

if [[ -f /root/ansible.reboot ]]; then
    echo "After WSL has rebooted your instance is ready"
    echo "Shutting WSL down now"
    rm -rf /root/ansible.reboot
    wsl.exe --shutdown
fi
