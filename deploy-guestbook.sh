#!/bin/bash
sleep 1
echo "Deploying sample guestbook application..."
echo "(This will take about 3-4 minutes.)"
sleep 2

echo "Deploying services..."
sleep 2

kubectl apply -f frontend-service.yaml
sleep 15

kubectl apply -f k8dash.yaml
sleep 15

kubectl apply -f redis-master-service.yaml
sleep 15

kubectl apply -f redis-worker-service.yaml
sleep 15

echo "Deploying statefulsets..."
kubectl apply -f frontend-statefulset.yaml
sleep 15

kubectl apply -f redis-master-statefulset.yaml
sleep 15

kubectl apply -f redis-worker-statefulset.yaml
sleep 15

echo "Configuring dashboard..."
sleep 1
kubectl create serviceaccount kubedash
sleep 2
kubectl create clusterrolebinding kubedash --clusterrole=cluster-admin --serviceaccount=default:kubedash
sleep 2

echo "Starting up the pods..."
frontend_status=""
while [ "$frontend_status" != "Running" ]; do
  frontend_status=$(kubectl get pods frontend-0 --template="{{.status.phase}}")
  sleep 10
done

redis_master_status=""
while [ "$redis_master_status" != "Running" ]; do
  redis_master_status=$(kubectl get pods redis-master-0 --template="{{.status.phase}}")
  sleep 10
done

redis_slave_status=""
while [ "$redis_slave_status" != "Running" ]; do
  redis_slave_status=$(kubectl get pods redis-slave-0 --template="{{.status.phase}}")
  sleep 10
done

sleep 10

external_ip=""
while [ -z $external_ip ]; do
  echo "Waiting for guestbook IP..."
  external_ip=$(kubectl get svc frontend --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
  [ -z "$external_ip" ] && sleep 10
done

k8dash_ip=""
while [ -z $k8dash_ip ]; do
  echo "Waiting for dashboard IP..."
  k8dash_ip=$(kubectl get svc k8dash -n kube-system  --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
  [ -z "$k8dash_ip" ] && sleep 20
done

echo 'Guestbook IP:' && echo $external_ip
echo 'Dashboard IP:' && echo $k8dash_ip
