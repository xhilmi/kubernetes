# Prometheus (Operator) and Grafana Monitoring On Kubernetes
# https://computingforgeeks.com/setup-prometheus-and-grafana-on-kubernetes/
cd ~
mkdir repository && repository
git clone https://github.com/prometheus-operator/kube-prometheus.git
cd kube-prometheus
kubectl create -f manifests/setup
kubectl get ns monitoring
kubectl create -f manifests/
kubectl get pods -n monitoring
kubectl get svc -n monitoring

# Access from Port Forward / Proxy
# Username: admin
# Password: admin
# kubectl --namespace monitoring port-forward svc/grafana 3000
# kubectl --namespace monitoring port-forward svc/prometheus-k8s 9090
# kubectl --namespace monitoring port-forward svc/alertmanager-main 9093

# Access from NodePort / Load Balancer
kubectl get networkpolicies -A
kubectl -n monitoring delete networkpolicies.networking.k8s.io --all

# Prometheus Alertmanager Grafana = NodePort
kubectl --namespace monitoring patch svc prometheus-k8s -p '{"spec": {"type": "NodePort"}}'
kubectl --namespace monitoring patch svc alertmanager-main -p '{"spec": {"type": "NodePort"}}'
kubectl --namespace monitoring patch svc grafana -p '{"spec": {"type": "NodePort"}}'
kubectl -n monitoring get svc  | grep NodePort

# Prometheus Alertmanager Grafana = LoadBalancer
kubectl --namespace monitoring patch svc prometheus-k8s -p '{"spec": {"type": "LoadBalancer"}}'
kubectl --namespace monitoring patch svc alertmanager-main -p '{"spec": {"type": "LoadBalancer"}}'
kubectl --namespace monitoring patch svc grafana -p '{"spec": {"type": "LoadBalancer"}}'
kubectl -n monitoring get svc  | grep LoadBalancer

