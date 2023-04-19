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
echo -e "\n"
echo -e "${BLUE}##### Tools Install Kubernetes and CRI Docker #####${BOLD}"
echo -e "${YELLOW}# Reference:${BOLD}"
echo -e "${YELLOW}# https://computingforgeeks.com/install-kubernetes-cluster-ubuntu-jammy${BOLD}"
echo -e "${YELLOW}# https://computingforgeeks.com/install-mirantis-cri-dockerd-as-docker-engine-shim-for-kubernetes${BOLD}"

function menu {
    echo -e "\n"
    echo -e "${GREEN}Choose:${BOLD}"
    echo "1) K8s Install on Master Node"
    echo "2) K8s Install on Cluster Node"
    echo "3) K8s Kubeadm Init Node"
    echo "4) K8s Kubeadm Join Node"
    echo "5) K8s Kubeadm Reset Node"
    echo "6) Exit"
    echo -n "Enter your choice (1-6): "
}

function common_install {
    echo -e "\n"
    echo -e "${BLUE}##### Common steps for master node and cluster node #####${BOLD}"
    
    # ... All the common steps for master and cluster node
    while true; do
        read -p "Enter the hostname of this node: " hostnamectl
        if [ -z "$hostnamectl" ]; then
            echo "Please enter a valid hostname."
            continue
        fi
        echo "Hostname: $hostnamectl"
        read -p "Is this correct? (y/n) " yn
        case $yn in
            [Yy]* )
                sudo sh -c "echo \"$internalip $hostnamectl\" >> /etc/hosts"
                break;;
            [Nn]* ) ;;
            * ) echo "Please answer yes or no.";;
        esac
        read -p "Do you want to add another hostname? (y/n) " yn
        case $yn in
            [Nn]* ) break;;
        esac
    done

    echo -e "\n"
    echo -e "${BLUE}##### Installing Kubernetes #####${BOLD}"

    echo -e "\n"
    echo -e "${YELLOW}# Updating packages...${BOLD}"
    sudo apt update

    echo -e "\n"
    echo -e "${YELLOW}# Installing required packages...${BOLD}"
    sudo apt install curl apt-transport-https -y

    echo -e "\n"
    echo -e "${YELLOW}# Adding kubernetes required packages...${BOLD}"
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --batch --yes --trust-model always --dearmor -o /etc/apt/trusted.gpg.d/k8s.gpg
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    
    echo -e "\n"
    echo -e "${YELLOW}# Updating packages...${BOLD}"
    sudo apt update

    echo -e "\n"
    echo -e "${YELLOW}# Installing kubelet, kubeadm, and kubectl...${BOLD}"
    sudo apt install wget curl vim git kubelet kubeadm kubectl -y

    echo -e "\n"
    echo -e "${YELLOW}# Marking hold to prevent upgrade automatically on kubelet, kubeadm, and kubectl...${BOLD}"
    sudo apt-mark hold kubelet kubeadm kubectl

    echo -e "\n"
    echo -e "${YELLOW}# Checking kubectl and kubeadm version...${BOLD}"
    kubectl version --client && kubeadm version

    echo -e "\n"
    echo -e "${YELLOW}# Disabling swap, setup kernel modules..${BOLD}"
    sudo swapoff -a 
    free -h
    sudo modprobe overlay
    sudo modprobe br_netfilter
    echo -e "overlay\nbr_netfilter" | sudo tee -a /etc/modules-load.d/k8s.conf

    echo -e "\n"
    echo -e "${YELLOW}# Adding k8sconf and daemon..${BOLD}"
    echo -e "net.bridge.bridge-nf-call-ip6tables = 1\nnet.bridge.bridge-nf-call-iptables = 1\nnet.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/kubernetes.conf
    echo -e '{\n  "exec-opts": ["native.cgroupdriver=systemd"],\n  "log-driver": "json-file",\n  "log-opts": {\n    "max-size": "100m"\n  },\n  "storage-driver": "overlay2"\n}' | sudo tee /etc/docker/daemon.json

    echo -e "\n"
    echo -e "${YELLOW}# Reloading sysctl system..${BOLD}"
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
    echo -e "${YELLOW}# Enabling service kubelet...${BOLD}"
    sudo systemctl enable kubelet

    echo -e "\n"
    echo -e "${GREEN}##### Kubernetes Success Installed #####${BOLD}"
    
    ###################

    echo -e "\n"
    echo -e "${BLUE}##### Installing CRI Docker #####${BOLD}"

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
    go build -o bin/cri-dockerd
    sudo mkdir -p /usr/local/bin
    sudo install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd
    sudo cp -a packaging/systemd/* /etc/systemd/system
    sudo sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service

    echo -e "\n"
    echo -e "${YELLOW}# Enabling service cri-dockerd...${BOLD}"
    sudo systemctl daemon-reload
    sudo systemctl enable cri-docker.service
    sudo systemctl enable --now cri-docker.socket

    echo -e "\n"
    echo -e "${GREEN}##### CRI Docker Success Installed #####${BOLD}"

    echo -e "\n"  
    echo -e "${YELLOW}# Checking kernel modules...${BOLD}"
    lsmod | grep br_netfilter

    echo -e "\n"
    echo -e "${YELLOW}# Disabling service ufw...${BOLD}"
    sudo ufw disable
    sudo service ufw stop
}

# function (1)
function master_install {
    # call function common_install
    common_install

    echo -e "\n"
    echo -e "${BLUE}##### Run Only On Master Node #####${BOLD}"

    echo -e "\n"
    echo -e "${YELLOW}# Pulling default images...${BOLD}"
    sudo kubeadm config images pull --cri-socket unix:///run/cri-dockerd.sock

    echo -e "\n"
    echo -e "${YELLOW}# Run kubeadm init command...${BOLD}"
    while [[ -z $internalip ]]; do
      read -p "Enter the internal IP address of the master node (e.g. 10.184.0.8): " internalip
    done
    read -p "Enter the pod network CIDR (e.g. 10.244.0.0/16): " podip
    if [ -z "$podip" ]; then
      podip="10.244.0.0/16"
    fi
    echo -e "\n"
    echo -e "${YELLOW}# Run kubeadm init command...${BOLD}"
    sudo kubeadm init \
      --pod-network-cidr="$podip" \
      --cri-socket unix:///run/cri-dockerd.sock \
      --upload-certs \
      --control-plane-endpoint="$internalip"

    echo -e "\n"
    echo -e "${YELLOW}# Setting kube config...${BOLD}"
    mkdir -p $HOME/.kube
    sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    echo -e "\n"
    echo -e "${YELLOW}# Setting networking using CNI Flannel...${BOLD}"
    kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

    echo -e "\n"
    echo -e "${YELLOW}# Getting cluster-info and nodes...${BOLD}"
    kubectl cluster-info
    kubectl get nodes

    echo -e "\n"
    echo -e "${YELLOW}# Print kubernetes token...${BOLD}"
    cd
    kubeadm token create --print-join-command > k8s-token.txt
    cat k8s-token.txt

    echo -e "\n"
    echo -e "${GREEN}##### Successfull Print Token #####${BOLD}"
}

# function (2)
function cluster_install {
    # call function common_install
    common_install

    echo -e "\n"
    echo -e "${BLUE}##### Run Only On Cluster Node #####${BOLD}"
    while true; do
      read -p "Enter the internal IP address of the cluster node: " internalip
      if [ -z "$internalip" ]; then
          echo "Please enter a valid internal IP address."
          continue
      fi
      read -p "Enter the token: " token
      if [ -z "$token" ]; then
          echo "Please enter a valid token."
          continue
      fi
      read -p "Enter the discovery-token-ca-cert-hash: " shatoken
      if [ -z "$shatoken" ]; then
          echo "Please enter a valid discovery-token-ca-cert-hash."
          continue
      fi
      break
    done

    echo -e "\n"
    echo -e "${YELLOW}# Run kubeadm join command...${BOLD}"
    sudo kubeadm join $internalip:6443 --token $token \
        --discovery-token-ca-cert-hash sha256:$shatoken \
        --cri-socket unix:///run/cri-dockerd.sock
    
    echo -e "\n"
    echo -e "${GREEN}##### Successfull Join Into Master Node #####${BOLD}"
}

# function (3)
function kubeadm_init {
    echo -e "\n"
    echo -e "${BLUE}##### Run Only On Master Node #####${BOLD}"

    echo -e "\n"
    echo -e "${YELLOW}# Pulling default images...${BOLD}"
    sudo kubeadm config images pull --cri-socket unix:///run/cri-dockerd.sock

    echo -e "\n"
    echo -e "${YELLOW}# Run kubeadm init command...${BOLD}"
    while [[ -z $internalip ]]; do
      read -p "Enter the internal IP address of the master node (e.g. 10.184.0.8): " internalip
    done
    read -p "Enter the pod network CIDR (e.g. 10.244.0.0/16): " podip
    if [ -z "$podip" ]; then
      podip="10.244.0.0/16"
    fi
    echo -e "\n"
    echo -e "${YELLOW}# Run kubeadm init command...${BOLD}"
    sudo kubeadm init \
      --pod-network-cidr="$podip" \
      --cri-socket unix:///run/cri-dockerd.sock \
      --upload-certs \
      --control-plane-endpoint="$internalip"

    echo -e "\n"
    echo -e "${YELLOW}# Setting kube config...${BOLD}"
    mkdir -p $HOME/.kube
    sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    echo -e "\n"
    echo -e "${YELLOW}# Setting networking using CNI Flannel...${BOLD}"
    kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

    echo -e "\n"
    echo -e "${YELLOW}# Getting cluster-info and nodes...${BOLD}"
    kubectl cluster-info
    kubectl get nodes

    echo -e "\n"
    echo -e "${YELLOW}# Print kubernetes token...${BOLD}"
    cd
    kubeadm token create --print-join-command > k8s-token.txt
    cat k8s-token.txt

    echo -e "\n"
    echo -e "${GREEN}##### Successfull Print Token #####${BOLD}"
}

# function (4)
function kubeadm_join {
    echo -e "\n"
    echo -e "${BLUE}##### Run Only On Cluster Node #####${BOLD}"
    while true; do
      read -p "Enter the internal IP address of the cluster node: " internalip
      if [ -z "$internalip" ]; then
          echo "Please enter a valid internal IP address."
          continue
      fi
      read -p "Enter the token: " token
      if [ -z "$token" ]; then
          echo "Please enter a valid token."
          continue
      fi
      read -p "Enter the discovery-token-ca-cert-hash: " shatoken
      if [ -z "$shatoken" ]; then
          echo "Please enter a valid discovery-token-ca-cert-hash."
          continue
      fi
      break
    done

    echo -e "\n"
    echo -e "${YELLOW}# Run kubeadm join command...${BOLD}"
    sudo kubeadm join $internalip:6443 --token $token \
        --discovery-token-ca-cert-hash sha256:$shatoken \
        --cri-socket unix:///run/cri-dockerd.sock
    
    echo -e "\n"
    echo -e "${GREEN}##### Successfull Join Into Master Node #####${BOLD}"
}

# function (5)
function kubeadm_reset {
    echo -e "\n"
    echo -e "${BLUE}##### Only Run To Reset Node #####${BOLD}"

    echo -e "\n"
    echo -e "${YELLOW}# Run kubeadm reset command...${BOLD}"
    sudo kubeadm reset --cri-socket=unix:///var/run/cri-dockerd.sock && sudo rm -rf /etc/cni/net.d && sudo rm -f $HOME/.kube/config
}

while true; do
    menu
    read choice
    case $choice in
        1)
            master_install
            break
            ;;
        2)
            cluster_install
            break
            ;;
        3)
            kubeadm_init
            break
            ;;
        4)
            kubeadm_join
            break
            ;;
        5)
            kubeadm_reset
            break
            ;;
        6)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please choose a valid option (1-4)."
            ;;
    esac
done
