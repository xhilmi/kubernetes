# Delete all
cd ~/repository/kube-prometheus
kubectl delete --ignore-not-found=true -f manifests/ -f manifests/setup