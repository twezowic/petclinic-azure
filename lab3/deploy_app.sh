git clone https://github.com/spring-petclinic/spring-petclinic-cloud

cd spring-petclinic-cloud/
sed -i '/- wavefront/d'  manifest.yml

cd k8s/

sed -i '/- name: MANAGEMENT_METRICS_EXPORT_WAVEFRONT_URI/d' api-gateway-deployment.yaml
sed -i '/value: proxy:\/\/wavefront-proxy.spring-petclinic.svc.cluster.local:2878/d' api-gateway-deployment.yaml
sed -i 's/replicas: 1/replicas: 2/' api-gateway-deployment.yaml
sed -i 's/            cpu: 2000m/            cpu: 0.5/' api-gateway-deployment.yaml

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
sed -i '/^ *wavefront:/,/^[ ]*freemium-account:/d' 02-config-map.yaml
sed -i '/^ *wavefront:/,/^[ ]*enabled: true/d' 02-config-map.yaml

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

# to jeszcze nie wywalone
# spring-petclinic-visits-service/.factorypath
# spring-petclinic-vets-service/pom.xml
# spring-petclinic-customers-service/pom.xml
# spring-petclinic-visits-service/manifest.yml
# spring-petclinic-customers-service/manifest.yml
# spring-petclinic-visits-service/pom.xml
# spring-petclinic-vets-service/.factorypath
# spring-petclinic-api-gateway/manifest.yml
# spring-petclinic-api-gateway/src/main/resources/bootstrap.yml
# spring-petclinic-customers-service/.factorypath
# spring-petclinic-api-gateway/pom.xml
# spring-petclinic-api-gateway/.factorypath
# spring-petclinic-vets-service/manifest.yml