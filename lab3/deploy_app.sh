git clone https://github.com/spring-petclinic/spring-petclinic-cloud

cd spring-petclinic-cloud/
sed -i '/- wavefront/d'  manifest.yml

cd k8s/

sed -i 's/            cpu: 2000m/            cpu: 0.5/' api-gateway-deployment.yaml
sed -i 's/replicas: 1/replicas: 2/' customers-service-deployment.yaml
sed -i 's/replicas: 1/replicas: 2/' vets-service-deployment.yaml
sed -i 's/replicas: 1/replicas: 2/' visits-service-deployment.yaml


cd init-services/
sed -i '/wavefront:/ { n; s/enabled: true/enabled: false/; }' 02-config-map.yaml

cd ..
cd ..

kubectl apply -f k8s/init-namespace
kubectl apply -f k8s/init-services

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install vets-db-mysql bitnami/mysql --namespace spring-petclinic --version 9.4.6 --set auth.database=service_instance_db
helm install visits-db-mysql bitnami/mysql --namespace spring-petclinic  --version 9.4.6 --set auth.database=service_instance_db
helm install customers-db-mysql bitnami/mysql --namespace spring-petclinic  --version 9.4.6 --set auth.database=service_instance_db


export REPOSITORY_PREFIX=springcommunity

./scripts/deployToKubernetes.sh

kubectl get svc -n spring-petclinic
kubectl get pods -n spring-petclinic