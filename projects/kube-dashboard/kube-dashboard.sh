# Install Kubernetes Dashboard
# https://computingforgeeks.com/how-to-install-kubernetes-dashboard-with-nodeport/

# Ubuntu / Debian
mkdir kube-dashboard
cd kube-dashboard
sudo apt update
sudo apt install wget curl
VER=$(curl -s https://api.github.com/repos/kubernetes/dashboard/releases/latest|grep tag_name|cut -d '"' -f 4)
echo $VER
wget https://raw.githubusercontent.com/kubernetes/dashboard/$VER/aio/deploy/recommended.yaml -O kubernetes-dashboard.yaml
kubectl apply -f kubernetes-dashboard.yaml
kubectl get svc -n kubernetes-dashboard

# Patch Expose LoadBalancer
kubectl -n kubernetes-dashboard patch svc kubernetes-dashboard -p '{"spec": {"type": "LoadBalancer"}}'
kubectl -n kubernetes-dashboard get services

# Patch Expose NodePort
kubectl --namespace kubernetes-dashboard patch svc kubernetes-dashboard -p '{"spec": {"type": "NodePort"}}'
kubectl -n kubernetes-dashboard get services
kubectl get svc -n kubernetes-dashboard kubernetes-dashboard -o yaml
sudo tee nodeport_dashboard_patch.yaml <<EOF
spec:
  ports:
  - nodePort: 32000
    port: 443
    protocol: TCP
    targetPort: 8443
EOF
kubectl -n kubernetes-dashboard patch svc kubernetes-dashboard --patch "$(cat nodeport_dashboard_patch.yaml)"
kubectl get deployments -n kubernetes-dashboard
kubectl get pods -n kubernetes-dashboard
kubectl get service -n kubernetes-dashboard  

# Create Admin Kubernetes Dashboard
# https://computingforgeeks.com/create-admin-user-to-access-kubernetes-dashboard/
sudo tee admin-sa.yml <<EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: k8sadmin
  namespace: kube-system
EOF
kubectl apply -f admin-sa.yml
sudo tee admin-rbac.yml <<EOF
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  namespace: kube-system
  name: k8sadmin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: k8sadmin
    namespace: kube-system
EOF
kubectl apply -f admin-rbac.yml
kubectl create token k8sadmin -n kube-system

# sample output
# copy secret token

sudo tee k8sadmin-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: k8sadmin-token
  annotations:
    kubernetes.io/service-account.name: k8sadmin
type: kubernetes.io/service-account-token
EOF
kubectl apply -f k8sadmin-secret.yaml
export NAMESPACE="kube-system"
export K8S_USER="k8sadmin"
kubectl get services -A | grep dashboard