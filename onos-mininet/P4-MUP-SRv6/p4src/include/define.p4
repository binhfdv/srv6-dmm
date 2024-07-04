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

#ifndef __DEFINE__
#define __DEFINE__
#define ETH_HDR_SIZE 14
#define IPV4_HDR_SIZE 20
#define IPV4_MIN_IHL 5
#define UDP_HDR_SIZE 8
#define GTP_HDR_MIN_SIZE 8
#define GTPU_OPTIONS_HDR_BYTES 4
#define GTPU_EXT_PSC_HDR_BYTES 4

#define UDP_PORT_GTP 2152

typedef bit<9>   port_num_t;
typedef bit<48>  mac_addr_t;
typedef bit<16>  group_id_t;
typedef bit<32>  ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<16>  l4_port_t;

const bit<16> ETHERTYPE_IPV4 = 0x0800;
const bit<16> ETHERTYPE_IPV6 = 0x86dd;
const bit<16> ETHERTYPE_ARP  = 0x0806;

const bit<8> PROTO_ICMP = 1;
const bit<8> PROTO_TCP = 6;
const bit<8> PROTO_UDP = 17;
const bit<8> PROTO_SRV6 = 43;
const bit<8> PROTO_ICMPV6 = 58;
const bit<8> PROTO_IPV6 = 41;
const bit<8> PROTO_IP_IN_IP = 4;

enum bit<8> GTPUMessageType {
    GPDU = 255
}
const bit<4> IP_VERSION_4 = 4;
const bit<8> DEFAULT_IPV4_TTL = 64;

enum bit<16> L4Port {
    DHCP_SERV       = 67, // naming this DHCP_SERVER causes a syntax error..
    DHCP_CLIENT     = 68,
    GTP_GPDU        = 2152,
    IPV4_IN_UDP     = 9875 // placeholder. port has not yet been assigned by IANA
}


typedef bit<32> teid_t;
const bit<16> UDP_PORT_GTPU = 2152;
const bit<3> GTP_V1 = 0x1;
const bit<1> GTP_PROTOCOL_TYPE_GTP = 0x1;
const bit<8> GTP_MESSAGE_TYPE_UPDU = 0xff;
const bit<8> GTPU_NEXT_EXT_NONE = 0x0;
const bit<8> GTPU_NEXT_EXT_PSC = 0x85;
const bit<4> GTPU_EXT_PSC_TYPE_DL = 4w0; // Downlink
const bit<4> GTPU_EXT_PSC_TYPE_UL = 4w1; // Uplink
const bit<8> GTPU_EXT_PSC_LEN = 8w1; // 1*4-octets

const bit<8> ICMP6_TYPE_NS = 135;
const bit<8> ICMP6_TYPE_NA = 136;
const bit<8> NDP_OPT_TARGET_LL_ADDR = 2;
const mac_addr_t IPV6_MCAST_01 = 0x33_33_00_00_00_01;
const bit<32> NDP_FLAG_ROUTER = 0x80000000;
const bit<32> NDP_FLAG_SOLICITED = 0x40000000;
const bit<32> NDP_FLAG_OVERRIDE = 0x20000000;
#endif