#!/bin/bash

echo "Enter the name of the Azure Resource Group you want to delete:"
read resourceGroupName

# az login

echo "Are you sure you want to delete the resource group $resourceGroupName? This action cannot be undone. (y/n)"
read confirmation

if [ "$confirmation" == "y" ]; then
  az group delete --name $resourceGroupName --yes --no-wait
  echo "Resource group $resourceGroupName is being deleted."
else
  echo "Deletion cancelled."
fi
