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

#ifndef __PARSER__
#define __PARSER__

#include "define.p4"

parser ParserImpl (packet_in packet,
                   out parsed_headers_t hdr,
                   inout local_metadata_t local_metadata,
                   inout standard_metadata_t standard_metadata)
{
    state start {
        transition select(standard_metadata.ingress_port) {
            CPU_PORT: parse_packet_out;
            default: parse_ethernet;
        }
    }

    state parse_packet_out {
        packet.extract(hdr.packet_out);
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type){
            ETHERTYPE_ARP: parse_arp;
            ETHERTYPE_IPV4: parse_ipv4;
            ETHERTYPE_IPV6: parse_ipv6;
            default: accept;
        }
    }

    state parse_ipv6 {
        packet.extract(hdr.ipv6);
        local_metadata.ip_proto = hdr.ipv6.next_hdr;
        transition select(hdr.ipv6.next_hdr) {
            PROTO_TCP: parse_tcp;
            PROTO_UDP: parse_udp;
            PROTO_ICMPV6: parse_icmpv6;
            PROTO_SRV6: parse_srv6;
            PROTO_IPV6: parse_ipv6_inner;
            PROTO_IP_IN_IP: parse_ipv4;
            default: accept;
        }
    }

    state parse_srv6 {
        packet.extract(hdr.srv6h);
        transition parse_srv6_list;
    }
    state parse_srv6_list {
        packet.extract(hdr.srv6_list.next);
        bool next_segment = (bit<32>)hdr.srv6h.segment_left - 1 == (bit<32>)hdr.srv6_list.lastIndex;
        transition select(next_segment) {
            true: mark_current_srv6;
            _: check_last_srv6;
        }
    }

    state mark_current_srv6 {
        // current metadata
        local_metadata.next_srv6_sid = hdr.srv6_list.last.segment_id;
        transition check_last_srv6;
    }

    state check_last_srv6 {
        // working with bit<8> and int<32> which cannot be cast directly; using bit<32> as common intermediate type for comparision
        bool last_segment = (bit<32>)hdr.srv6h.last_entry == (bit<32>)hdr.srv6_list.lastIndex;
        transition select(last_segment) {
           true: parse_srv6_next_hdr;
           false: parse_srv6_list;
        }
    }
    state parse_srv6_next_hdr {
        transition select(hdr.srv6h.next_hdr) {
            PROTO_TCP: parse_tcp;
            PROTO_UDP: parse_udp;
            PROTO_ICMPV6: parse_icmpv6;
            PROTO_IPV6: parse_ipv6_inner;
            PROTO_IP_IN_IP: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        local_metadata.ip_proto = hdr.ipv4.protocol;
        //Need header verification?
        transition select(hdr.ipv4.protocol) {
            PROTO_TCP: parse_tcp;
            PROTO_UDP: parse_udp;
            PROTO_ICMP: parse_icmp;
            default: accept;
        }
    }

    state parse_ipv6_inner {
        packet.extract(hdr.ipv6_inner);

        transition select(hdr.ipv6_inner.next_hdr) {
            PROTO_TCP: parse_tcp;
            PROTO_UDP: parse_udp;
            PROTO_ICMPV6: parse_icmpv6;
            PROTO_SRV6: parse_srv6;
            default: accept;
        }
    }

    state parse_arp {
        packet.extract(hdr.arp);
        transition accept;
    }

    state parse_tcp {
        packet.extract(hdr.tcp);
        local_metadata.l4_src_port = hdr.tcp.src_port;
        local_metadata.l4_dst_port = hdr.tcp.dst_port;
        transition accept;
    }
//////////////////////
    state parse_udp {
        packet.extract(hdr.udp);
        local_metadata.l4_src_port = hdr.udp.src_port;
        local_metadata.l4_dst_port = hdr.udp.dst_port;
        transition select(hdr.udp.dst_port) {
            UDP_PORT_GTP: parse_gtpu;
            default: accept;
        }
    }

    state parse_gtpu {
        packet.extract(hdr.gtpu);
        // local_meta.teid = hdr.gtpu.teid;
        transition select(hdr.gtpu.ex_flag, hdr.gtpu.seq_flag, hdr.gtpu.npdu_flag) {
            (0, 0, 0): parse_inner_ipv4;
            default: parse_gtpu_options;
        }
    }

    state parse_gtpu_options {
        packet.extract(hdr.gtpu_options);
        bit<8> gtpu_ext_len = packet.lookahead<bit<8>>();
        transition select(hdr.gtpu_options.next_ext, gtpu_ext_len) {
            (GTPU_NEXT_EXT_PSC, GTPU_EXT_PSC_LEN): parse_gtpu_ext_psc;
            default: accept;
        }
    }

    state parse_gtpu_ext_psc {
        packet.extract(hdr.gtpu_ext_psc);
        transition select(hdr.gtpu_ext_psc.next_ext) {
            GTPU_NEXT_EXT_NONE: parse_inner_ipv4;
            default: accept;
        }
    }
    //-----------------
    // Inner packet
    //-----------------
    state parse_inner_ipv4 {
        packet.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.protocol) {
            PROTO_UDP:  parse_inner_udp;
            PROTO_TCP:  parse_inner_tcp;
            PROTO_ICMP: parse_inner_icmp;
            default: accept;
        }
    }

    state parse_inner_udp {
        packet.extract(hdr.inner_udp);
        // local_meta.l4_sport = hdr.inner_udp.sport;
        // local_meta.l4_dport = hdr.inner_udp.dport;
        transition accept;
    }

    state parse_inner_tcp {
        packet.extract(hdr.inner_tcp);
        // local_meta.l4_sport = hdr.inner_tcp.sport;
        // local_meta.l4_dport = hdr.inner_tcp.dport;
        transition accept;
    }

    state parse_inner_icmp {
        packet.extract(hdr.inner_icmp);
        transition accept;
    }


    state parse_icmp {
        packet.extract(hdr.icmp);
        local_metadata.icmp_type = hdr.icmp.type;
        transition accept;
    }

    state parse_icmpv6 {
        packet.extract(hdr.icmpv6);
        local_metadata.icmp_type = hdr.icmpv6.type;
        transition select(hdr.icmpv6.type) {
            ICMP6_TYPE_NS: parse_ndp;
            ICMP6_TYPE_NA: parse_ndp;
            default: accept;
        }

    }

    state parse_ndp {
        packet.extract(hdr.ndp);
        transition parse_ndp_option;
    }

    state parse_ndp_option {
        packet.extract(hdr.ndp_option);
        transition accept;
    }
}

control DeparserImpl(packet_out packet, in parsed_headers_t hdr) {
    apply {
        packet.emit(hdr.packet_in);
        packet.emit(hdr.ethernet);
        packet.emit(hdr.outer_ipv4);
        packet.emit(hdr.outer_udp);
        packet.emit(hdr.arp);
        packet.emit(hdr.ipv6);
        packet.emit(hdr.srv6h);
        packet.emit(hdr.srv6_list);
        packet.emit(hdr.ipv6_inner);

        ////
        packet.emit(hdr.outer_gtpu);
        packet.emit(hdr.outer_gtpu_options);
        packet.emit(hdr.outer_gtpu_ext_psc);

        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
        packet.emit(hdr.udp);
        ////
        packet.emit(hdr.gtpu);
        packet.emit(hdr.gtpu_options);
        packet.emit(hdr.gtpu_ext_psc);

        packet.emit(hdr.inner_ipv4);
        packet.emit(hdr.inner_udp);
        packet.emit(hdr.inner_tcp);
        packet.emit(hdr.inner_icmp);
        /////
        packet.emit(hdr.icmp);
        packet.emit(hdr.icmpv6);
        packet.emit(hdr.ndp);
        packet.emit(hdr.ndp_option);
        ///

    }
}

#endif