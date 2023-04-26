
#!/bin/bash

# Create a directory to store the installation files and navigate to it
mkdir kube-dashboard
cd kube-dashboard

# Update the system and install necessary packages
sudo apt update
sudo apt install wget curl git tree -y

# Fetch the latest release version of Kubernetes Dashboard and extract its tag_name
VER=$(curl -s https://api.github.com/repos/kubernetes/dashboard/releases/latest|grep tag_name|cut -d '"' -f 4)

# Download the recommended YAML file for deploying the dashboard and apply it to the cluster using kubectl
echo $VER
wget https://raw.githubusercontent.com/kubernetes/dashboard/$VER/aio/deploy/recommended.yaml -O kubernetes-dashboard.yaml
kubectl apply -f kubernetes-dashboard.yaml

# Depending on the user's choice, either expose the service using a LoadBalancer or a NodePort by patching the service accordingly
read -p "How do you want to expose the Kubernetes Dashboard service? Choose (L)oadBalancer or (N)odePort: " choice

if [[ "$choice" == [Ll] ]]; then
  kubectl -n kubernetes-dashboard patch svc kubernetes-dashboard -p '{"spec": {"type": "LoadBalancer"}}'
  kubectl -n kubernetes-dashboard get services
elif [[ "$choice" == [Nn] ]]; then
  kubectl --namespace kubernetes-dashboard patch svc kubernetes-dashboard -p '{"spec": {"type": "NodePort"}}'
  kubectl -n kubernetes-dashboard get services
  kubectl get svc -n kubernetes-dashboard kubernetes-dashboard -o yaml > nodeport_dashboard_patch.yaml
  echo "spec:" >> nodeport_dashboard_patch.yaml
  echo "  ports:" >> nodeport_dashboard_patch.yaml
  echo "  - nodePort: 32000" >> nodeport_dashboard_patch.yaml
  echo "    port: 443" >> nodeport_dashboard_patch.yaml
  echo "    protocol: TCP" >> nodeport_dashboard_patch.yaml
  echo "    targetPort: 8443" >> nodeport_dashboard_patch.yaml
  kubectl -n kubernetes-dashboard patch svc kubernetes-dashboard --patch "$(cat nodeport_dashboard_patch.yaml)"
else
  echo "Invalid input. Exiting."
  exit 1
fi

# Verify that the Kubernetes Dashboard has been successfully installed and is accessible
kubectl get deployments -n kubernetes-dashboard
kubectl get pods -n kubernetes-dashboard
kubectl get service -n kubernetes-dashboard 

# Prompt to create an admin user for accessing the Kubernetes Dashboard
read -p "Do you want to create an admin user for accessing the Kubernetes Dashboard? (Y/N) " create_admin

if [[ "$create_admin" == [Yy] ]]; then
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
  kubectl create token k8sadmin -n kube-system > k8sadmin.token
  cat k8sadmin.token
fi
