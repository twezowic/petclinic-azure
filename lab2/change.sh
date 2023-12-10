#!/bin/bash
IP_FRONT_VM=$(az network public-ip show --resource-group wus_2 --name front --query "ipAddress" --output tsv)
IP_BACK_VM=$(az network public-ip show --resource-group wus_2 --name back --query "ipAddress" --output tsv)
IP_DATABASE_VM=$(az network public-ip show --resource-group wus_2 --name database --query "ipAddress" --output tsv)

complete_inventory_ip() {
    local VM_ID="$1"
    local IP="$2"
        echo "        $VM_ID:
          ansible_host: $IP
          ansible_password: MaciekMaciek1!
          ansible_user: azureuser" >> inventory.yaml
}

# Changing inventory file

echo "all:
  hosts:" > inventory.yaml
complete_inventory_ip "front_vm" "$IP_FRONT_VM"
complete_inventory_ip "back_vm" "$IP_BACK_VM"
complete_inventory_ip "database_vm" "$IP_DATABASE_VM"

ansible -i inventory.yaml all -m ping

# Changing config files

#1

sed -i "s/db_ip: .*/db_ip: $IP_DATABASE_VM/" vars/config_1.yaml
sed -i "s/    backend_ip: .*/    backend_ip: $IP_BACK_VM/" vars/config_1.yaml
sed -i "s/frontend_ip: .*/frontend_ip: $IP_FRONT_VM/" vars/config_1.yaml
sed -i "s/frontend_backend_ip: .*/frontend_backend_ip: $IP_BACK_VM/" vars/config_1.yaml

#2

sed -i "s/db_ip: .*/db_ip: $IP_DATABASE_VM/" vars/config_2.yaml
sed -i "s/    backend_ip: .*/    backend_ip: $IP_BACK_VM/" vars/config_2.yaml
sed -i "s/frontend_ip: .*/frontend_ip: $IP_FRONT_VM/" vars/config_2.yaml
sed -i "s/frontend_backend_ip: .*/frontend_backend_ip: $IP_FRONT_VM/" vars/config_2.yaml
sed -i "s/ngix_ip: .*/ngix_ip: $IP_BACK_VM/" vars/config_2.yaml

#5

sed -i "s/db_ip: .*/db_ip: $IP_DATABASE_VM/" vars/config_5.yaml
sed -i "s/db_slave_ip: .*/db__slave_ip: $IP_BACK_VM/" vars/config_5.yaml
sed -i "s/    backend_ip: .*/    backend_ip: $IP_BACK_VM/" vars/config_5.yaml
sed -i "s/frontend_ip: .*/frontend_ip: $IP_FRONT_VM/" vars/config_5.yaml
sed -i "s/frontend_backend_ip: .*/frontend_backend_ip: $IP_FRONT_VM/" vars/config_5.yaml
sed -i "s/ngix_ip: .*/ngix_ip: $IP_BACK_VM/" vars/config_5.yaml