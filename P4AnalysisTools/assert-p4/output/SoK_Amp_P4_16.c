#define BITSLICE(x, a, b) ((x) >> (b)) & ((1 << ((a)-(b)+1)) - 1)
#include<stdio.h>
#include<stdint.h>
#include<stdlib.h>
#include<assert.h>

int assert_forward = 1;
int action_run;

void end_assertions();


void start();
void parse_ipv4();
void parse_tcp();
void accept();
void reject();

typedef struct {
	uint32_t ingress_port : 9;
	uint32_t egress_spec : 9;
	uint32_t egress_port : 9;
	uint32_t instance_type : 32;
	uint32_t packet_length : 32;
	uint32_t enq_timestamp : 32;
	uint32_t enq_qdepth : 19;
	uint32_t deq_timedelta : 32;
	uint32_t deq_qdepth : 19;
	uint64_t ingress_global_timestamp : 48;
	uint64_t egress_global_timestamp : 48;
	uint32_t mcast_grp : 16;
	uint32_t egress_rid : 16;
	uint8_t checksum_error : 1;
	error parser_error;
	uint8_t priority : 3;
} standard_metadata_t;

void mark_to_drop() {
	assert_forward = 0;
	end_assertions();
	exit(0);
}

void mark_to_drop() {
	assert_forward = 0;
	end_assertions();
	exit(0);
}

typedef struct {
	uint8_t isValid : 1;
	uint64_t dstAddr : 48;
	uint64_t srcAddr : 48;
	uint32_t etherType : 16;
} ethernet_t;

typedef struct {
	uint8_t isValid : 1;
	uint8_t version : 4;
	uint8_t ihl : 4;
	uint8_t diffserv : 8;
	uint32_t totalLen : 16;
	uint32_t identification : 16;
	uint8_t flags : 3;
	uint32_t fragOffset : 13;
	uint8_t ttl : 8;
	uint8_t protocol : 8;
	uint32_t hdrChecksum : 16;
	uint32_t srcAddr : 32;
	uint32_t dstAddr : 32;
} ipv4_t;

typedef struct {
	uint8_t isValid : 1;
	uint32_t sport : 16;
	uint32_t dport : 16;
	uint32_t seq : 32;
	uint32_t ack : 32;
	uint8_t dataOffset : 4;
	uint8_t reserved : 3;
	uint32_t flags : 9;
	uint32_t windowSize : 16;
	uint32_t checksum : 16;
	uint32_t urgPtr : 16;
} tcp_t;

typedef struct {
	ethernet_t ethernet;
	ipv4_t ipv4;
	tcp_t tcp;
} headers_t;

typedef struct {
	uint8_t do_recirc : 1;
} metadata_t;

headers_t hdr;
metadata_t meta;
standard_metadata_t standard_metadata;


void start() {
	//Extract hdr.ethernet
	hdr.ethernet.isValid = 1;
	if((hdr.ethernet.etherType == 2048)){
		parse_ipv4();
	} else {
		accept();
	}
}


void parse_ipv4() {
	//Extract hdr.ipv4
	hdr.ipv4.isValid = 1;
	if((hdr.ipv4.protocol == 6)){
		parse_tcp();
	} else {
		accept();
	}
}


void parse_tcp() {
	//Extract hdr.tcp
	hdr.tcp.isValid = 1;
	accept();
}


void accept() {
	
}


void reject() {
	assert_forward = 0;
	end_assertions();
	exit(0);
}


void MyParser() {
	klee_make_symbolic(&hdr, sizeof(hdr), "hdr");
	klee_make_symbolic(&meta, sizeof(meta), "meta");
	klee_make_symbolic(&standard_metadata, sizeof(standard_metadata), "standard_metadata");

	start();
}

//Control

void MyDeparser() {
	//Emit hdr.ethernet
	
	//Emit hdr.ipv4
	
	//Emit hdr.tcp
	
}


//Control

void MyIngress() {
	if(hdr.tcp.isValid();) {
	if((hdr.tcp.dport == 8192)) {
		standard_metadata.egress_spec = 2;
	meta.do_recirc = 0;

} else {
	if((hdr.tcp.dport == 16384)) {
		meta.do_recirc = 1;
	standard_metadata.egress_spec = 1;

} else {
	if((hdr.tcp.dport == 20480)) {
		meta.do_recirc = 1;
	clone_preserving_field_list();
	standard_metadata.egress_spec = 1;

} else {
		hdr.tcp.dport = 12288;
	meta.do_recirc = 0;
	clone_preserving_field_list();
	standard_metadata.egress_spec = 2;

}
}
}
}
}


//Control

void MyEgress() {
	if((meta.do_recirc == 1) && (standard_metadata.instance_type != 1)) {
	recirculate_preserving_field_list();
}
}


//Control

void MyVerifyChecksum() {
	
}


//Control

void MyComputeChecksum() {
	
}


int main() {
	MyParser();
	MyIngress();
	MyEgress();
	MyDeparser();
	end_assertions();
	return 0;
}

assert_error(char msg[]) {
	printf("Assertion Error: %s", msg);
	klee_abort();
}

void end_assertions(){
}



