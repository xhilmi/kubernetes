### ADDITIONAL COMMAND ###
### RUN IF YOU WANT TO REBUILD KUBEADM - AUTOMATICALLY ###
- sudo kubeadm reset --cri-socket=unix:///var/run/cri-dockerd.sock

### RUN IF YOU WANT TO REBUILD KUBEADM - MANUALLY ###
- sudo systemctl stop kubelet
- sudo rm /etc/kubernetes/manifests/kube-apiserver.yaml
- sudo rm /etc/kubernetes/manifests/kube-controller-manager.yaml
- sudo rm /etc/kubernetes/manifests/kube-scheduler.yaml
- sudo rm /etc/kubernetes/manifests/etcd.yaml
- sudo rm -rf /var/lib/etcd

### DEBUGGING COMMAND ###
- crictl --runtime-endpoint unix:///var/run/cri-dockerd.sock ps -a | grep kube | grep -v pause
- crictl --runtime-endpoint unix:///var/run/cri-dockerd.sock logs CONTAINERID
- systemctl status kubelet
- journalctl -xeu kubelet
