!/bin/bash
# (c) 2023 Hilmi

# Color
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
ORANGE='\033[0;33m'
BOLD='\033[1m'
ITALIC='\033[3m'

# Clearing prompt after running this script.
clear
echo -e "${GREEN}
#######################################################################
#          Tools Install Kubernetes and Docker on Master Nodes        #
#######################################################################
${BOLD}"
echo -e "\n"
echo -e "${BLUE}# Reference:${BOLD}"
echo -e "${BLUE}# https://computingforgeeks.com/install-kubernetes-cluster-ubuntu-jammy/${BOLD}"
echo -e "${BLUE}# https://computingforgeeks.com/install-mirantis-cri-dockerd-as-docker-engine-shim-for-kubernetes/${BOLD}"

# Function to check if a package is installed
function is_installed {
  dpkg -s "$1" >/dev/null 2>&1
}

# Disable Ctrl+C command
trap "echo 'Please wait until the installation completes.' >&2" SIGINT

# Check if Kubernetes and Docker packages are already installed
if is_installed kubelet && is_installed kubeadm && is_installed kubectl \
&& is_installed containerd.io && is_installed docker-ce && is_installed docker-ce-cli; then
echo -e "${GREEN}
#######################################################################
#         Kubernetes and Docker packages are already installed        #
#######################################################################
${BOLD}"
else

# If the packages are not installed, continue with installation
echo -e "\n"
echo -e "${GREEN}
#######################################################################
#                Installing Kubelet Kubeadm and Kubectl               #
#######################################################################
${BOLD}"
sudo apt update
sudo apt install -y vim git wget curl gnupg2 software-properties-common apt-transport-https ca-certificates
curl -fsSL  https://packages.cloud.google.com/apt/doc/apt-key.gpg|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/k8s.gpg
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt -y install kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
kubectl version --client && kubeadm version
sudo swapoff -a 
free -h
sudo modprobe overlay
sudo modprobe br_netfilter
sudo tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo tee /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
sudo sysctl --system

echo -e "\n"
echo -e "${GREEN}
#######################################################################
#                      Installing Docker Runtime                      #
#######################################################################
${BOLD}"
sudo apt update
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
yes | sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y containerd.io docker-ce docker-ce-cli
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo systemctl daemon-reload 
sudo systemctl restart docker
sudo systemctl enable docker

echo -e "\n"
echo -e "${GREEN}
#######################################################################
#                   Installing Golang and CRI-Docker                  #
#######################################################################
${BOLD}"
sudo apt update
wget https://storage.googleapis.com/golang/getgo/installer_linux
chmod +x ./installer_linux
./installer_linux
source ~/.bash_profile
go version
rm -rf cri-dockerd
git clone https://github.com/Mirantis/cri-dockerd.git
cd cri-dockerd
mkdir bin
sudo chmod 777 bin
go build -x -o bin/cri-dockerd
sudo mkdir -p /usr/local/bin
sudo install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd
sudo cp -a packaging/systemd/* /etc/systemd/system
sudo sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
sudo systemctl daemon-reload
sudo systemctl enable cri-docker.service
sudo systemctl enable --now cri-docker.socket
lsmod | grep br_netfilter
sudo systemctl enable kubelet
sudo ufw disable
sudo service ufw stop

echo -e "\n"
echo -e "${GREEN}
#######################################################################
#                        Kubeadm Join Cluster                         #
#######################################################################
${BOLD}"
echo -e "${GREEN}# Run this command below to join into spesify cluster ${BOLD}"
echo -e "\n"
echo -e "${BLUE}
sudo kubeadm join (^Address):6443 --token (^Token) --discovery-token-ca-cert-hash (^sha256) \
	 --cri-socket unix:///run/cri-dockerd.sock ${BOLD}"

sleep 10
fi