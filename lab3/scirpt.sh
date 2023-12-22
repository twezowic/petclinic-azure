az login

# sudo az aks install-cli

az group create --name wus_3 --location westeurope

az aks delete --resource-group wus_3 --name petclinicCluster --yes
az aks create --resource-group wus_3 --name petclinicCluster --enable-managed-identity --node-count 2 --generate-ssh-keys

az aks get-credentials \
    --resource-group wus_3 \
    --name petclinicCluster

kubectl get nodes


