# api
- kubectl api-resources
- kubectl api-resources -o wide
- kubectl api-versions
- kubectl api-versions | more
- kubectl explain --api-version=apps/v1 Deployment

- kubectl apply -f main.yml
- kubectl apply -f pod.yaml -n expressjs-restapi-system
- kubectl apply -f foldername

- kubectl cluster-info

- kubectl config current-context
- kubectl config set-context --current --namespace=<namespace>
- kubectl config view --minify | grep namespace
- kubectl config get-contexts $(kubectl config current-context) | awk '{print $5}' | tail -n 1
- kubectl config delete-context <name-context>

- kubectl create pod <pod-name>
- kubectl create namespace nginx-system
- kubectl create -f https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/platform/kube/bookinfo-db-poddisruptionbudget.yaml

- kubectl delete -f main.yml
- kubectl delete pod <pod-name>
- kubectl delete pod -l "app=nginx"
- kubectl delete pod -l "environment=development"
- kubectl delete pod --selector="app=nginx"
- kubectl delete pod <pod-name> --grace-period=0 --force
- kubectl delete pod --all -n istio-system
- kubectl delete pod $(kubectl get pods -A | grep "nginx-" | awk '{print $2}')
- kubectl delete namespace istio-system
- kubectl delete service flask-node-port -n dev

- kubectl describe deployment <deployment_name>
- kubectl describe pod <pod_name>
- kubectl describe pod nginx-deployment-6678ff89cf-2qtf2 -n nginx-system | grep -A 1 "Containers:"
- kubectl describe node
- kubectl describe node automate
- kubectl describe deployment flask -n dev
- kubectl describe service flask-node-port -n dev

- kubectl expose deployment nginx-deployment --type=LoadBalancer --port=80 --target-port=80

- kubectl exec -it expressjs-restapi-pod -n expressjs-restapi-system -- ls /app
- kubectl exec curl-pod -- env
- kubectl exec curl-pod -- env | grep NGINX_SVC
- kubectl exec -it curl-pod -- /bin/sh

- kubectl get deployment -A
- kubectl get daemonsets -A
- kubectl get endpoints -n default
- kubectl get ing -n default
- kubectl get ingressclass
- kubectl get ns -A
- kubectl get namespaces -A
- kubectl get node -A
- kubectl get pods -A
- kubectl get pods -n dev --selector=app=flask
- kubectl get pods -l app=nginx -o yaml | sed 's/namespace: default/namespace: nginx-system/' | kubectl apply -f -
- kubectl get pods -n nginx-system -o wide
- kubectl get rc
- kubectl get replicationcontrollers
- kubectl get rs
- kubectl get replicaset
- kubectl get svc -A
- kubectl get service -A
- kubectl get job
- kubectl get cronjob
- kubectl get -f file.yaml -o yaml
- kubectl get pv
- kubectl get pvc

- kubectl label node master-node node=master-node
- kubectl label node master-node node-role.kubernetes.io/control-plane=control-plane
- kubectl label node master-node node-role.kubernetes.io/control-plane-
- kubectl taint node master-node node-role.kubernetes.io/control-plane:NoSchedule
- kubectl taint node master-node node-role.kubernetes.io/control-plane:NoSchedule-

- kubectl label node cluster-node-a node-role.kubernetes.io/worker-a=worker-a
- kubectl label node cluster-node-a node-role.kubernetes.io/worker-a-
- kubectl taint node cluster-node-a node-role.kubernetes.io/worker-a:NoSchedule
- kubectl taint node cluster-node-a node-role.kubernetes.io/worker-a:NoSchedule-

- kubectl label node cluster-node-b node-role.kubernetes.io/worker-b=worker-b
- kubectl label node cluster-node-b node-role.kubernetes.io/worker-b-
- kubectl taint node cluster-node-b node-role.kubernetes.io/worker-b:NoSchedule
- kubectl taint node cluster-node-b node-role.kubernetes.io/worker-b:NoSchedule-

- kubectl taint nodes --all node-role.kubernetes.io/master-
- kubectl taint nodes --all node-role.kubernetes.io/control-plane-

- kubectl logs <scheduler-pod>
- kubectl logs <pod-name> -c <container-name>
- kubectl logs <pod-name> -n istio-system
- kubectl logs istio-ingressgateway-6f86b8c88d-fkhb5 -n istio-system
- kubectl logs expressjs-restapi-pod -n expressjs-restapi-system

- kubectl port-forward flask-6b58b4fbcf-g54nn 8080 -n dev

- kubectl replace -f file.yaml

- kubectl rollout history deployment name
- kubectl rollout pause deployment name
- kubectl rollout resume deployment name
- kubectl rollout restart deployment name
- kubectl rollout status deployment name
- kubectl rollout undo deployment name

==============================================================================================================
==============================================================================================================
==============================================================================================================
- istioctl manifest generate > istio.yaml		

- curl http://nginx-svc.default.svc.cluster.local:8080
- curl http://<service>.<namespace>.svc.cluster.local:8080

- /var/lib/kubelet/config.yaml
- /etc/kubernetes/kubelet.conf

- kubectl config set-cluster my-cluster --server=https://master-h1.thanos.my.id --kubeconfig=my-config --insecure-skip-tls-verify=true --pod-network-cidr=10.10.0.0/16 --apiserver-advertise-address=10.182.0.19
- kubectl config set-cluster my-cluster --server=https://master-h1.thanos.my.id --kubeconfig=my-config --insecure-skip-tls-verify=true --pod-network-cidr=10.10.0.0/16 --apiserver-advertise-address=10.182.0.19 --tls-cert-file=/path/to/cert --tls-private-key-file=/path/to/key
- kubectl config set-cluster my-cluster --server=http://master-h1.thanos.my.id --kubeconfig=my-config --insecure-skip-tls-verify=true --pod-network-cidr=10.10.0.0/16 --apiserver-advertise-address=10.182.0.19
- kubectl config set-cluster kube-cluster --server=http://10.182.0.22:6443 --insecure-skip-tls-verify=true
- kubectl config set-cluster kube-cluster --server=http://master-h1.thanos.my.id --kubeconfig=my-config --insecure-skip-tls-verify=true

- kubectl config view --kubeconfig=my-config
- kubectl config set-context kube-context --cluster=kube-cluster --user=kube-username
- kubectl config use-context kube-context

- 10.10.0.0/16
- 10.182.0.19
- 10.182.0.0/20

- --apiserver-advertise-address=10.182.0.19
- --cluster-cidr=10.10.0.0/16
- --pod-network-cidr=10.10.0.0/16
- --service-cluster-ip-range=10.182.0.0/20
