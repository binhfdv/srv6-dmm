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

package org.onosproject.srv6_usid.common;

import org.onlab.packet.Ip6Address;
import org.onlab.packet.MacAddress;
import org.onosproject.net.DeviceId;
import org.onosproject.net.config.Config;

/**
 * Device configuration object for the SRv6 srv6_usid application.
 */
public class Srv6DeviceConfig extends Config<DeviceId> {

    public static final String CONFIG_KEY = "srv6DeviceConfig";
    private static final String MY_STATION_MAC = "myStationMac";
    private static final String MY_USID = "uN";
    private static final String MY_UDX = "uDX";
    private static final String MY_UDX4 = "uDX4";
    private static final String MY_UGTP4D = "uGTP4D";
    private static final String MY_UGTP4E = "uGTP4E";
    private static final String MY_UMUPE = "uMUPE";
    private static final String IS_CORE = "isCore";

    @Override
    public boolean isValid() {
        return myStationMac() != null &&
                    myUSid() != null;
    }

    /**
     * Gets the MAC address of the switch.
     *
     * @return MAC address of the switch. Or null if not configured.
     */
    public MacAddress myStationMac() {
        String mac = get(MY_STATION_MAC, null);
        return mac != null ? MacAddress.valueOf(mac) : null;
    }

    /**
     * Gets the SRv6 micro segment ID (uSID) of the switch.
     *
     * @return IP microSID address of the router. Or null if not configured.
     */
    public Ip6Address myUSid() {
        String ip = get(MY_USID, null);
        return ip != null ? Ip6Address.valueOf(ip) : null;
    }

    /**
     * Gets the SRv6 uDX instruction of the switch.
     *
     * @return uDX instruction of the router. Or null if not configured.
     */
    public Ip6Address myUDX() {
        String uDX = get(MY_UDX, null);
        return uDX != null ? Ip6Address.valueOf(uDX) : null;
    }

    /**
     * Gets the SRv6 uDX instruction of the switch.
     *
     * @return uDX instruction of the router. Or null if not configured.
     */
    public Ip6Address myUDX4() {
        String uDX4 = get(MY_UDX4, null);
        return uDX4 != null ? Ip6Address.valueOf(uDX4) : null;
    }

    /**
     * Gets the SRv6 uDX instruction of the switch.
     *
     * @return uDX instruction of the router. Or null if not configured.
     */
    public Ip6Address myUGTP4D() {
        String uGTP4D = get(MY_UGTP4D, null);
        return uGTP4D != null ? Ip6Address.valueOf(uGTP4D) : null;
    }


    /**
     * Gets the SRv6 uDX instruction of the switch.
     *
     * @return uDX instruction of the router. Or null if not configured.
     */
    public Ip6Address myUGTP4E() {
        String uGTP4E = get(MY_UGTP4E, null);
        return uGTP4E != null ? Ip6Address.valueOf(uGTP4E) : null;
    }

    /**
     * Gets the SRv6 uDX instruction of the switch.
     *
     * @return uDX instruction of the router. Or null if not configured.
     */
    public Ip6Address myUMUPE() {
        String uMUPE = get(MY_UMUPE, null);
        return uMUPE != null ? Ip6Address.valueOf(uMUPE) : null;
    }
    /**
     * Checks if the switch is a core switch.
     *
     * @return true if the switch is a core switch. false if the switch is not
     * a core switch, or if the value is not configured.
     */
    public boolean isCore() {
        String isCore = get(IS_CORE, null);
        return isCore != null && Boolean.valueOf(isCore);
    }

}
