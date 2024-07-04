# route add -net 10.60.0.0/24 gw 192.168.0.20  on  worker3
# route add -net 10.60.0.0/24 gw 192.168.1.20  on  worker1

#setup for h2a to h1a
docker exec -it mininet /mininet/host-cmd h2a ip route add  10.60.0.0/24 dev  h2a-eth0
docker exec -it mininet /mininet/host-cmd h2a arp -s 10.60.0.1 00:aa:00:00:00:08

bash util/onos-cmd  srv6-encap-insert device:r8 10.60.0.1 24 fcbb:bb00:08:: fcbb:bb00:9:3:2:1:4eee::   00

# setup for h3a to h1a
docker exec -it mininet /mininet/host-cmd h3a ip route add  10.60.0.0/24 dev  h3a-eth0
docker exec -it mininet /mininet/host-cmd h3a arp -s 10.60.0.1 00:aa:00:00:00:09

bash util/onos-cmd  srv6-encap-insert device:r9 10.60.0.1 24 fcbb:bb00:09:: fcbb:bb00:8:5:4:1:4eee::   00

#setup for h1a to h2a or h3a
# bash util/onos-cmd route-gtp4d-insert device:r1 192.168.0.3 24 fcbb:bb00:01:: fcbb:bb00:2:3:8:fd44::
# bash util/onos-cmd route-gtp4d-insert device:r1 192.168.0.3 24 fcbb:bb00:01:: fcbb:bb00:4:5:8:fd44::

# bash util/onos-cmd route-gtp4d-insert device:r1 192.168.1.3 24 fcbb:bb00:01:: fcbb:bb00:4:5:9:fd44::
# bash util/onos-cmd route-gtp4d-insert device:r1 192.168.1.3 24 fcbb:bb00:01:: fcbb:bb00:6:5:9:fd44::

bash util/onos-cmd  route-ipv4-insert device:r1 10.60.0.1 24  00:00:00:00:01:1A

# route from UE to service: gtp decapsulation, worker 3
# binary cat-dog
# bash util/onos-cmd route-gtp4d-insert device:r1 10.96.10.30 24 fcbb:bb00:01:: fcbb:bb00:2:3:8:fd44::
# # dog
# bash util/onos-cmd route-gtp4d-insert device:r1 10.96.10.50 24 fcbb:bb00:01:: fcbb:bb00:4:5:9:8:fd44::
# # cat
# bash util/onos-cmd route-gtp4d-insert device:r1 10.96.10.40 24 fcbb:bb00:01:: fcbb:bb00:6:7:9:8:fd44::

# route from UE to service: gtp decapsulation, worker 1
# binary cat-dog
# bash util/onos-cmd route-gtp4d-insert device:r1 10.96.10.30 24 fcbb:bb00:01:: fcbb:bb00:2:3:9:fd44::
# # dog
# bash util/onos-cmd route-gtp4d-insert device:r1 10.96.10.50 24 fcbb:bb00:01:: fcbb:bb00:4:5:8:9:fd44::
# # cat
# bash util/onos-cmd route-gtp4d-insert device:r1 10.96.10.40 24 fcbb:bb00:01:: fcbb:bb00:6:5:8:9:fd44::



# route to UE: gtp encapsulation
# bash util/onos-cmd route-gtp4e-insert device:r1 192.168.0.3 10.100.200.3 fcbb:bb00:01:4eee::  1 # TEID: 1
# bash util/onos-cmd route-gtp4e-insert device:r1 192.168.1.3 10.100.200.3 fcbb:bb00:01:4eee::  1


bash util/onos-cmd route-gtp4e-insert device:r1 10.96.10.30 10.100.200.3 fcbb:bb00:01:4eee::  1 # TEID: 1
bash util/onos-cmd route-gtp4e-insert device:r1 10.96.10.40 10.100.200.3 fcbb:bb00:01:4eee::  1
bash util/onos-cmd route-gtp4e-insert device:r1 10.96.10.50 10.100.200.3 fcbb:bb00:01:4eee::  1 # TEID: 1
