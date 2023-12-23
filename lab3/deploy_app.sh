git clone https://github.com/spring-petclinic/spring-petclinic-cloud

cd spring-petclinic-cloud/
sed -i '/- wavefront/d'  manifest.yml

cd k8s/

sed -i '/- name: MANAGEMENT_METRICS_EXPORT_WAVEFRONT_URI/d' api-gateway-deployment.yaml
sed -i '/value: proxy:\/\/wavefront-proxy.spring-petclinic.svc.cluster.local:2878/d' api-gateway-deployment.yaml
sed -i 's/replicas: 1/replicas: 2/' api-gateway-deployment.yaml

sed -i '/- name: MANAGEMENT_METRICS_EXPORT_WAVEFRONT_URI/d' customers-service-deployment.yaml
sed -i '/value: proxy:\/\/wavefront-proxy.spring-petclinic.svc.cluster.local:2878/d' customers-service-deployment.yaml
sed -i 's/replicas: 1/replicas: 2/' customers-service-deployment.yaml

sed -i '/- name: MANAGEMENT_METRICS_EXPORT_WAVEFRONT_URI/d' vets-service-deployment.yaml
sed -i '/value: proxy:\/\/wavefront-proxy.spring-petclinic.svc.cluster.local:2878/d' vets-service-deployment.yaml
sed -i 's/replicas: 1/replicas: 2/' vets-service-deployment.yaml

sed -i '/- name: MANAGEMENT_METRICS_EXPORT_WAVEFRONT_URI/d' visits-service-deployment.yaml
sed -i '/value: proxy:\/\/wavefront-proxy.spring-petclinic.svc.cluster.local:2878/d' visits-service-deployment.yaml
sed -i 's/replicas: 1/replicas: 2/' visits-service-deployment.yaml

cd init-services/
rm 04-wavefront.yaml
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
# trzeba wywalić wavefront ze wszystkiego bo nie działa
# nie wiem czy to coś naprawi