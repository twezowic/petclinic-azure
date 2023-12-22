git clone https://github.com/spring-petclinic/spring-petclinic-cloud

cd spring-petclinic-cloud/

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