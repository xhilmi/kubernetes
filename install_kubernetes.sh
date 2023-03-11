

sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get update -y
sudo apt-get install ca-certificates curl gnupg lsb-release -y
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo chmod a+r /etc/apt/keyrings/docker.gpg
sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo docker run hello-world 

sudo git clone https://github.com/Mirantis/cri-dockerd.git
sudo wget https://go.dev/dl/go1.20.2.linux-amd64.tar.gz

## optional
## sudo rm -rf /usr/local/go

sudo tar -C /usr/local -xzf go1.20.2.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >>~/.profile
source ~/.profile
go version

cd cri-dockerd
sudo mkdir bin
sudo chmod 777 bin
go build -o bin/cri-dockerd
go build -o bin/cri-dockerd -buildvcs=false
sudo mkdir -p /usr/local/bin
sudo install -o root -g root -m 0777 bin/cri-dockerd /usr/local/bin/cri-dockerd
sudo cp -a packaging/systemd/* /etc/systemd/system
sudo sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
sudo systemctl daemon-reload
sudo systemctl enable cri-docker.service
sudo systemctl enable --now cri-docker.socket

sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --cri-socket=unix:///var/run/cri-dockerd.sock

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

## optional
## export KUBECONFIG=/etc/kubernetes/admin.conf
## Then you can join any number of worker nodes by running the following on each as root:
## kubeadm join 10.182.0.5:6443 --token ovf82b.kx7trjdpri0ir0og --discovery-token-ca-cert-hash sha256:bdfd6617fb8860cd03964a5a7afcb9984b9b104c704cea3a70fb2b3edb35dd52

cd
curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml -O
kubectl apply -f calico.yaml
kubectl get pods -A --watch

## optional 
## ln -s /home/user/.kube .kube
