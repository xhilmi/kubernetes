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

echo -e "${GREEN}
#######################################################################
#            Tools Reset Master or Worker Nodes Kubernetes            #
#######################################################################
${BOLD}"
sudo kubeadm reset --force \
--cri-socket=unix:///var/run/cri-dockerd.sock && \
sudo rm -rf /etc/cni/net.d && \
sudo rm -f $HOME/.kube/config