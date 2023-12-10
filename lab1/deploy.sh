#!/bin/bash

set -euxo pipefail

if [ $# -lt 1 ]; then
    echo 1>&2 "$0: not enough arguments"
    echo "Usage: $0 CONFIG_FILE"
    exit 2
fi

CONFIG_FILE="$1"

echo $CONFIG_FILE

RESOURCE_GROUP="$(jq -r '.resource_group' "$CONFIG_FILE")"

echo $RESOURCE_GROUP

az login

az group create --name $RESOURCE_GROUP --location westeurope

# Network
NETWORK_ADDRESS_PREFIX="$(jq -r '.network.address_prefix' "$CONFIG_FILE")"

az network vnet create \
    --resource-group $RESOURCE_GROUP \
    --name VNet \
    --address-prefix $NETWORK_ADDRESS_PREFIX \
    --no-wait

# Network Security Group
readarray -t NETWORK_SECURITY_GROUPS < <(jq -c '.network_security_group[]' "$CONFIG_FILE")

for GROUP in "${NETWORK_SECURITY_GROUPS[@]}"; do
    echo $GROUP

    GROUP_NAME=$(jq -r '.name' <<<$GROUP)

    az network nsg create \
        --resource-group $RESOURCE_GROUP \
        --name $GROUP_NAME

    readarray -t RULES < <(jq -c '.rule[]' <<<$GROUP)

    for RULE in "${RULES[@]}"; do
        echo $RULE

        RULE_NAME=$(jq -r '.name' <<<$RULE)
        RULE_PRIORITY=$(jq -r '.priority' <<<$RULE)
        RULE_SOURCE_ADDRESS_PREFIX=$(jq -r '.source_address_prefixes' <<<$RULE)
        RULE_SOURCE_PORT_RANGES=$(jq -r '.source_port_ranges' <<<$RULE)
        RULE_DESTINATION_ADDRESS_PREFIX=$(jq -r '.destination_address_prefixes' <<<$RULE)
        RULE_DESTINATION_PORT_RANGES=$(jq -r '.destination_port_ranges' <<<$RULE)

        az network nsg rule create \
            --resource-group $RESOURCE_GROUP \
            --nsg-name $GROUP_NAME \
            --name $RULE_NAME \
            --access allow \
            --protocol Tcp \
            --priority $RULE_PRIORITY \
            --source-address-prefix "$RULE_SOURCE_ADDRESS_PREFIX" \
            --source-port-range "$RULE_SOURCE_PORT_RANGES" \
            --destination-address-prefix "$RULE_DESTINATION_ADDRESS_PREFIX" \
            --destination-port-range "$RULE_DESTINATION_PORT_RANGES" \
            --no-wait
    done
done

# Subnet
readarray -t SUBNETS < <(jq -c '.subnet[]' "$CONFIG_FILE")

for SUBNET in "${SUBNETS[@]}"; do
    echo $SUBNET

    SUBNET_NAME=$(jq -r '.name' <<<$SUBNET)
    SUBNET_ADDRESS_PREFIX=$(jq -r '.address_prefix' <<<$SUBNET)
    SUBNET_NETWORK_SECURITY_GROUP=$(jq -r '.network_security_group' <<<$SUBNET)
    echo $SUBNET_NAME

    az network vnet subnet create \
        --resource-group $RESOURCE_GROUP \
        --vnet-name VNet \
        --name $SUBNET_NAME \
        --address-prefix $SUBNET_ADDRESS_PREFIX \
        --network-security-group "$SUBNET_NETWORK_SECURITY_GROUP" \
        --no-wait
done

# Public IP
readarray -t PUBLIC_IPS < <(jq -c '.public_ip[]' "$CONFIG_FILE")

for PUBLIC_IP in "${PUBLIC_IPS[@]}"; do
    echo $PUBLIC_IP

    PUBLIC_IP_NAME=$(jq -r '.name' <<<$PUBLIC_IP)

    az network public-ip create \
        --resource-group $RESOURCE_GROUP \
        --name $PUBLIC_IP_NAME
done

# Virtual Machine
readarray -t VIRTUAL_MACHINES < <(jq -c '.virtual_machine[]' "$CONFIG_FILE")

for VM in "${VIRTUAL_MACHINES[@]}"; do
    echo $VM

    VM_NAME=$(jq -r '.name' <<<$VM)
    VM_SUBNET=$(jq -r '.subnet' <<<$VM)
    VM_PRIVATE_IP_ADDRESS=$(jq -r '.private_ip_address' <<<$VM)
    VM_PUBLIC_IP_ADDRESS=$(jq -r '.public_ip_address' <<<$VM)

    az vm create \
        --resource-group $RESOURCE_GROUP \
        --vnet-name VNet \
        --name $VM_NAME \
        --subnet $VM_SUBNET \
        --nsg "" \
        --private-ip-address "$VM_PRIVATE_IP_ADDRESS" \
        --public-ip-address "$VM_PUBLIC_IP_ADDRESS" \
        --image Ubuntu2204 \
        --admin-username azureuser \
        --admin-password MaciekMaciek1! \
        --no-wait
done

echo "WAITING FOR VIRTUAL MACHINES..."

az vm wait --created --ids $(az vm list -g $RESOURCE_GROUP --query "[].id" -o tsv)

readarray -t SCRIPTS < <(jq -c '.scripts[]' "$CONFIG_FILE")

for SCRIPT in "${SCRIPTS[@]}"; do
    SERVICE_TYPE=$(jq -r '.type' <<<$SCRIPT)
    SERVICE_PORT=$(jq -r '.port' <<<$SCRIPT)
    VM_NAME=$(jq -r '.vname' <<<$SCRIPT)

    case $SERVICE_TYPE in

        frontend)
                echo Setting up frontend

                SERVER_ADDRESS=$(jq -r '.backend_address' <<<$SCRIPT)
                SERVER_IP=$(az network public-ip show --resource-group "$RESOURCE_GROUP" --name "$SERVER_ADDRESS" --query "ipAddress" --output tsv)
                SERVER_PORT=$(jq -r '.backend_port' <<<$SCRIPT)

                az vm run-command invoke \
                    --resource-group $RESOURCE_GROUP \
                    --name "$VM_NAME" \
                    --command-id RunShellScript \
                    --scripts "@front.sh" \
                    --parameters "$SERVER_IP" "$SERVER_PORT" "$SERVICE_PORT"
                ;;

        nginx)
                echo Setting up nginx

                SERVER_ADDRESS=$(jq -r '.backend_address' <<<$SCRIPT)
                readarray -t BACKEND_PORTS < <(jq -c '.backend_ports[]' <<<$SCRIPT)

                az vm run-command invoke \
                    --resource-group $RESOURCE_GROUP \
                    --name $VM_NAME \
                    --command-id RunShellScript \
                    --scripts '@nginx.sh' \
                    --parameters "$SERVICE_PORT" "$SERVER_ADDRESS" "${BACKEND_PORTS[@]}"
                ;;

        backend)
                echo Setting up backend

                DATABASE_ADDRESS=$(jq -r '.database_ip' <<<$SCRIPT)
                DATABASE_PORT=$(jq -r '.database_port' <<<$SCRIPT)
                DATABASE_USER=$(jq -r '.database_user' <<<$SCRIPT)
                DATABASE_PASSWORD=$(jq -r '.database_password' <<<$SCRIPT)

                az vm run-command invoke \
                    --resource-group $RESOURCE_GROUP \
                    --name $VM_NAME \
                    --command-id RunShellScript \
                    --scripts "@back.sh" \
                    --parameters "$SERVICE_PORT" "$DATABASE_ADDRESS" "$DATABASE_PORT" "$DATABASE_USER" "$DATABASE_PASSWORD"
                ;;

        database)
                echo Setting up database

                DATABASE_USER=$(jq -r '.user' <<<$SCRIPT)
                DATABASE_PASSWORD=$(jq -r '.password' <<<$SCRIPT)

                az vm run-command invoke \
                    --resource-group $RESOURCE_GROUP \
                    --name $VM_NAME \
                    --command-id RunShellScript \
                    --scripts "@db.sh" \
                    --parameters "$SERVICE_PORT" "$DATABASE_USER" "$DATABASE_PASSWORD"
                ;;

        database-master)
                echo Setting up database master

                DATABASE_USER=$(jq -r '.user' <<<$SCRIPT)
                DATABASE_PASSWORD=$(jq -r '.password' <<<$SCRIPT)

                az vm run-command invoke \
                    --resource-group $RESOURCE_GROUP \
                    --name $VM_NAME \
                    --command-id RunShellScript \
                    --scripts "@db_master.sh" \
                    --parameters "$SERVICE_PORT" "$DATABASE_USER" "$DATABASE_PASSWORD"
                ;;

        database-slave)
            echo Setting up database slave

            DATABASE_USER=$(jq -r '.user' <<< $SCRIPT)
            DATABASE_PASSWORD=$(jq -r '.password' <<< $SCRIPT)
            MASTER_ADDRESS=$(jq -r '.master_address' <<< $SCRIPT)
            MASTER_PORT=$(jq -r '.master_port' <<< $SCRIPT)

            az vm run-command invoke \
                --resource-group $RESOURCE_GROUP \
                --name $VM_NAME \
                --command-id RunShellScript \
                --scripts "@db_slave.sh" \
                --parameters "$SERVICE_PORT" "$DATABASE_USER" "$DATABASE_PASSWORD" "$MASTER_ADDRESS" "$MASTER_PORT"
            ;;


        *)
            echo 1>&2 "Unknown script type!"
            exit 1
            ;;
    esac
done


for PUBLIC_IP in "${PUBLIC_IPS[@]}"; do
    echo $PUBLIC_IP

    PUBLIC_IP_NAME=$(jq -r '.name' <<<$PUBLIC_IP)

    az network public-ip show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$PUBLIC_IP_NAME" \
        --query "ipAddress" \
        --output tsv
done

az logout