#!/bin/bash

# Function to install Kubernetes Dashboard
function install_dashboard() {
  # Install the Kubernetes Dashboard
  # https://computingforgeeks.com/how-to-install-kubernetes-dashboard-with-nodeport/

  # Ubuntu / Debian
  mkdir kube-dashboard
  cd kube-dashboard
  sudo apt update
  sudo apt install wget curl git tree -y
  VER=$(curl -s https://api.github.com/repos/kubernetes/dashboard/releases/latest|grep tag_name|cut -d '"' -f 4)
  echo $VER
  wget https://raw.githubusercontent.com/kubernetes/dashboard/$VER/aio/deploy/recommended.yaml -O kubernetes-dashboard.yaml
  kubectl apply -f kubernetes-dashboard.yaml
  kubectl get svc -n kubernetes-dashboard

  # Prompt the user for their choice of how to expose the Kubernetes Dashboard service
  read -p "How do you want to expose the Kubernetes Dashboard service? Choose (L)oadBalancer or (N)odePort: " choice

  # LoadBalancer  
  if [[ "$choice" == [Ll] ]]; then
    kubectl -n kubernetes-dashboard patch svc kubernetes-dashboard -p '{"spec": {"type": "LoadBalancer"}}'
    kubectl -n kubernetes-dashboard get services
    # Function add_user
    add_user

  # NodePort
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
    # Function add_user
    add_user
  else
    echo "Invalid input. Exiting."
    exit 1
  fi

  # Verify that the Kubernetes Dashboard has been successfully installed and is accessible
  kubectl get deployments -n kubernetes-dashboard
  kubectl get pods -n kubernetes-dashboard
  kubectl get service -n kubernetes-dashboard
}

# Function add_user
function add_user() {
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
}


function uninstall_dashboard() {
# Delete the Kubernetes Dashboard
    kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.3.1/aio/deploy/recommended.yaml
    kubectl delete -f admin-user.yaml
    kubectl delete -f kubernetes-dashboard.yaml
    kubectl delete -f recommended.yaml
    kubectl delete -f nodeport_dashboard_patch.yaml
    kubectl delete -f admin-sa.yaml
    kubectl delete -f admin-rbac.yaml
    kubectl delete -f k8sadmin-secret.yaml
}

# Case statement to handle user choice
case "$choice" in
  [Ii]) # Install Kubernetes Dashboard
    install_dashboard
    ;;
  [Dd]) # Delete Kubernetes Dashboard
    uninstall_dashboard
    ;;
  [Ee]) # Exit
    echo "Exiting."
    sleep 10
    exit 0
    ;;
  *) # Invalid input
    echo "Invalid input. Exiting."
    sleep 10
    exit 1
    ;;
esac
