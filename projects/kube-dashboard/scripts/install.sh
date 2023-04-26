# Install Kubernetes Dashboard
# https://computingforgeeks.com/how-to-install-kubernetes-dashboard-with-nodeport/

# Ubuntu / Debian
cd ~
mkdir repository && cd repository
mkdir kube-dashboard && cd kube-dashboard
sudo apt update
sudo apt install wget curl
VER=$(curl -s https://api.github.com/repos/kubernetes/dashboard/releases/latest|grep tag_name|cut -d '"' -f 4)
echo $VER
wget https://raw.githubusercontent.com/kubernetes/dashboard/$VER/aio/deploy/recommended.yaml -O kubernetes-dashboard.yaml
kubectl apply -f kubernetes-dashboard.yaml
kubectl get svc -n kubernetes-dashboard

# Patch Expose NodePort
kubectl -n kubernetes-dashboard patch svc kubernetes-dashboard -p '{"spec": {"type": "NodePort"}}'
kubectl -n kubernetes-dashboard get svc
kubectl get svc -n kubernetes-dashboard kubernetes-dashboard -o yaml
sudo tee nodeport_dashboard_patch.yaml <<EOF
spec:
  ports:
  - nodePort: 30000
    port: 443
    protocol: TCP
    targetPort: 8443
EOF
kubectl -n kubernetes-dashboard patch svc kubernetes-dashboard --patch "$(cat nodeport_dashboard_patch.yaml)"
kubectl get deploy -n kubernetes-dashboard
kubectl get pods -n kubernetes-dashboard
kubectl get svc -n kubernetes-dashboard  

# Patch Expose LoadBalancer
kubectl -n kubernetes-dashboard patch svc kubernetes-dashboard -p '{"spec": {"type": "LoadBalancer"}}'
kubectl -n kubernetes-dashboard get svc

# Create Admin Kubernetes Dashboard
# https://computingforgeeks.com/create-admin-user-to-access-kubernetes-dashboard/
sudo tee admin-sa.yaml <<EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: k8sadmin
  namespace: kube-system
EOF
kubectl apply -f admin-sa.yaml
sudo tee admin-rbac.yaml <<EOF
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
kubectl apply -f admin-rbac.yaml
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
kubectl get svc -A | grep dashboard
kubectl create token k8sadmin -n kube-system > k8sadmin.token
cat k8sadmin.token