#!/bin/bash
# install docker full version on linux ubuntu

sudo apt-get remove docker docker-engine docker.io containerd runc;
sudo apt-get update -y;
sudo apt-get install ca-certificates curl gnupg lsb-release -y;
sudo mkdir -m 0755 -p /etc/apt/keyrings;
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg;
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null;

sudo apt-get update -y;
sudo chmod a+r /etc/apt/keyrings/docker.gpg;
sudo apt-get update -y;
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y;
sudo docker run hello-world ;

sudo git clone https://github.com/Mirantis/cri-dockerd.git;
sudo wget https://go.dev/dl/go1.20.2.linux-amd64.tar.gz;

## optional
## sudo rm -rf /usr/local/go

sudo tar -C /usr/local -xzf go1.20.2.linux-amd64.tar.gz;
echo 'export PATH=$PATH:/usr/local/go/bin' >>~/.profile;
source ~/.profile;
go version;

cd cri-dockerd;
sudo mkdir bin;
sudo chmod 777 bin;
go build -o bin/cri-dockerd;
go build -o bin/cri-dockerd -buildvcs=false;
sudo mkdir -p /usr/local/bin;
sudo install -o root -g root -m 0777 bin/cri-dockerd /usr/local/bin/cri-dockerd;
sudo cp -a packaging/systemd/* /etc/systemd/system;
sudo sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service;
sudo systemctl daemon-reload;
sudo systemctl enable cri-docker.service;
sudo systemctl enable --now cri-docker.socket;
