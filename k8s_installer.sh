#!/bin/bash
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
echo -e "\n"
echo -e "${PURPLE}##### Tools Install Kubernetes and CRI Docker #####${BOLD}"
echo -e "\n"
echo -e "${YELLOW}# Reference:${BOLD}"
echo -e "${YELLOW}# https://computingforgeeks.com/install-kubernetes-cluster-ubuntu-jammy${BOLD}"
echo -e "${YELLOW}# https://computingforgeeks.com/install-mirantis-cri-dockerd-as-docker-engine-shim-for-kubernetes${BOLD}"

function menu {
    echo -e "\n"
    echo -e "${GREEN}Choose:${BOLD}"
    echo "1) Master Node"
    echo "2) Cluster Node"
    echo "3) Reset Node"
    echo "4) Exit"
    echo -n "Enter your choice (1-4): "
}

function common_install {
    echo -e "\n"
    echo -e "${YELLOW}# Common steps for master node and cluster node${BOLD}"
    
    # ... All the common steps for master and cluster node
    while true;
        do
        read -p "Enter the hostname of this node: " hostnamectl
        echo "Hostname: $hostnamectl"
        read -p "Is this correct? (y/n) " yn
        case $yn in
            [Yy]* ) 
                sudo sh -c "echo \"$internalip $hostnamectl\" >> /etc/hosts"
                break;;
            [Nn]* ) ;;
            * ) echo "Please answer yes or no.";;
        esac
        echo "Please answer yes or no to add again?"
    done

    echo -e "\n"
    echo -e "${YELLOW}# Updating packages...${BOLD}"
    sudo apt update

    echo -e "\n"
    echo -e "${YELLOW}# Installing required packages...${BOLD}"
    sudo apt install curl apt-transport-https -y
    curl -fsSL  https://packages.cloud.google.com/apt/doc/apt-key.gpg|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/k8s.gpg
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    
    echo -e "\n"
    echo -e "${YELLOW}# Updating packages...${BOLD}"
    sudo apt update

    echo -e "\n"
    echo -e "${YELLOW}# Installing kubelet, kubeadm, and kubectl...${BOLD}"
    sudo apt install wget curl vim git kubelet kubeadm kubectl -y
    sudo apt-mark hold kubelet kubeadm kubectl
    kubectl version --client && kubeadm version

    echo -e "\n"
    echo -e "${YELLOW}# Disabling swap, setup kernel modules, and reload sysctl..${BOLD}"
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
    echo -e "${YELLOW}# Updating packages...${BOLD}"
    sudo apt update

    echo -e "\n"
    echo -e "${YELLOW}# Installing required packages...${BOLD}"
    sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    yes | sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    
    echo -e "\n"
    echo -e "${YELLOW}# Updating packages...${BOLD}"
    sudo apt update

    echo -e "\n"
    echo -e "${YELLOW}# Installing CRI Docker Community Edition...${BOLD}"
    sudo apt install -y containerd.io docker-ce docker-ce-cli
    sudo mkdir -p /etc/systemd/system/docker.service.d

    echo -e "\n"
    echo -e "${YELLOW}# Enabling service docker...${BOLD}"
    sudo systemctl daemon-reload 
    sudo systemctl restart docker
    sudo systemctl enable docker
    sudo systemctl status docker

    echo -e "\n"
    echo -e "${YELLOW}# Updating packages...${BOLD}"
    sudo apt update

    echo -e "\n"
    echo -e "${YELLOW}# Installing required packages...${BOLD}"
    sudo apt install git wget curl -y
    sudo apt install curl gnupg2 software-properties-common apt-transport-https ca-certificates -y
    
    echo -e "\n"
    echo -e "${YELLOW}# Installing Golang...${BOLD}"
    wget https://storage.googleapis.com/golang/getgo/installer_linux
    chmod +x ./installer_linux
    ./installer_linux
    source ~/.bash_profile
    go version

    echo -e "\n"
    echo -e "${YELLOW}# Installing cri-dockerd...${BOLD}"
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

    echo -e "\n"
    echo -e "${YELLOW}# Enabling service cri-dockerd...${BOLD}"
    sudo systemctl daemon-reload
    sudo systemctl enable cri-docker.service
    sudo systemctl enable --now cri-docker.socket
    sudo systemctl status cri-docker.socket

    echo -e "\n"  
    echo -e "${YELLOW}# Checking kernel modules...${BOLD}"
    lsmod | grep br_netfilter

    echo -e "\n"
    echo -e "${YELLOW}# Enabling service kubelet...${BOLD}"
    sudo systemctl enable kubelet

    echo -e "\n"
    echo -e "${YELLOW}# Disabling service ufw...${BOLD}"
    sudo ufw disable
    sudo service ufw stop
}

function master_node {
    common_install

    echo -e "\n"
    echo -e "${PURPLE}##### Only on master node #####${BOLD}"
    sudo kubeadm config images pull --cri-socket unix:///run/cri-dockerd.sock
    read -p "Enter the internal IP address of the master node: " internalip

    echo -e "\n"
    echo -e "${YELLOW}# Run kubeadm init command...${BOLD}"
    sudo kubeadm init \
      --pod-network-cidr=10.244.0.0/16 \
      --cri-socket unix:///run/cri-dockerd.sock  \
      --upload-certs \
      --control-plane-endpoint=$internalip
    
    echo -e "\n"
    echo -e "${YELLOW}# Setting kube config...${BOLD}"
    mkdir -p $HOME/.kube
    sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    kubectl cluster-info
    kubectl get nodes

    echo -e "\n"
    echo -e "${YELLOW}# Setting CNI using Flannel...${BOLD}"
    kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

    echo -e "\n"
    echo -e "${YELLOW}# Print kubernetes token...${BOLD}"
    kubeadm token create --print-join-command
}

function cluster_node {
    common_install
    echo -e "\n"
    echo -e "${PURPLE}##### Only on cluster node #####${BOLD}"
    read -p "Enter the internal IP address of the cluster node: " internalip
    read -p "Enter the token: " token
    read -p "Enter the discovery-token-ca-cert-hash: " shatoken
    
    echo -e "\n"
    echo -e "${YELLOW}# Run kubeadm join command...${BOLD}"
    sudo kubeadm join $internalip:6443 --token $token \
        --discovery-token-ca-cert-hash sha256:$shatoken \
        --cri-socket unix:///run/cri-dockerd.sock
}

function reset_node {
    echo -e "\n"
    echo -e "${PURPLE}##### Only when wanna reset node #####${BOLD}"

    echo -e "\n"
    echo -e "${YELLOW}# Run kubeadm reset command...${BOLD}"
    sudo kubeadm reset --cri-socket=unix:///var/run/cri-dockerd.sock && sudo rm -rf /etc/cni/net.d && sudo rm -f $HOME/.kube/config
}

while true; do
    menu
    read choice
    case $choice in
        1)
            master_node
            break
            ;;
        2)
            cluster_node
            break
            ;;
        3)
            reset_node
            break
            ;;
        4)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please choose a valid option (1-4)."
            ;;
    esac
done
   


