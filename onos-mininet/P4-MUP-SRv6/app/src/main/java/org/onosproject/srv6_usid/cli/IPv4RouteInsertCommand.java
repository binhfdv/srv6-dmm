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
 * IPv4 Route Insert Command
 */
@Service
@Command(scope = "onos", name = "route-ipv4-insert",
         description = "Insert a t_insert rule into the IPv4 Routing table")
public class IPv4RouteInsertCommand extends AbstractShellCommand {

    @Argument(index = 0, name = "uri", description = "Device ID",
              required = true, multiValued = false)
    @Completion(DeviceIdCompleter.class)
    String uri = null;

    @Argument(index = 1, name = "IPv4NetAddress",
            description = "IPv4 address",
            required = true, multiValued = false)
    String ipv4NetAddr = null;

    @Argument(index = 2, name = "mask",
            description = "IPv4 mask",
            required = false, multiValued = false)
    int mask = 64;

    @Argument(index = 3, name = "macDstAddr",
            description = "MAC destination address",
            required = true, multiValued = false)
    String macDstAddr = null;

    @Override
    protected void doExecute() {
        DeviceService deviceService = get(DeviceService.class);
        Ipv6RoutingComponent app = get(Ipv6RoutingComponent.class);

        Device device = deviceService.getDevice(DeviceId.deviceId(uri));
        if (device == null) {
            print("Device \"%s\" is not found", uri);
            return;
        }
        
        Ip4Address destIp = Ip4Address.valueOf(ipv4NetAddr);
        MacAddress nextHop = MacAddress.valueOf(macDstAddr);

        print("Installing route on device %s", uri);

        app.insertV4RoutingRule(device.id(), destIp, mask, nextHop);

    }

}
