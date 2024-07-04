/*
 * Copyright 2019-present Open Networking Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.onosproject.srv6_usid.cli;

import org.apache.karaf.shell.api.action.Argument;
import org.apache.karaf.shell.api.action.Command;
import org.apache.karaf.shell.api.action.Completion;
import org.apache.karaf.shell.api.action.lifecycle.Service;
import org.onlab.packet.Ip6Address;
import org.onlab.packet.Ip4Address;
import org.onlab.packet.IpAddress;
import org.onosproject.cli.AbstractShellCommand;
import org.onosproject.cli.net.DeviceIdCompleter;
import org.onosproject.net.Device;
import org.onosproject.net.DeviceId;
import org.onosproject.net.device.DeviceService;
import org.onlab.packet.MacAddress;
import org.onosproject.srv6_usid.Ipv6RoutingComponent;

/**
 * Ipv6 Route Insert Command
 */
@Service
@Command(scope = "onos", name = "srv6-encap-insert",
         description = "Insert a t_insert rule into the IPv6 Routing table")
public class Srv6EncapInsertCommand extends AbstractShellCommand {

    @Argument(index = 0, name = "uri", description = "Device ID",
              required = true, multiValued = false)
    @Completion(DeviceIdCompleter.class)
    String uri = null;

    @Argument(index = 1, name = "ipv4NetAddress",
            description = "IPv6 address",
            required = true, multiValued = false)
    String ipv4NetAddr = null;

    @Argument(index = 2, name = "mask",
            description = "IPv6 mask",
            required = false, multiValued = false)
    int mask = 64;

    @Argument(index = 3, name = "ipv6SrcAddress",
            description = "IPv6 address src",
            required = true, multiValued = false)
    String src_addr_net = null;

    @Argument(index = 4, name = "ipv6S1ddress",
            description = "IPv6 address S1",
            required = true, multiValued = false)
    String s1_net = null;

    @Argument(index = 5, name = "dscp",
            description = "dscp",
            required = false, multiValued = false)
    int dscp = 0;    

    @Override
    protected void doExecute() {
        DeviceService deviceService = get(DeviceService.class);
        Ipv6RoutingComponent app = get(Ipv6RoutingComponent.class);

        Device device = deviceService.getDevice(DeviceId.deviceId(uri));
        if (device == null) {
            print("Device \"%s\" is not found", uri);
            return;
        }
        
        Ip4Address ipv4Addr = Ip4Address.valueOf(ipv4NetAddr);
        Ip6Address src_addr = Ip6Address.valueOf(src_addr_net);
        Ip6Address s1 = Ip6Address.valueOf(s1_net);
      

        print("Installing route on device %s", uri);

        app.insertEnSRv6V4Rule(device.id(), ipv4Addr, mask, dscp, src_addr, s1);

    }

}
