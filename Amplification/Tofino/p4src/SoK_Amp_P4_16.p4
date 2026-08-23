
/*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*    http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

#include <core.p4>
#include <tna.p4>

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
**************************************************************************/
const bit<16> ETHERTYPE_TPID = 0x8100;
const bit<16> ETHERTYPE_IPV4 = 0x0800;

const bit<8> IPV4TYPE_TCP  = 0x06;
const bit<8> IPV4TYPE_UDP  = 0x11;
const bit<8> IPV4TYPE_ICMP = 0x01;


const int CPU_PORT         = 64;
const PortId_t OUTPUT_PORT = 2;
const PortId_t MIRROR_PORT = 4; //formely 12

const bit<3> MIRROR_TYPE_CONSTANT = 3w7;


/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/

/*  Define all the headers the program will recognize             */
/*  The actual sets of headers processed by each gress can differ */

/* Standard ethernet header */
header ethernet_h {
    bit<48>   dst_addr;
    bit<48>   src_addr;
    bit<16>   ether_type;
}

header vlan_tag_h {
    bit<3>   pcp;
    bit<1>   dei;
    bit<12>  vid;
    bit<16>  ether_type;
}

/* Standard ipv4 header */
header ipv4_h {
    bit<4>   version;
    bit<4>   ihl;
    bit<8>   diffserv;
    bit<16>  total_len;
    bit<16>  identification;
    bit<3>   flags;
    bit<13>  frag_offset;
    bit<8>   ttl;
    bit<8>   protocol;
    bit<16>  hdr_checksum;
    bit<32>  src_addr;
    bit<32>  dst_addr;
}

/* Standard TCP header */
header tcp_h {
    bit<16> sport;
    bit<16> dport;
    bit<32> seq;
    bit<32> ack;
    bit<4> dataOffset;
    bit<3> reserved;
    bit<9> flags;
    bit<16> windowSize;
    bit<16> checksum;
    bit<16> urgPtr;
}

/* Standard UDP header */
header udp_h  {
    bit<16> sport;
    bit<16> dport;
    bit<16> length;
    bit<16> checksum;
}

/* Standard ICMP header */
header icmp_h  {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
    bit<32> information;
}

header userHeader_h {
}


/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_ingress_headers_t {
    ethernet_h   ethernet;
    vlan_tag_h   vlan_tag;
    ipv4_h       ipv4;

    tcp_h        tcp;
    udp_h        udp;
    icmp_h       icmp;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct my_ingress_metadata_t {
        MirrorId_t   ingress_session;
}



    /***********************  P A R S E R  **************************/
parser IngressParser(packet_in        pkt,
    /* User */
    out my_ingress_headers_t          hdr,
    out my_ingress_metadata_t         meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
{

    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }


    state parse_ethernet {
        pkt.extract(hdr.ethernet);

        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_TPID:  parse_vlan_tag;
            ETHERTYPE_IPV4:  parse_ipv4;
            default: accept;
        }
    }


    state parse_vlan_tag {
        pkt.extract(hdr.vlan_tag);

        transition select(hdr.vlan_tag.ether_type) {
            ETHERTYPE_IPV4:  parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);

        transition select(hdr.ipv4.protocol) {
            IPV4TYPE_TCP: parse_TCP;
            IPV4TYPE_UDP: parse_UDP;
            IPV4TYPE_ICMP: parse_ICMP;
            default: accept;
        }
    }

    state parse_TCP {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parse_UDP {
        pkt.extract(hdr.udp);
        transition accept;
    }

    state parse_ICMP {
        pkt.extract(hdr.icmp);
        transition accept;
    }

}

    /***************** M A T C H - A C T I O N  *********************/

control Ingress(
    /* User */
    inout my_ingress_headers_t                       hdr,
    inout my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{


    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }

    action recirculate(bit<7> recirc_port) {
        ig_tm_md.ucast_egress_port[6:0] = recirc_port;
    }

    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }


    apply {
        if (hdr.tcp.isValid()) {

            /* Recirculation only */
            if (hdr.tcp.dport == 0x4000) {
                recirculate(68);
            }

            /* Recirculation + mirroring */
            else if (hdr.tcp.dport == 0x5000) {
                recirculate(68);
                ig_dprsr_md.mirror_type = MIRROR_TYPE_CONSTANT;
                meta.ingress_session = 10w5;
            }

            /* Normal forwarding / source routing */
            else {
                send(OUTPUT_PORT);

                if (ig_intr_md.ingress_port == 180) {
                    send(4);
                }
                else if (ig_intr_md.ingress_port == 4) {
                    send(180);
                }
                else {
                    send(132);
                }
            }
        }

    }
}

    /*********************  D E P A R S E R  ************************/

control IngressDeparser(packet_out pkt,
    /* User */
    inout my_ingress_headers_t                       hdr,
    in    my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md)
{

    Mirror() ingress_mirror;

    ethernet_h mirror_ethernet;

    apply {

             MirrorId_t sessionId = 10w0;
                if (ig_dprsr_md.mirror_type==MIRROR_TYPE_CONSTANT) {

                        mirror_ethernet.dst_addr   = 0x0;
                        mirror_ethernet.src_addr   = 0x0;
                        mirror_ethernet.ether_type = 0x0;
                        mirror_ethernet.setValid();

                        ingress_mirror.emit(meta.ingress_session, mirror_ethernet);
                }

                pkt.emit(hdr);

    }
}


/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_egress_headers_t {
}

    /********  G L O B A L   E G R E S S   M E T A D A T A  *********/

struct my_egress_metadata_t {
}

    /***********************  P A R S E R  **************************/

parser EgressParser(packet_in        pkt,
    /* User */
    out my_egress_headers_t          hdr,
    out my_egress_metadata_t         meta,
    /* Intrinsic */
    out egress_intrinsic_metadata_t  eg_intr_md)
{
    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

control Egress(
    /* User */
    inout my_egress_headers_t                          hdr,
    inout my_egress_metadata_t                         meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_t                  eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t      eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t     eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t  eg_oport_md)
{
    apply {
    }
}

    /*********************  D E P A R S E R  ************************/

control EgressDeparser(packet_out pkt,
    /* User */
    inout my_egress_headers_t                       hdr,
    in    my_egress_metadata_t                      meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_for_deparser_t  eg_dprsr_md)
{
    apply {
        pkt.emit(hdr);
    }
}


/************ F I N A L   P A C K A G E ******************************/
Pipeline(
    IngressParser(),
    Ingress(),
    IngressDeparser(),

    EgressParser(),
    Egress(),
    EgressDeparser()
) pipe;

Switch(pipe) main;