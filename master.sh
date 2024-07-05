
#! /bin/bash

##Install Docker
#sudo apt-get update -y

#sudo apt-get install \
#    ca-certificates \
#    curl \
#    gnupg \
#    lsb-release -y

#curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

#echo \
#  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
#  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
#y
#sudo apt-get update -y
#sudo apt-get install docker-ce docker-ce-cli containerd.io -y
#sudo apt-get install zsh
sudo bash -c 'sudo cat > /etc/docker/daemon.json <<EOF
{
"exec-opts": ["native.cgroupdriver=systemd"],
"log-driver": "json-file",
"log-opts": {
"max-size": "100m"
},
"storage-driver": "overlay2"
}
EOF'

sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

###Install kubeadm, kubelet, kubectl

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

sudo swapoff -a

#sudo apt-get update -y
#sudo apt-get install -y apt-transport-https ca-certificates curl
#sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
#sudo apt-get update -y
sudo apt-get install kubeadm=1.22.0-00 kubelet=1.22.0-00 kubectl=1.22.0-00 -y


sudo kubeadm init --pod-network-cidr=10.244.0.0/16  


mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

kubectl taint nodes --all node-role.kubernetes.io/master-


# cd
# git clone https://github.com/k8snetworkplumbingwg/multus-cni.git
# cd multus-cni
# cat ./deployments/multus-daemonset-thick.yml | kubectl apply -f -
# #cat ./deployments/multus-daemonset-thick.yml | kubectl apply -f -
# kubectl taint nodes --all node-role.kubernetes.io/master-
# kubectl create ns o5
# ifconfig eth0 promisc
# ifconfig eth1 promisc 
# #kubectl apply -f https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/deployments/multus-daemonset-thick.yml
