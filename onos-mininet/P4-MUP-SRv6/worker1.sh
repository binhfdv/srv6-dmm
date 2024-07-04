ip link add v3_eth1 type veth peer name v3_eth2 && ifconfig v3_eth1 up
ip link set v3_eth2 netns  $(docker inspect --format='{{ .State.Pid }}' $(docker ps -aqf "name=mininet"))

docker exec -it  mininet brctl addbr mybridge3 
docker exec -it  mininet ifconfig v3_eth2 up
docker exec -it  mininet brctl addif mybridge3 v3_eth2 
docker exec -it  mininet brctl addif mybridge3 v3_eth3
docker exec -it  mininet ifconfig mybridge3 192.168.1.19/24 up

docker exec -it  mininet ping 192.168.1.20 -I mybridge3 -c 2


ovs-vsctl del-br br2
ovs-vsctl add-br br2
ifconfig br2 up
ovs-vsctl add-port br2 enxaaaaaaaaab7f
ovs-vsctl add-port br2 v3_eth1
ifconfig enxaaaaaaaaab7f 0
ifconfig br2 192.168.1.4/24 up
ping 192.168.1.20 -I br2 -c 2
