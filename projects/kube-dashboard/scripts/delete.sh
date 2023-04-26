# Uniinstall Kubernetes Dashboard
# https://computingforgeeks.com/how-to-install-kubernetes-dashboard-with-nodeport/
cd ~/repository
kubectl delete --ignore-not-found=true -f kube-dashboard/
cd ..
rm -rf kube-dashboard/

# cd ~/repository/kube-dashboard
# kubectl delete -f kubernetes-dashboard.yaml
# kubectl delete -f recommended.yaml
# kubectl delete -f nodeport_dashboard_patch.yaml
# kubectl delete -f admin-sa.yaml
# kubectl delete -f admin-rbac.yaml
# kubectl delete -f k8sadmin-secret.yaml