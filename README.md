# srv6-dmm


# Networking Connection Topology

```

                           ________________                              ________________ 
                          |     manager    | 192.168.28.81 (wlp2s0)     |                |
                          |     (5GC)      |*---------------------------|    Internet    |
                          |________________|                            |________________|
                                  * 192.168.20.1 (eno1)                         |                        
                                  |                                             |                        
                                  |                                             |                        
                                  |                                             |                        
                                  |                                             |                      
           _______________________._______________________________________._____|_________________________________________________________.__________________________.__
          |                                                               |     |                                                         |                          |
          |                                                               |     |                                                         |                          |
          | 192.168.20.9 (enp4s0f1)             192.168.20.11 (enp0s31f6) |     | 192.168.28.104 (wlp1s0)                                 | 192.168.20.8 (enp4s0f1)  |
  ________*_______                                                     ___*_____*______                                           ________*_______                   |
 |    worker 2    |  10.100.200.3 (eno0)            10.100.200.4 (br0)|                | 192.168.0.4 (br1)     192.168.0.3 (eno0)|                |                  |
 |    (UE, gNB)   |*-------------------------------------------------*|     mininet    |*---------------------------------------*| worker 3 (UPF) |                  |
 |________________|                                                   |________________|                                         |________________|                  |
                                                                               * 192.168.1.4 (br2)                                                                   |
                                                                               |                                                                                     |
                                                                               |                                                  ________________                   |
                                                                               |                               192.168.1.3 (eno0)|                |                  |
                                                                               |------------------------------------------------*|    worker 1    |*-----------------|
                                                                                                                                 |________________| 192.168.20.10 (enp4s0f1)


```


## Manager: worker-desktop
### natting
```
iptables -A FORWARD -i eno1 -o wlp2s0 -j ACCEPT
iptables -A FORWARD -i wlp2s0 -o eno1 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -t nat -A POSTROUTING -o wlp2s0 -j MASQUERADE
```
### free5gc: 5GC initiation
```
cd srv6-dmm/manager_worker/free5gc
./run.sh

# to stop all running NFs
./force_kill.sh 
```

### webconsole for UE register
```
cd srv6-dmm/manager_worker/free5gc
./bin/webconsole
```



## Onos-Mininet: mininet-GB-BSi5-6200

## Worker 1: worker1

## Worker 2: worker2
### gNB, UE initiation
```
cd srv6-dmm/worker2/UERANSIM
./build/nr-gnb -c ./config/free5gc-gnb.yaml
./build/nr-ue -c ./config/free5gc-ue.yaml

# test UE connection to UPF
ping 192.168.0.3 -I uesimtun0 -i 0.3

```


## Worker 3: worker3
### UPF initiation
```
route del -net 10.60.0.0/24 gw 192.168.0.20
cd srv6-dmm/worker3/free5gc
./bin/upf

# to stop all running NFs
./force_kill.sh
```









