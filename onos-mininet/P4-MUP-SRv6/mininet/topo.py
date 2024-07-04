#!/usr/bin/python

#  Copyright 2019-present Open Networking Foundation
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

import argparse

from mininet.cli import CLI
from mininet.log import setLogLevel
from mininet.net import Mininet
from mininet.node import RemoteController
from mininet.topo import Topo
from mininet.node import Host
from stratum import StratumBmv2Switch
from host6 import IPv6Host
from mininet.link import Intf
import subprocess

CPU_PORT = 255

class IPv4Host(Host):
    """Host that can be configured with an IPv4 gateway (default route).
    """

    def config(self, mac=None, ip=None, defaultRoute=None, lo='up', gw=None,
               **_params):
        super(IPv4Host, self).config(mac, ip, defaultRoute, lo, **_params)
        self.cmd('ip -4 addr flush dev %s' % self.defaultIntf())
        self.cmd('ip -6 addr flush dev %s' % self.defaultIntf())
        self.cmd('ip -4 link set up %s' % self.defaultIntf())
        self.cmd('ip -4 addr add %s dev %s' % (ip, self.defaultIntf()))
        if gw:
            self.cmd('ip -4 route add default via %s' % gw)
        # Disable offload
        for attr in ["rx", "tx", "sg"]:
            cmd = "/sbin/ethtool --offload %s %s off" % (
                self.defaultIntf(), attr)
            self.cmd(cmd)

        def updateIP():
            return ip.split('/')[0]

        self.defaultIntf().updateIP = updateIP


class TutorialTopo(Topo):
    
    """
    /--------\   /----\   /----\   /----\   /----\
    | Site A |---| R1 |---| R4 |---| R5 |---| R8 |
    \________/   \____/   \____/   \____/   \____/
                   |         |       |        |
                     \     /       |        |
					   R11		R10		 R9
				     / 	   \   
				   |				
    /--------\   /----\   /----\   /----\   /----\
    | Site B |---| R2 |---| R3 |---| R6 |---| R7 |
    \________/   \____/   \____/   \____/   \____/

    """


    def __init__(self, *args, **kwargs):
        Topo.__init__(self, *args, **kwargs)

        # End routers
        r1 = self.addSwitch('r1', cls=StratumBmv2Switch,cpuport=CPU_PORT)
        r2 = self.addSwitch('r2', cls=StratumBmv2Switch,cpuport=CPU_PORT)

        # Transit routers
        r3 = self.addSwitch('r3', cls=StratumBmv2Switch, cpuport=CPU_PORT)
        r4 = self.addSwitch('r4', cls=StratumBmv2Switch, cpuport=CPU_PORT)
        r5 = self.addSwitch('r5', cls=StratumBmv2Switch, cpuport=CPU_PORT)
        r6 = self.addSwitch('r6', cls=StratumBmv2Switch, cpuport=CPU_PORT)
        r7 = self.addSwitch('r7', cls=StratumBmv2Switch, cpuport=CPU_PORT)
        r8 = self.addSwitch('r8', cls=StratumBmv2Switch, cpuport=CPU_PORT)
        r9 = self.addSwitch('r9', cls=StratumBmv2Switch, cpuport=CPU_PORT)

        

        # Switch Links
        self.addLink(r1, r2)
        self.addLink(r1, r4)
        self.addLink(r1, r6)

        self.addLink(r2, r3)
        self.addLink(r2, r4)
        self.addLink(r2, r5)

        self.addLink(r3, r4)
        self.addLink(r3, r5)
        self.addLink(r3, r8)

        self.addLink(r4, r5)
        self.addLink(r4, r6)
        self.addLink(r4, r7)

        self.addLink(r5, r6)
        self.addLink(r5, r7)
        self.addLink(r5, r8)
        self.addLink(r5, r9)

        self.addLink(r6, r7)

        # self.addLink(r7, r8)
        self.addLink(r7, r9)

        self.addLink(r8, r9)
        



        # IPv6 hosts attached to leaf 1
        h1 = self.addHost('h1', cls=IPv6Host, mac="00:00:00:00:00:10",
                           ipv6='2001:1:1::1/64', ipv6_gw='2001:1:1::ff')
        h2 = self.addHost('h2', cls=IPv6Host, mac="00:00:00:00:00:20",
                          ipv6='2001:1:2::1/64', ipv6_gw='2001:1:2::ff')

        self.addLink(h1, r1)
        self.addLink(h2, r8)

        # custom code
        h1a = self.addHost('h1a', cls=IPv4Host, mac="00:00:00:00:01:1A",
                           ip='10.100.200.20/24', gw='10.100.200.1')
        self.addLink(h1a, r1)

        h1b = self.addHost('h1b', cls=IPv4Host, mac="00:00:00:00:01:1B",
                           ip='10.100.200.21/24', gw='10.100.200.1')
        self.addLink(h1b, r1)

        h2a = self.addHost('h2a', cls=IPv4Host, mac="00:00:00:00:02:1A",
                           ip='192.168.0.20/24', gw='192.168.0.1')
        self.addLink(h2a, r8)

        h3a = self.addHost('h3a', cls=IPv4Host, mac="00:00:00:00:03:1A",
                           ip='192.168.1.20/24', gw='192.168.1.1')
        self.addLink(h3a, r9)

        #for communicate with worker2
        cmd_str = 'ip link add v_eth3 type veth peer name v_eth4'
        subprocess.call(cmd_str, shell=True)

        cmd_str = 'ifconfig v_eth3 up'
        subprocess.call(cmd_str, shell=True)
        
        cmd_str = 'ifconfig v_eth4 up'
        subprocess.call(cmd_str, shell=True)
        intfName = 'v_eth4'

        #for communicate with worker3
        cmd_str = 'ip link add v2_eth3 type veth peer name v2_eth4'
        subprocess.call(cmd_str, shell=True)

        cmd_str = 'ifconfig v2_eth3 up'
        subprocess.call(cmd_str, shell=True)
        
        cmd_str = 'ifconfig v2_eth4 up'
        subprocess.call(cmd_str, shell=True)
        intfName = 'v2_eth4'

        #for communicate with worker1
        cmd_str = 'ip link add v3_eth3 type veth peer name v3_eth4'
        subprocess.call(cmd_str, shell=True)

        cmd_str = 'ifconfig v3_eth3 up'
        subprocess.call(cmd_str, shell=True)
        
        cmd_str = 'ifconfig v3_eth4 up'
        subprocess.call(cmd_str, shell=True)
        intfName = 'v3_eth4'


def main():
    topo = TutorialTopo()
    controller = RemoteController('c0', ip="127.0.0.1")

    net = Mininet(topo=topo, controller=None)
    net.addController(controller)

    _intf = Intf( 'v_eth4', node= net.getNodeByName('r1'))
    _intf = Intf( 'v2_eth4', node= net.getNodeByName('r8'))
    _intf = Intf( 'v3_eth4', node= net.getNodeByName('r9'))

    net.start()
    CLI(net)
    net.stop()


if __name__ == "__main__":
    main()
