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

#ifndef __HEADER__
#define __HEADER__

#include "define.p4"

#define MAX_HOPS 5

@controller_header("packet_in")
header packet_in_header_t {
    port_num_t ingress_port;
    bit<7> _pad;
}

@controller_header("packet_out")
header packet_out_header_t {
    port_num_t egress_port;
    bit<7> _pad;
}

header ethernet_t {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header ipv4_t {
    bit<4> version;
    bit<4> ihl;
    bit<6> dscp;
    bit<2> ecn;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    bit<32> src_addr;
    bit<32> dst_addr;
}

header ipv6_t {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    bit<8> next_hdr;
    bit<8> hop_limit;
    bit<128> src_addr;
    bit<128> dst_addr;
}

header srv6h_t {
    bit<8> next_hdr;
    bit<8> hdr_ext_len;
    bit<8> routing_type;
    bit<8> segment_left;
    bit<8> last_entry;
    bit<8> flags;
    bit<16> tag;
}

header srv6_list_t {
    bit<128> segment_id;
}

header arp_t {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;
}

header tcp_t {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4>  data_offset;
    bit<3>  res;
    bit<3>  ecn;
    bit<6>  ctrl;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_t {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> len;
    bit<16> checksum;
}

header icmp_t {
    bit<8> type;
    bit<8> icmp_code;
    bit<16> checksum;
    bit<16> identifier;
    bit<16> sequence_number;
    bit<64> timestamp;
}

header icmpv6_t {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
}

header ndp_t {
    bit<32> flags;
    bit<128> target_addr;
}

header ndp_option_t {
    bit<8> type;
    bit<8> length;
    bit<48> value;
}


header gtpu_t {
    bit<3>          version;    /* version */
    bit<1>          pt;         /* protocol type */
    bit<1>          spare;      /* reserved */
    bit<1>          ex_flag;    /* next extension hdr present? */
    bit<1>          seq_flag;   /* sequence no. */
    bit<1>          npdu_flag;  /* n-pdn number present ? */
    GTPUMessageType msgtype;    /* message type */
    bit<16>         msglen;     /* message length */
    teid_t          teid;       /* tunnel endpoint id */
}

// Follows gtpu_t if any of ex_flag, seq_flag, or npdu_flag is 1.
header gtpu_options_t {
    bit<16> seq_num;   /* Sequence number */
    bit<8>  n_pdu_num; /* N-PDU number */
    bit<8>  next_ext;  /* Next extension header */
}

// GTPU extension: PDU Session Container (PSC) -- 3GPP TS 38.415 version 15.2.0
// https://www.etsi.org/deliver/etsi_ts/138400_138499/138415/15.02.00_60/ts_138415v150200p.pdf
header gtpu_ext_psc_t {
    bit<8> len;      /* Length in 4-octet units (common to all extensions) */
    bit<4> type;     /* Uplink or downlink */
    bit<4> spare0;   /* Reserved */
    bit<1> ppp;      /* Paging Policy Presence (UL only, not supported) */
    bit<1> rqi;      /* Reflective QoS Indicator (UL only) */
    bit<6> qfi;      /* QoS Flow Identifier */
    bit<8> next_ext;
}

//Custom metadata definition
struct local_metadata_t {
    bool is_multicast;
    bool skip_l2;
    bool xconnect;
    ipv6_addr_t next_srv6_sid;
    ipv6_addr_t ua_next_hop;
    bit<8> ip_proto;
    bit<8> icmp_type;
    l4_port_t l4_src_port;
    l4_port_t l4_dst_port;
    bool ipv4_update;
}

struct parsed_headers_t {
    ethernet_t ethernet;
    ipv4_t outer_ipv4;
    udp_t outer_udp;
    ipv6_t ipv6;
    ipv6_t ipv6_inner;
    ipv4_t ipv4;
    srv6h_t srv6h;
    srv6_list_t[MAX_HOPS] srv6_list;
    arp_t arp;
    tcp_t tcp;
    udp_t udp;
    ////
    gtpu_t outer_gtpu;
    gtpu_options_t outer_gtpu_options;
    gtpu_ext_psc_t outer_gtpu_ext_psc;
    ////
    gtpu_t gtpu;
    gtpu_options_t gtpu_options;
    gtpu_ext_psc_t gtpu_ext_psc;
    ipv4_t inner_ipv4;
    udp_t inner_udp;
    tcp_t inner_tcp;
    icmp_t inner_icmp;
    ////
    icmp_t icmp;
    icmpv6_t icmpv6;
    ndp_t ndp;
    ndp_option_t ndp_option;
    packet_out_header_t packet_out;
    packet_in_header_t packet_in;
}

#endif