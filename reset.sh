kubeadm reset -f

rm -rf /etc/cni /etc/kubernetes /var/lib/dockershim /var/lib/etcd /var/lib/kubelet /var/run/kubernetes ~/.kube/*

ip link set cni0 down && ip link set flannel.1 down

ip link delete cni0 && ip link delete flannel.1

systemctl restart docker && systemctl restart kubelet

