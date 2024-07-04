#worker2
docker exec -it  mininet brctl addbr mybridge
ip link add v_eth1 type veth peer name v_eth2 && ifconfig v_eth1 up

ip link set v_eth2 netns  $(docker inspect --format='{{ .State.Pid }}' $(docker ps -aqf "name=mininet"))
docker exec -it  mininet ifconfig v_eth2 up
docker exec -it  mininet brctl addif mybridge v_eth2
docker exec -it  mininet brctl addif mybridge v_eth3
docker exec -it  mininet ifconfig mybridge 10.100.200.19/24 up

docker exec -it  mininet ping 10.100.200.20 -I mybridge -c 2

ovs-vsctl del-br br0
ovs-vsctl add-br br0
ifconfig br0 up
ovs-vsctl add-port br0 enxf8e43b4d17e5
ovs-vsctl add-port br0 v_eth1
ifconfig enxf8e43b4d17e5 0
ifconfig br0 10.100.200.4/24 up

ping 10.100.200.20 -I br0 -c 2


#worker3
ip link add v2_eth1 type veth peer name v2_eth2 && ifconfig v2_eth1 up
ip link set v2_eth2 netns  $(docker inspect --format='{{ .State.Pid }}' $(docker ps -aqf "name=mininet"))

docker exec -it  mininet brctl addbr mybridge2 
docker exec -it  mininet ifconfig v2_eth2 up
docker exec -it  mininet brctl addif mybridge2 v2_eth2 
docker exec -it  mininet brctl addif mybridge2 v2_eth3
docker exec -it  mininet ifconfig mybridge2 192.168.0.19/24 up

docker exec -it  mininet ping 192.168.0.20 -I mybridge2 -c 2


ovs-vsctl del-br br1
ovs-vsctl add-br br1
ifconfig br1 up
ovs-vsctl add-port br1 enxf8e43b26ac73
ovs-vsctl add-port br1 v2_eth1
ifconfig enxf8e43b26ac73 0
ifconfig br1 192.168.0.4/24 up

ping 192.168.0.20 -I br1 -c 2



#worker1
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


####################
bash util/onos-cmd source /config/routing_tables.txt

############config for h1a to h2a
docker exec -it mininet /mininet/host-cmd h1a ip route add  192.168.0.0/24 dev  h1a-eth0
docker exec -it mininet /mininet/host-cmd h1a arp -s 192.168.0.20 00:aa:00:00:00:01
docker exec -it mininet /mininet/host-cmd h1a arp -s 192.168.0.4 00:aa:00:00:00:01
docker exec -it mininet /mininet/host-cmd h1a arp -s 192.168.0.3 00:aa:00:00:00:01


docker exec -it mininet /mininet/host-cmd h2a ip route add  10.100.200.0/24 dev  h2a-eth0
docker exec -it mininet /mininet/host-cmd h2a arp -s 10.100.200.20 00:aa:00:00:00:08
docker exec -it mininet /mininet/host-cmd h2a arp -s 10.100.200.4 00:aa:00:00:00:08
docker exec -it mininet /mininet/host-cmd h2a arp -s 10.100.200.3 00:aa:00:00:00:08

bash util/onos-cmd srv6-encap-insert device:r1 192.168.0.20 24 fcbb:bb00:01:: fcbb:bb00:2:3:8:fd44::  00
bash util/onos-cmd srv6-encap-insert device:r8 10.100.200.20 24 fcbb:bb00:08:: fcbb:bb00:3:2:1:fd44::   00
bash util/onos-cmd route-ipv4-insert device:r8 192.168.0.20 24 00:00:00:00:02:1A
bash util/onos-cmd route-ipv4-insert device:r1 10.100.200.20 24 00:00:00:00:01:1A

############config for h1a to h3a
docker exec -it mininet /mininet/host-cmd h1a ip route add  192.168.1.0/24 dev  h1a-eth0
docker exec -it mininet /mininet/host-cmd h1a arp -s 192.168.1.20 00:aa:00:00:00:01
docker exec -it mininet /mininet/host-cmd h1a arp -s 192.168.1.4 00:aa:00:00:00:01
docker exec -it mininet /mininet/host-cmd h1a arp -s 192.168.1.3 00:aa:00:00:00:01


docker exec -it mininet /mininet/host-cmd h3a ip route add  10.100.200.0/24 dev  h3a-eth0
docker exec -it mininet /mininet/host-cmd h3a arp -s 10.100.200.20 00:aa:00:00:00:09
docker exec -it mininet /mininet/host-cmd h3a arp -s 10.100.200.4 00:aa:00:00:00:09
docker exec -it mininet /mininet/host-cmd h3a arp -s 10.100.200.3 00:aa:00:00:00:09

bash util/onos-cmd srv6-encap-insert device:r1 192.168.1.20 24 fcbb:bb00:01:: fcbb:bb00:6:7:9:fd44::  00
bash util/onos-cmd srv6-encap-insert device:r9 10.100.200.20 24 fcbb:bb00:09:: fcbb:bb00:7:6:1:fd44::   00
bash util/onos-cmd route-ipv4-insert device:r9 192.168.1.20 24 00:00:00:00:03:1A


##config for h1a to services
docker exec -it mininet /mininet/host-cmd h1a ip route add  10.96.10.0/24 dev  h1a-eth0
docker exec -it mininet /mininet/host-cmd h1a arp -s 10.96.10.30 00:aa:00:00:00:01
docker exec -it mininet /mininet/host-cmd h1a arp -s 10.96.10.40 00:aa:00:00:00:01
docker exec -it mininet /mininet/host-cmd h1a arp -s 10.96.10.50 00:aa:00:00:00:01

# worker 3
# binary cat-dog
# bash util/onos-cmd srv6-encap-insert device:r1 10.96.10.30 24 fcbb:bb00:01:: fcbb:bb00:2:3:8:fd44::  00
# dog
# bash util/onos-cmd srv6-encap-insert device:r1 10.96.10.50 24 fcbb:bb00:01:: fcbb:bb00:4:5:8:fd44::  00
# cat
# bash util/onos-cmd srv6-encap-insert device:r1 10.96.10.40 24 fcbb:bb00:01:: fcbb:bb00:6:5:8:fd44::  00


# worker 1
# binary cat-dog
# bash util/onos-cmd srv6-encap-insert device:r1 10.96.10.30 24 fcbb:bb00:01:: fcbb:bb00:2:3:9:fd44::  00
# dog
# bash util/onos-cmd srv6-encap-insert device:r1 10.96.10.50 24 fcbb:bb00:01:: fcbb:bb00:4:5:9:fd44::  00
# cat
# bash util/onos-cmd srv6-encap-insert device:r1 10.96.10.40 24 fcbb:bb00:01:: fcbb:bb00:6:7:9:fd44::  00


# worker 3
# config service at h2a come back h1a
docker exec -it mininet /mininet/host-cmd h2a route add -net 10.96.10.0/24 gw 192.168.0.3
bash util/onos-cmd route-ipv4-insert device:r8 10.96.10.30 32 00:00:00:00:02:1A
bash util/onos-cmd route-ipv4-insert device:r8 10.96.10.40 32 00:00:00:00:02:1A
bash util/onos-cmd route-ipv4-insert device:r8 10.96.10.50 32 00:00:00:00:02:1A


# worker 1
# config service h3a come back h1a
docker exec -it mininet /mininet/host-cmd h3a route add -net 10.96.10.0/24 gw 192.168.1.3
bash util/onos-cmd route-ipv4-insert device:r9 10.96.10.30 32 00:00:00:00:03:1A
bash util/onos-cmd route-ipv4-insert device:r9 10.96.10.40 32 00:00:00:00:03:1A
bash util/onos-cmd route-ipv4-insert device:r9 10.96.10.50 32 00:00:00:00:03:1A

#NOTE that set default gw  on worker3, worker1 and worker2``
# example: route add -net 10.100.200.0/24 gw 192.168.1.20   on worker1
# example: route add -net 10.100.200.0/24 gw 192.168.0.20   on worker3
# example: route add -net 192.168.0.0/24 gw 10.100.200.20   on worker2
# example: route add -net 192.168.1.0/24 gw 10.100.200.20   on worker2
# example: route add -net 192.168.1.0/24 gw 10.100.200.20    on worker2


#bash util/onos-cmd route-gtp4d-insert device:r1 192.168.0.3 24 fcbb:bb00:01:: fcbb:bb00:6:7:9:8:fd44::

#docker exec -it mininet /mininet/host-cmd h2a ip route add  10.60.0.0/24 dev  h2a-eth0
#docker exec -it mininet /mininet/host-cmd h2a arp -s 10.60.0.1 00:aa:00:00:00:08

# bash util/onos-cmd  srv6-encap-insert device:r8 10.60.0.1 24 fcbb:bb00:08:: fcbb:bb00:3:2:1:fd44::   00

# bash util/onos-cmd  srv6-encap-insert device:r8 10.60.0.1 24 fcbb:bb00:08:: fcbb:bb00:3:2:1:4eee::   00

