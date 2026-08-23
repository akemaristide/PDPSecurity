header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}
header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr : 32;
    }
}
header_type tcp_t {
    fields {
        sport : 16;
        dport : 16;
        seq : 32;
        ack : 32;
        dataOffset : 4;
        reserved : 3;
        flags : 9;
        windowSize : 16;
        checksum : 16;
        urgPtr : 16;
    }
}
header_type amplification_metadata_t {
    fields {
        do_recirc : 1;
    }
}
header ethernet_t ethernet;
header ipv4_t ipv4;
header tcp_t tcp;
metadata amplification_metadata_t amp_meta;
field_list amplification_fields {
    amp_meta.do_recirc;
}
parser start {
    return parse_ethernet;
}
parser parse_ethernet {
    extract(ethernet);
    return select(ethernet.etherType) {
        0x0800 : parse_ipv4;
        default : ingress;
    }
}
parser parse_ipv4 {
    extract(ipv4);
    return select(ipv4.protocol) {
        0x06 : parse_tcp;
        default : ingress;
    }
}
parser parse_tcp {
    extract(tcp);
    return ingress;
}
action normal_forward() {
    modify_field(standard_metadata.egress_spec, 2);
    modify_field(amp_meta.do_recirc, 0);
}
action recirculate_only() {
    modify_field(amp_meta.do_recirc, 1);
    modify_field(standard_metadata.egress_spec, 1);
}
action amplify() {
    modify_field(amp_meta.do_recirc, 1);
    clone_ingress_pkt_to_egress(5, amplification_fields);
    modify_field(standard_metadata.egress_spec, 1);
}
action default_branch() {
    modify_field(tcp.dport, 0x3000);
    modify_field(amp_meta.do_recirc, 0);
    clone_ingress_pkt_to_egress(5, amplification_fields);
    modify_field(standard_metadata.egress_spec, 2);
}
action do_recirculate() {
    recirculate(amplification_fields);
}
action _nop() {
}
table experiment {
    reads {
        tcp.dport : exact;
    }
    actions {
        normal_forward;
        recirculate_only;
        amplify;
        default_branch;
    }
    size : 4;
}
table recirc_table {
    actions {
        do_recirculate;
        _nop;
    }
    size : 1;
}
control ingress {
    if (valid(tcp)) {
        apply(experiment);
    }
}
control egress {
    if ((amp_meta.do_recirc == 1) and
        (standard_metadata.instance_type != 1)) {
        apply(recirc_table);
    }
}