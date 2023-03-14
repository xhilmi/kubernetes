#!/bin/bash
# install kubernetes full version on linux ubuntu

sudo apt-get update -y;
sudo apt-get install -y apt-transport-https ca-certificates curl;
sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg;
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list;

sudo apt-get update -y;
sudo apt-get install -y kubelet kubeadm kubectl;
sudo apt-mark hold kubelet kubeadm kubectl;

sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --cri-socket=unix:///var/run/cri-dockerd.sock;
mkdir -p $HOME/.kube;
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config;
sudo chown $(id -u):$(id -g) $HOME/.kube/config;

## optional
## export KUBECONFIG=/etc/kubernetes/admin.conf
## Then you can join any number of worker nodes by running the following on each as root:
## kubeadm join 10.182.0.5:6443 --token ovf82b.kx7trjdpri0ir0og --discovery-token-ca-cert-hash sha256:bdfd6617fb8860cd03964a5a7afcb9984b9b104c704cea3a70fb2b3edb35dd52

cd;
curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml -O;
kubectl apply -f calico.yaml;
kubectl get pods -A --watch;

## optional 
## ln -s /home/user/.kube .kube
