#!/bin/bash
# install kubernetes full version on linux ubuntu

# For docker : www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-22-04
# For Cri-dockered : github.com/Mirantis/cri-dockerd
# For kubernetes : kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

### DISABLE SWAP ###
sudo swapoff -a;

### COPY INTO /etc/modules-load.d/k8s.conf ### 
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

### ENABLE BRIDGED TRAFFIC ###
lsmod | grep br_netfilter;
sudo modprobe overlay;
sudo modprobe br_netfilter;

### COPY INTO /etc/sysctl.d/k8s.conf ###
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

### APPLY ###
sudo sysctl --system

### UNINSTALL OLDER VERSIONS ###
sudo apt-get remove docker docker-engine docker.io containerd runc;

### FETCH DOCKER RUN AS NON ROOT ###
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
apt-cache policy docker-ce -y
sudo apt install docker-ce -y
sudo systemctl status docker
sudo systemctl enable docker

### BUILD CRI-DOCKER RUN AS ROOT ###
sudo su -
git clone https://github.com/Mirantis/cri-dockerd.git

### INSTALL GOLANG ###
wget https://storage.googleapis.com/golang/getgo/installer_linux
chmod +x ./installer_linux
./installer_linux
source ~/.bash_profile

### BUILD GOLANG ###
cd cri-dockerd
mkdir bin
go build -x -o bin/cri-dockerd
mkdir -p /usr/local/bin

### INSTALL CRI-DOCKER ###
install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd
cp -a packaging/systemd/* /etc/systemd/system
sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
systemctl daemon-reload
systemctl enable cri-docker.service
systemctl enable --now cri-docker.socket
systemctl start cri-docker.service
systemctl status cri-docker.service

### DEFINE USER FOR DOCKER ###
sudo usermod -aG docker root
sudo usermod -aG docker ubuntu
sudo usermod -aG docker agrisoye
sudo usermod -aG docker ${USER}
groups
sudo systemctl restart cri-docker.service
sudo systemctl restart docker

### INSTALL MINIKUBE ###
cd
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube
minikube start

### INSTALL KUBERNETES ###
cd
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo apt install net-tools -y;
sudo netstat -tulpn | grep etcd;
sudo netstat -tulpn | grep 6443;
sudo netstat -tulpn | grep kubelet
sudo netstat -tulpn | grep kube-apiser
sudo netstat -tulpn | grep kube-control
sudo netstat -tulpn | grep kube-sche
sudo netstat -tulpn | grep kube-proxy
sudo netstat -tulpn | grep kube

### JOIN NODES - RUN ON WORKER NODE ###
# below is example
# kubeadm join 10.182.0.32:6443 \
# --token uelw3s.vwb3qjafcqj0hgm1 \
# --discovery-token-ca-cert-hash sha256:3afb9314c97626a2f97dab9aa901675acbc7365b895a93e02de83cd0ed99b434 \
# --cri-socket=unix:///var/run/cri-dockerd.sock
read -p "Enter master node ip: " ip
read -p "Enter master node token: " token
read -p "Enter master node sha256: " sha256
kubeadm join $ip:6443 --token $token --discovery-token-ca-cert-hash $sha256 --cri-socket=unix:///var/run/cri-dockerd.sock
