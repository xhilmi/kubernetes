#!/bin/bash

# Prompt the user for their choice
read -p "Do you want to (I)nstall, (D)elete, or (E)xit the Kubernetes Dashboard? " choice

# Depending on the user's choice, either install, delete or exit
if [[ "$choice" == [Ii] ]]; then

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
  else
    echo "Invalid input. Exiting."
    exit 1
  fi

  # Verify that the Kubernetes Dashboard has been successfully installed and is accessible
  kubectl get deployments -n kubernetes-dashboard
  kubectl get pods -n kubernetes-dashboard
  kubectl get service -n kubernetes-dashboard

elif [[ "$choice" == [Dd] ]]; then
  # Delete the Kubernetes Dashboard
  kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.3.1/aio/deploy/recommended.yaml
  kubectl delete -f admin-user.yaml
  kubectl delete -f kubernetes-dashboard.yaml
  kubectl delete -f recommended.yaml
  kubectl delete -f nodeport_dashboard_patch.yaml
  kubectl delete -f admin-sa.yaml
  kubectl delete -f admin-rbac.yaml
  kubectl delete -f k8sadmin-secret.yaml


elif [[ "$choice" == [Ee] ]]; then
  # Exit
  echo "Exiting."
  exit 0

else
  # Invalid input
  echo "Invalid input. Exiting."
  exit 1

fi