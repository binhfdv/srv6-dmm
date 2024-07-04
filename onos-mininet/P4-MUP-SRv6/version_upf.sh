# route del -net 10.60.0.0/24 gw 192.168.0.20 on worker3
docker exec -it mininet /mininet/host-cmd h2a ip route add  10.60.0.0/24 dev  h2a-eth0
