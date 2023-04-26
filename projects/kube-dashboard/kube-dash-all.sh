#!/bin/bash

# Prompt the user for their choice
read -p "Do you want to (I)nstall, (D)elete, or (E)xit the Kubernetes Dashboard? " choice

# Depending on the user's choice, either install, delete or exit
if [[ "$choice" == [Ii] ]]; then
  # Install the Kubernetes Dashboard
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.3.1/aio/deploy/recommended.yaml

  # Create an admin user for the Kubernetes Dashboard
  kubectl apply -f admin-user.yaml

  # Prompt the user for their choice of how to expose the Kubernetes Dashboard service
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

elif [[ "$choice" == [Dd] ]]; then
  # Delete the Kubernetes Dashboard
  kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.3.1/aio/deploy/recommended.yaml
  kubectl delete -f admin-user.yaml

  # Prompt the user for their choice of how the service was exposed
  read -p "Was the Kubernetes Dashboard service exposed using (L)oadBalancer or (N)odePort? " choice

  if [[ "$choice" == [Ll] ]]; then
    kubectl delete service kubernetes-dashboard -n kubernetes-dashboard
  elif [[ "$choice" == [Nn] ]]; then
    kubectl delete -f nodeport_dashboard_patch.yaml
    kubectl --namespace kubernetes-dashboard patch svc kubernetes-dashboard -p '{"spec": {"type": "ClusterIP"}}'
  else
    echo "Invalid input. Exiting."
    exit 1
  fi

  # Verify that the Kubernetes Dashboard has been successfully deleted
  kubectl get deployments -n kubernetes-dashboard || true
  kubectl get pods -n kubernetes-dashboard || true
  kubectl get service -n kubernetes-dashboard || true

elif [[ "$choice" == [Ee] ]]; then
  # Exit
  echo "Exiting."
  exit 0

else
  # Invalid input
  echo "Invalid input. Exiting."
  exit 1

fi