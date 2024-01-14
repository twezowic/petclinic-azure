az group create --name wus_3 --location westeurope

az aks delete --resource-group wus_3 --name petclinicCluster --yes
az aks create --resource-group wus_3 --name petclinicCluster --enable-managed-identity --node-count 2 --generate-ssh-keys

az aks update --enable-azure-monitor-metrics -n petclinicCluster -g wus_3
az aks enable-addons -a monitoring -n petclinicCluster -g wus_3

az aks get-credentials \
    --resource-group wus_3 \
    --name petclinicCluster

kubectl get nodes