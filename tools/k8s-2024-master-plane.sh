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
#          Tools Install Kubernetes and Docker on Worker Nodes        #
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
#                      Installing Docker Runtime                      #
#######################################################################
${BOLD}"
sudo apt update
sudo apt install docker.io -y
sudo systemctl enable docker
sudo systemctl start docker


echo -e "\n"
echo -e "${GREEN}
#######################################################################
#               Installing Kubeadm, Kubelet, and Kubectl              #
#######################################################################
${BOLD}"
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/kubernetes.gpg] http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list
sudo apt update
sudo apt install kubeadm kubelet kubectl -y
sudo apt-mark hold kubeadm kubelet kubectl


echo -e "\n"
echo -e "${GREEN}
#######################################################################
#                         Deploying Kubernetes                        #
#######################################################################
${BOLD}"
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system


echo -e "\n"
echo -e "${GREEN}
#######################################################################
#                          Setting Up Hostname                        #
#######################################################################
${BOLD}"
sudo hostnamectl set-hostname master-plane
sudo tee /etc/hosts <<EOF
10.128.0.2 master-plane
10.128.0.3 worker-node-01
10.128.0.4 worker-node-02
EOF


echo -e "\n"
echo -e "${GREEN}
#######################################################################
#                       Setting Up Kubelet Daemon                     #
#######################################################################
${BOLD}"
sudo tee /etc/default/kubelet <<EOF
KUBELET_EXTRA_ARGS="--cgroup-driver=cgroupfs"
EOF
sudo systemctl daemon-reload
sudo systemctl restart kubelet


echo -e "\n"
echo -e "${GREEN}
#######################################################################
#                       Setting Up Docker Daemon                      #
#######################################################################
${BOLD}"
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
sudo systemctl daemon-reload
sudo systemctl restart docker


echo -e "\n"
echo -e "${GREEN}
#######################################################################
#                      Setting Up Kubeadm Daemon                      #
#######################################################################
${BOLD}"
sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf <<EOF
Environment="KUBELET_EXTRA_ARGS=--fail-swap-on=false"
EOF
sudo systemctl daemon-reload
sudo systemctl restart kubelet
sudo kubeadm reset --force
sudo systemctl start kubelet
sudo kubeadm init --control-plane-endpoint=master-plane --upload-certs --ignore-preflight-errors=All


echo -e "\n"
echo -e "${GREEN}
#######################################################################
#                        Setting Up Kube Config                       #
#######################################################################
${BOLD}"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


echo -e "\n"
echo -e "${GREEN}
#######################################################################
#                          Install CNI Flannel                        #
#######################################################################
${BOLD}"
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

sleep 10
fi
