#include <core.p4>
#include <v1model.p4>

/*************************************************************************
 * 1. HEADERS & METADATA
 *************************************************************************/
header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header tcp_t {
    bit<16> sport;
    bit<16> dport;
    bit<32> seq;
    bit<32> ack;
    bit<4>  dataOffset;
    bit<3>  reserved;
    bit<9>  flags;
    bit<16> windowSize;
    bit<16> checksum;
    bit<16> urgPtr;
}

struct headers_t {
    ethernet_t ethernet;
    ipv4_t     ipv4;
    tcp_t      tcp;
}

struct metadata_t {
    @field_list(1)
    bit<1> do_recirc;
}

/*************************************************************************
 * 2. PARSER & DEPARSER
 *************************************************************************/
parser MyParser(packet_in pkt,
                out headers_t hdr,
                inout metadata_t meta,
                inout standard_metadata_t standard_metadata) {
    state start {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            0x0800: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            6: parse_tcp;
            default: accept;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }
}

control MyDeparser(packet_out pkt, in headers_t hdr) {
    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.tcp);
    }
}

/*************************************************************************
 * 3. INGRESS PROCESSING
 *************************************************************************/
control MyIngress(inout headers_t hdr,
                  inout metadata_t meta,
                  inout standard_metadata_t standard_metadata) {
    apply {
        if (hdr.tcp.isValid()) {
            if (hdr.tcp.dport == 0x2000) {
                // Forward normally out port 2
                standard_metadata.egress_spec = (bit<9>)2;
                meta.do_recirc = 0;
            }
            else if (hdr.tcp.dport == 0x4000) {
                // Recirculate only
                meta.do_recirc = 1;
                standard_metadata.egress_spec = (bit<9>)1;
            }
            else if (hdr.tcp.dport == 0x5000) {
                // Mirror clone + recirculate original packet
                meta.do_recirc = 1;
                clone_preserving_field_list(
                    CloneType.I2E,
                    (bit<32>)5,
                    1
                );
                standard_metadata.egress_spec = (bit<9>)1;
            }
            else {
                hdr.tcp.dport = 0x3000;
                meta.do_recirc = 0;
                clone_preserving_field_list(
                    CloneType.I2E,
                    (bit<32>)5,
                    1
                );
                standard_metadata.egress_spec = (bit<9>)2;
            }
        }
    }
}

/*************************************************************************
 * 4. EGRESS PROCESSING
 *************************************************************************/
control MyEgress(inout headers_t hdr,
                 inout metadata_t meta,
                 inout standard_metadata_t standard_metadata) {
    apply {
        // Only recirculate the original pipeline packet, not the cloned mirror copy
        // PKT_INSTANCE_TYPE_INGRESS_CLONE is instance_type 1 in BMv2
        if (meta.do_recirc == 1 && standard_metadata.instance_type != 1) {
            recirculate_preserving_field_list(1);
        }
    }
}

/*************************************************************************
 * 5. UNUSED CONTROLS & PIPELINE
 *************************************************************************/
control MyVerifyChecksum(inout headers_t hdr, inout metadata_t meta) { apply {} }
control MyComputeChecksum(inout headers_t hdr, inout metadata_t meta) { apply {} }

V1Switch(
    MyParser(),
    MyVerifyChecksum(),
    MyIngress(),
    MyEgress(),
    MyComputeChecksum(),
    MyDeparser()
) main;
