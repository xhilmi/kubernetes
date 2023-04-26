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
# kubectl -n monitoring port-forward svc/grafana 3000
# kubectl -n monitoring port-forward svc/prometheus-k8s 9090
# kubectl -n monitoring port-forward svc/alertmanager-main 9093

# Access from NodePort / Load Balancer
kubectl get networkpolicies -A
kubectl -n monitoring delete networkpolicies.networking.k8s.io --all

# Prometheus Alertmanager Grafana = NodePort 
kubectl -n monitoring patch svc alertmanager-main -p '{"spec": {"type": "NodePort"}}'
kubectl -n monitoring patch svc grafana -p '{"spec": {"type": "NodePort"}}'
kubectl -n monitoring patch svc prometheus-k8s -p '{"spec": {"type": "NodePort"}}'
kubectl -n monitoring get svc | grep "NodePort\|LoadBalancer"

# Prometheus Alertmanager Grafana Backup 
kubectl -n monitoring get svc alertmanager-main -o yaml > alertmanager-main.yaml-BAK
kubectl -n monitoring get svc grafana -o yaml > grafana.yaml-BAK
kubectl -n monitoring get svc prometheus-k8s -o yaml > prometheus-k8s.yaml-BAK

# Prometheus Alertmanager Grafana = NodePort Patch
sudo tee alertmanager_main_patch.yaml <<EOF
spec:
  ports:
  - name: web
    nodePort: 30001
    port: 9093
    protocol: TCP
    targetPort: web
EOF
sudo tee grafana_patch.yaml <<EOF
spec:
  ports:
  - name: http
    nodePort: 30002
    port: 3000
    protocol: TCP
    targetPort: http
EOF
sudo tee prometheus_k8s_patch.yaml <<EOF
spec:
  ports:
  - name: web
    nodePort: 30003
    port: 9090
    protocol: TCP
    targetPort: web
EOF

kubectl -n monitoring patch svc alertmanager-main -p "$(cat alertmanager_main_patch.yaml)"
kubectl -n monitoring patch svc grafana -p "$(cat grafana_patch.yaml)"
kubectl -n monitoring patch svc prometheus-k8s -p "$(cat prometheus_k8s_patch.yaml)"
kubectl -n monitoring get svc | grep "NodePort\|LoadBalancer"

# Prometheus Alertmanager Grafana = LoadBalancer
kubectl -n monitoring patch svc alertmanager-main -p '{"spec": {"type": "LoadBalancer"}}'
kubectl -n monitoring patch svc grafana -p '{"spec": {"type": "LoadBalancer"}}'
kubectl -n monitoring patch svc prometheus-k8s -p '{"spec": {"type": "LoadBalancer"}}'
kubectl -n monitoring get svc | grep "NodePort\|LoadBalancer"

