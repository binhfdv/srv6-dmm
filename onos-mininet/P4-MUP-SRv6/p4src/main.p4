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

#include <core.p4>
#include <v1model.p4>

#include "include/header.p4"
#include "include/parser.p4"
#include "include/checksum.p4"

#define CPU_CLONE_SESSION_ID 99
#define UN_BLOCK_MASK     0xffffffff000000000000000000000000


control IngressPipeImpl (inout parsed_headers_t hdr,
                         inout local_metadata_t local_metadata,
                         inout standard_metadata_t standard_metadata) {

    action drop() {
        mark_to_drop(standard_metadata);
    }

    action set_output_port(port_num_t port_num) {
        standard_metadata.egress_spec = port_num;
    }
    action set_multicast_group(group_id_t gid) {
        standard_metadata.mcast_grp = gid;
        local_metadata.is_multicast = true;
    }

    direct_counter(CounterType.packets_and_bytes) unicast_counter; 
    table unicast {
        key = {
            hdr.ethernet.dst_addr: exact; 
        }
        actions = {
            set_output_port;
            drop;
            NoAction;
        }
        counters = unicast_counter;
        default_action = NoAction();
    }

    direct_counter(CounterType.packets_and_bytes) multicast_counter;
    table multicast {
        key = {
            hdr.ethernet.dst_addr: ternary;
        }
        actions = {
            set_multicast_group;
            drop;
        }
        counters = multicast_counter;
        const default_action = drop;
    }

    direct_counter(CounterType.packets_and_bytes) l2_firewall_counter;
    table l2_firewall {
	    key = {
	        hdr.ethernet.dst_addr: exact;
	    }
	    actions = {
	        NoAction;
	    }
    	counters = l2_firewall_counter;
    }

    action set_next_hop(mac_addr_t next_hop) {
	    hdr.ethernet.src_addr = hdr.ethernet.dst_addr;
	    hdr.ethernet.dst_addr = next_hop;
	    hdr.ipv6.hop_limit = hdr.ipv6.hop_limit - 1;
    }

    // TODO: implement ecmp with ipv6.src+ipv6.dst+ipv6.flow_label
    action_selector(HashAlgorithm.crc16, 32w64, 32w10) ip6_ecmp_selector;
    direct_counter(CounterType.packets_and_bytes) routing_v6_counter;
    table routing_v6 {
	    key = {
	        hdr.ipv6.dst_addr: lpm;

            hdr.ipv6.flow_label : selector;
            hdr.ipv6.dst_addr : selector;
            hdr.ipv6.src_addr : selector;
	    }
        actions = {
	        set_next_hop;
        }
        counters = routing_v6_counter;
        // implementation = ip6_ecmp_selector;
    }

    // TODO calc checksum
    action set_next_hop_v4(mac_addr_t next_hop) {
        hdr.ethernet.src_addr = hdr.ethernet.dst_addr;
        hdr.ethernet.dst_addr = next_hop;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        local_metadata.ipv4_update = true;
    }

    direct_counter(CounterType.packets_and_bytes) routing_v4_counter;
    table routing_v4 {
        key = {
            hdr.ipv4.dst_addr: lpm;
        }
        actions = {
            set_next_hop_v4;
        }
        counters = routing_v4_counter;
    }

    /*
     * NDP reply table and actions.
     * Handles NDP router solicitation message and send router advertisement to the sender.
     */
    action ndp_ns_to_na(mac_addr_t target_mac) {
        hdr.ethernet.src_addr = target_mac;
        hdr.ethernet.dst_addr = IPV6_MCAST_01;
        bit<128> host_ipv6_tmp = hdr.ipv6.src_addr;
        hdr.ipv6.src_addr = hdr.ndp.target_addr;
        hdr.ipv6.dst_addr = host_ipv6_tmp;
        hdr.icmpv6.type = ICMP6_TYPE_NA;
        hdr.ndp.flags = NDP_FLAG_ROUTER | NDP_FLAG_OVERRIDE;
        hdr.ndp_option.setValid();
        hdr.ndp_option.type = NDP_OPT_TARGET_LL_ADDR;
        hdr.ndp_option.length = 1;
        hdr.ndp_option.value = target_mac;
        hdr.ipv6.next_hdr = PROTO_ICMPV6;
        standard_metadata.egress_spec = standard_metadata.ingress_port;
        local_metadata.skip_l2 = true;
    }

    direct_counter(CounterType.packets_and_bytes) ndp_reply_table_counter;
    table ndp_reply_table {
        key = {
            hdr.ndp.target_addr: exact;
        }
        actions = {
            ndp_ns_to_na;
        }
        counters = ndp_reply_table_counter;
    }

    action srv6_end() {}

    action srv6_usid_un() {
        hdr.ipv6.dst_addr = (hdr.ipv6.dst_addr & UN_BLOCK_MASK) | ((hdr.ipv6.dst_addr << 16) & ~((bit<128>)UN_BLOCK_MASK));
    }

    action srv6_usid_ua(ipv6_addr_t next_hop) {
        hdr.ipv6.dst_addr = (hdr.ipv6.dst_addr & UN_BLOCK_MASK) | ((hdr.ipv6.dst_addr << 32) & ~((bit<128>)UN_BLOCK_MASK));
        local_metadata.xconnect = true;

        local_metadata.ua_next_hop = next_hop;
    }

    action srv6_end_x(ipv6_addr_t next_hop) {
        hdr.ipv6.dst_addr = (hdr.ipv6.dst_addr & UN_BLOCK_MASK) | ((hdr.ipv6.dst_addr << 32) & ~((bit<128>)UN_BLOCK_MASK));
        local_metadata.xconnect = true;

        local_metadata.ua_next_hop = next_hop;
    }

    action srv6_end_dx6() {
        hdr.ipv6.version = hdr.ipv6_inner.version;
        hdr.ipv6.traffic_class = hdr.ipv6_inner.traffic_class;
        hdr.ipv6.flow_label = hdr.ipv6_inner.flow_label;
        hdr.ipv6.payload_len = hdr.ipv6_inner.payload_len;
        hdr.ipv6.next_hdr = hdr.ipv6_inner.next_hdr;
        hdr.ipv6.hop_limit = hdr.ipv6_inner.hop_limit;
        hdr.ipv6.src_addr = hdr.ipv6_inner.src_addr;
        hdr.ipv6.dst_addr = hdr.ipv6_inner.dst_addr;

        hdr.ipv6_inner.setInvalid();
        hdr.srv6h.setInvalid();
        hdr.srv6_list[0].setInvalid();
    }

    action srv6_end_dx4()  {
        hdr.srv6_list[0].setInvalid();
        hdr.srv6h.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.ipv6_inner.setInvalid();

        hdr.ethernet.ether_type = ETHERTYPE_IPV4;
    } 

    action udp_encap(ipv4_addr_t src_addr, ipv4_addr_t dst_addr,
                      bit<16> ipv4_total_len,
                      bit<16> udp_len) {
        hdr.outer_ipv4.setValid();
        hdr.outer_ipv4.version = IP_VERSION_4;
        hdr.outer_ipv4.ihl = IPV4_MIN_IHL;
        hdr.outer_ipv4.dscp = 0;
        hdr.outer_ipv4.ecn = 0;
        hdr.outer_ipv4.total_len = ipv4_total_len;
        hdr.outer_ipv4.identification = 0x1513; // TODO: change this to timestamp or some incremental num
        hdr.outer_ipv4.flags = 0;
        hdr.outer_ipv4.frag_offset = 0;
        hdr.outer_ipv4.ttl = DEFAULT_IPV4_TTL;
        hdr.outer_ipv4.protocol = PROTO_UDP;
        hdr.outer_ipv4.src_addr = src_addr;
        hdr.outer_ipv4.dst_addr = dst_addr;
        hdr.outer_ipv4.hdr_checksum = 0; // Updated later
    

            
            
        hdr.outer_udp.setValid();
        hdr.outer_udp.src_port = 2152;
        hdr.outer_udp.dst_port = 2152;
        hdr.outer_udp.len = udp_len;
        hdr.outer_udp.checksum = 0; // Never updated due to p4 limitations
    }

    action gtpu_encap(teid_t teid) {
        hdr.outer_gtpu.setValid();
        hdr.outer_gtpu.version = GTP_V1;
        hdr.outer_gtpu.pt = GTP_PROTOCOL_TYPE_GTP;
        hdr.outer_gtpu.spare = 0;
        hdr.outer_gtpu.ex_flag = 0;
        hdr.outer_gtpu.seq_flag = 0;
        hdr.outer_gtpu.npdu_flag = 0;
        hdr.outer_gtpu.msgtype = GTPUMessageType.GPDU;
        hdr.outer_gtpu.msglen = hdr.ipv4.total_len;
        hdr.outer_gtpu.teid = teid;
    }

    action srv6_gtp4_e(ipv4_addr_t src_addr, ipv4_addr_t dst_addr, teid_t teid) {
        hdr.srv6_list[0].setInvalid();
        hdr.srv6h.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.ipv6_inner.setInvalid();
        hdr.ethernet.ether_type = ETHERTYPE_IPV4;

        udp_encap(src_addr, dst_addr, 
                   hdr.ipv4.total_len + IPV4_HDR_SIZE + UDP_HDR_SIZE + GTP_HDR_MIN_SIZE
                    + GTPU_OPTIONS_HDR_BYTES + GTPU_EXT_PSC_HDR_BYTES,
                   hdr.ipv4.total_len + UDP_HDR_SIZE + GTP_HDR_MIN_SIZE
                    + GTPU_OPTIONS_HDR_BYTES + GTPU_EXT_PSC_HDR_BYTES);

        gtpu_encap(teid);

        hdr.outer_gtpu.msglen = hdr.ipv4.total_len + GTPU_OPTIONS_HDR_BYTES
                            + GTPU_EXT_PSC_HDR_BYTES; // Override msglen set by _gtpu_encap
        hdr.outer_gtpu.ex_flag = 1; // Override value set by _gtpu_encap
        hdr.outer_gtpu_options.setValid();
        hdr.outer_gtpu_options.seq_num   = 0;
        hdr.outer_gtpu_options.n_pdu_num = 0;
        hdr.outer_gtpu_options.next_ext  = GTPU_NEXT_EXT_PSC;
        hdr.outer_gtpu_ext_psc.setValid();
        hdr.outer_gtpu_ext_psc.len      = GTPU_EXT_PSC_LEN;
        hdr.outer_gtpu_ext_psc.type     = GTPU_EXT_PSC_TYPE_DL;
        hdr.outer_gtpu_ext_psc.spare0   = 0;
        hdr.outer_gtpu_ext_psc.ppp      = 0;
        hdr.outer_gtpu_ext_psc.rqi      = 0;
        hdr.outer_gtpu_ext_psc.qfi      = 0x1;
        hdr.outer_gtpu_ext_psc.next_ext = GTPU_NEXT_EXT_NONE;

    }

    direct_counter(CounterType.packets_and_bytes) srv6_localsid_table_counter;
    table srv6_localsid_table {
        key = {
            hdr.ipv6.dst_addr: lpm;
        }
        actions = {
            srv6_end;
            srv6_end_x; 
            srv6_end_dx6;
            srv6_end_dx4;
            srv6_usid_un;
            srv6_usid_ua;
            srv6_gtp4_e;
            NoAction;
        }
        default_action = NoAction;
        counters = srv6_localsid_table_counter;
    }

    action xconnect_act(mac_addr_t next_hop) {
        hdr.ethernet.src_addr = hdr.ethernet.dst_addr;
        hdr.ethernet.dst_addr = next_hop;
    }

    direct_counter(CounterType.packets_and_bytes) xconnect_table_counter;
    table xconnect_table {
        key = {
            local_metadata.ua_next_hop: lpm;
        }
        actions = {
            xconnect_act;
            NoAction;
        }
        default_action = NoAction;
        counters = xconnect_table_counter;
    }

    action usid_encap_1(ipv6_addr_t src_addr, ipv6_addr_t s1) {
        hdr.ipv6_inner.setValid();

        hdr.ipv6_inner.version = 6;
        hdr.ipv6_inner.traffic_class = hdr.ipv6.traffic_class;
        hdr.ipv6_inner.flow_label = hdr.ipv6.flow_label;
        hdr.ipv6_inner.payload_len = hdr.ipv6.payload_len;
        hdr.ipv6_inner.next_hdr = hdr.ipv6.next_hdr;
        hdr.ipv6_inner.hop_limit = hdr.ipv6.hop_limit;
        hdr.ipv6_inner.src_addr = hdr.ipv6.src_addr;
        hdr.ipv6_inner.dst_addr = hdr.ipv6.dst_addr;

        hdr.ipv6.payload_len = hdr.ipv6.payload_len + 40;
        hdr.ipv6.next_hdr = PROTO_IPV6;
        hdr.ipv6.src_addr = src_addr;
        hdr.ipv6.dst_addr = s1;
    }

    action usid_encap_2(ipv6_addr_t src_addr, ipv6_addr_t s1, ipv6_addr_t s2) {
        hdr.ipv6_inner.setValid();

        hdr.ipv6_inner.version = 6;
        hdr.ipv6_inner.traffic_class = hdr.ipv6.traffic_class;
        hdr.ipv6_inner.flow_label = hdr.ipv6.flow_label;
        hdr.ipv6_inner.payload_len = hdr.ipv6.payload_len;
        hdr.ipv6_inner.next_hdr = hdr.ipv6.next_hdr;
        hdr.ipv6_inner.hop_limit = hdr.ipv6.hop_limit;
        hdr.ipv6_inner.src_addr = hdr.ipv6.src_addr;
        hdr.ipv6_inner.dst_addr = hdr.ipv6.dst_addr;

        hdr.ipv6.payload_len = hdr.ipv6.payload_len + 40 + 24;
        hdr.ipv6.next_hdr = PROTO_SRV6;
        hdr.ipv6.src_addr = src_addr;
        hdr.ipv6.dst_addr = s1;

        hdr.srv6h.setValid();
        hdr.srv6h.next_hdr = PROTO_IPV6;
        hdr.srv6h.hdr_ext_len = 0x2;
        hdr.srv6h.routing_type = 0x4;
        hdr.srv6h.segment_left = 0;
        hdr.srv6h.last_entry = 0;
        hdr.srv6h.flags = 0;
        hdr.srv6h.tag = 0;

        hdr.srv6_list[0].setValid();
        hdr.srv6_list[0].segment_id = s2;
    }

////extend
     action t_m_gtp4_d_sid1(ipv6_addr_t src_addr, ipv6_addr_t s1) {
    
        hdr.ipv6.setValid();

        hdr.ipv6.version = 6;
        hdr.ipv6.traffic_class = hdr.inner_ipv4.dscp ++ hdr.inner_ipv4.ecn; 
        hash(hdr.ipv6.flow_label, 
                HashAlgorithm.crc32, 
                (bit<20>) 0, 
                { 
                    hdr.inner_ipv4.src_addr,
                    hdr.inner_ipv4.dst_addr,
                    local_metadata.ip_proto,
                    local_metadata.l4_src_port,
                    local_metadata.l4_dst_port
                },
                (bit<20>) 1048575);
        hdr.ipv6.payload_len = hdr.inner_ipv4.total_len;
        hdr.ipv6.next_hdr = PROTO_IP_IN_IP;
        hdr.ipv6.hop_limit = hdr.inner_ipv4.ttl;
        hdr.ipv6.src_addr = src_addr;
        hdr.ipv6.dst_addr = s1;

        hdr.ethernet.ether_type = ETHERTYPE_IPV6;

        hdr.gtpu.setInvalid();
        hdr.gtpu_options.setInvalid();
        hdr.gtpu_ext_psc.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.udp.setInvalid();

    }
    direct_counter(CounterType.packets_and_bytes) srv6_transit_udp_table_counter;
    table srv6_transit_udp {
        key = {
            hdr.udp.dst_port : exact;
            hdr.inner_ipv4.dst_addr: lpm; // test opening 2 PEs to 2 MECs

            hdr.ipv4.src_addr: selector;
            hdr.ipv4.dst_addr: selector;
            local_metadata.ip_proto: selector;
            local_metadata.l4_src_port: selector;
            local_metadata.l4_dst_port: selector;
        }
        actions = {
            // SRv6 Mobile Userplane : draft-ietf-dmm-srv6-mobile-uplane
            t_m_gtp4_d_sid1;  // 2 SIDs (DA + sid1)
            NoAction;

   
        }
        default_action = NoAction;
        counters = srv6_transit_udp_table_counter;
    }
///




    direct_counter(CounterType.packets_and_bytes) srv6_encap_table_counter;
    table srv6_encap {
        key = {
           hdr.ipv6.dst_addr: lpm;       
        }
        actions = {
            usid_encap_1;
            usid_encap_2;
            NoAction;
        }
        default_action = NoAction;
        counters = srv6_encap_table_counter;
    }

    action usid_encap_1_v4(ipv6_addr_t src_addr, ipv6_addr_t s1) {
        hdr.ipv6.setValid();

        hdr.ipv6.version = 6;
        hdr.ipv6.traffic_class = hdr.ipv4.dscp ++ hdr.ipv4.ecn; 
        hash(hdr.ipv6.flow_label, 
                HashAlgorithm.crc32, 
                (bit<20>) 0, 
                { 
                    hdr.ipv4.src_addr,
                    hdr.ipv4.dst_addr,
                    local_metadata.ip_proto,
                    local_metadata.l4_src_port,
                    local_metadata.l4_dst_port
                },
                (bit<20>) 1048575);
        hdr.ipv6.payload_len = hdr.ipv4.total_len;
        hdr.ipv6.next_hdr = PROTO_IP_IN_IP;
        hdr.ipv6.hop_limit = hdr.ipv4.ttl;
        hdr.ipv6.src_addr = src_addr;
        hdr.ipv6.dst_addr = s1;

        hdr.ethernet.ether_type = ETHERTYPE_IPV6;
    }

    action usid_encap_mup_v4(ipv6_addr_t src_addr, ipv6_addr_t s1) {
        hdr.ipv6.setValid();

        hdr.ipv6.version = 6;
        hdr.ipv6.traffic_class = hdr.ipv4.dscp ++ hdr.ipv4.ecn; 
        hash(hdr.ipv6.flow_label, 
                HashAlgorithm.crc32, 
                (bit<20>) 0, 
                { 
                    hdr.ipv4.src_addr,
                    hdr.ipv4.dst_addr,
                    local_metadata.ip_proto,
                    local_metadata.l4_src_port,
                    local_metadata.l4_dst_port
                },
                (bit<20>) 1048575);
        hdr.ipv6.payload_len = hdr.ipv4.total_len;
        hdr.ipv6.next_hdr = PROTO_IP_IN_IP;
        hdr.ipv6.hop_limit = hdr.ipv4.ttl;
        hdr.ipv6.src_addr = src_addr;
        hdr.ipv6.dst_addr = s1;

        hdr.ethernet.ether_type = ETHERTYPE_IPV6;
    }

    action usid_encap_2_v4(ipv6_addr_t src_addr, ipv6_addr_t s1, ipv6_addr_t s2) {
        hdr.ipv6.setValid();

        hdr.ipv6.version = 6;
        hdr.ipv6.traffic_class = hdr.ipv4.dscp ++ hdr.ipv4.ecn; 
        hash(hdr.ipv6.flow_label, 
                HashAlgorithm.crc32, 
                (bit<20>) 0, 
                { 
                    hdr.ipv4.src_addr,
                    hdr.ipv4.dst_addr,
                    local_metadata.ip_proto,
                    local_metadata.l4_src_port,
                    local_metadata.l4_dst_port
                },
                (bit<20>) 1048575);        
        hdr.ipv6.payload_len = hdr.ipv4.total_len + 24;
        hdr.ipv6.next_hdr = PROTO_SRV6;
        hdr.ipv6.hop_limit = hdr.ipv4.ttl;
        hdr.ipv6.src_addr = src_addr;
        hdr.ipv6.dst_addr = s1;

        hdr.srv6h.setValid();
        hdr.srv6h.next_hdr = PROTO_IP_IN_IP;
        hdr.srv6h.hdr_ext_len = 0x2;
        hdr.srv6h.routing_type = 0x4;
        hdr.srv6h.segment_left = 0;
        hdr.srv6h.last_entry = 0;
        hdr.srv6h.flags = 0;
        hdr.srv6h.tag = 0;

        hdr.srv6_list[0].setValid();
        hdr.srv6_list[0].segment_id = s2;

        hdr.ethernet.ether_type = ETHERTYPE_IPV6;
    }

    // create one group 
    action_selector(HashAlgorithm.crc16, 32w64, 32w10) ecmp_selector;
    direct_counter(CounterType.packets_and_bytes) srv6_encap_v4_table_counter;
    table srv6_encap_v4 {
        key = {
            hdr.ipv4.dscp: exact;
            hdr.ipv4.dst_addr: lpm;

            hdr.ipv4.src_addr: selector;
            hdr.ipv4.dst_addr: selector;
            local_metadata.ip_proto: selector;
            local_metadata.l4_src_port: selector;
            local_metadata.l4_dst_port: selector;
        }
        actions = {
            usid_encap_1_v4;
            usid_encap_2_v4;
            usid_encap_mup_v4;
            NoAction;
        }
        default_action = NoAction;
        // implementation = ecmp_selector;
        counters = srv6_encap_v4_table_counter;
    }


    /*
     * ACL table  and actions.
     * Clone the packet to the CPU (PacketIn) or drop.
     */

    action clone_to_cpu() {
        clone3(CloneType.I2E, CPU_CLONE_SESSION_ID, standard_metadata);
    }

    direct_counter(CounterType.packets_and_bytes) acl_counter;
    table acl {
        key = {
            standard_metadata.ingress_port: ternary;
            hdr.ethernet.dst_addr: ternary;
            hdr.ethernet.src_addr: ternary;
            hdr.ethernet.ether_type: ternary;
            local_metadata.ip_proto: ternary;
            local_metadata.icmp_type: ternary;
            local_metadata.l4_src_port: ternary;
            local_metadata.l4_dst_port: ternary;
        }
        actions = {
            clone_to_cpu;
            drop;
        }
        counters = acl_counter;
    }

    apply {
        if (hdr.packet_out.isValid()) {
            standard_metadata.egress_spec = hdr.packet_out.egress_port;
            hdr.packet_out.setInvalid();
            exit;
        }
        bool do_l3_l2 = true;
        if (hdr.icmpv6.isValid() && hdr.icmpv6.type == ICMP6_TYPE_NS) {
            if (ndp_reply_table.apply().hit){
                do_l3_l2 = false;
            }
        }

	    if (hdr.ipv6.hop_limit == 0) {
	        drop();
	    }
        bool flag = false;
	    if (l2_firewall.apply().hit) {
            if (!flag){
                switch(srv6_localsid_table.apply().action_run) {
                    srv6_end: {
                        // support for reduced SRH
                        if (hdr.srv6h.segment_left > 0) {
                            // set destination IP address to next segment
                            hdr.ipv6.dst_addr = local_metadata.next_srv6_sid;
                            // decrement segments left
                            hdr.srv6h.segment_left = hdr.srv6h.segment_left - 1;
                        } else {
                            // set destination IP address to next segment
                            hdr.ipv6.dst_addr = hdr.srv6_list[0].segment_id;
                        }
                        flag = true;
                    }
                    srv6_end_dx4:  srv6_gtp4_e: {
                        routing_v4.apply();
                        flag = true;
                    }
                    // srv6_gtp4_e: {
                    //     // routing_v4.apply();
                    //     flag = true;
                    // }
                } 
            } 
            if (!flag){
                if (hdr.ipv4.isValid() && !hdr.ipv6.isValid()) {
                    if (hdr.udp.dst_port == 2152){
                        srv6_transit_udp.apply();
                        
                    }
                    srv6_encap_v4.apply();
                } else {
                    srv6_encap.apply();
                }
            }



            
            if (!local_metadata.xconnect) {
	            routing_v6.apply();
	        } else {
                xconnect_table.apply();
            }
        }
        
	    if (do_l3_l2) {
            if (!unicast.apply().hit) {
       	      	multicast.apply();
	        }	
	    }

        acl.apply();
    
    }
}

control EgressPipeImpl (inout parsed_headers_t hdr,
                        inout local_metadata_t local_metadata,
                        inout standard_metadata_t standard_metadata) {
    apply {
        if (standard_metadata.egress_port == CPU_PORT) {
		    hdr.packet_in.setValid();
		    hdr.packet_in.ingress_port = standard_metadata.ingress_port;		
        }

        if (local_metadata.is_multicast == true
             && standard_metadata.ingress_port == standard_metadata.egress_port) {
            mark_to_drop(standard_metadata);
        }
    }
}

V1Switch(
    ParserImpl(),
    VerifyChecksumImpl(),
    IngressPipeImpl(),
    EgressPipeImpl(),
    ComputeChecksumImpl(),
    DeparserImpl()
) main;
