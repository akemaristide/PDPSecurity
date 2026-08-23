#!/usr/bin/env python
import argparse
import sys
import socket
import random
import struct

from scapy.all import sendp, send, get_if_list, get_if_hwaddr
from scapy.all import Packet, PacketList
from scapy.all import Ether, IP, IPv6, UDP, TCP, ICMP

import numpy
import string
import time

from hardware_python_functions import get_if_new

global packetDPORT;
packetDPORT = 0x1000;

global numToSend
numToSend = 1;


def get_if_2(veth_no):
    veth_no_string = str(veth_no)
    iface = 'veth' + veth_no_string;
    return iface

# FUNCTION TO GET THE INTERFACE RELATED TO eth-0
def get_if():
    interfaceList=get_if_list()

    iface=None # "enp1s0f1np1"

    for i in interfaceList:
        # ONCE WE FIND THE PORT (INTERFACE) THAT IS THE ETHERNET
        # WE CHOOSE THIS AS THE OUTPUT OF THIS FUNCTION
        if "enp1s0f1np1" in i:
            iface=i
            break;

    # THIS PROGRAM IS EXITED AFTER AN ERROR MESSAGE,
    #   IF THE CORRECT INTERFACE IS NOT FOUND
    if not iface:
        print("Cannot find enp1s0f1np1 interface")
        exit(1)

    # RETURNS THE INDEX OF THE ETHERNET OUTPUT INTERFACE
    return iface


def generate_payload(size):
    """Generate a payload of specified size in bytes"""
    if size <= 0:
        return ""
    
    # Create a pattern that's easy to identify in packet captures
    pattern = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    
    # If size is smaller than pattern, just return the needed portion
    if size <= len(pattern):
        return pattern[:size]
    
    # For larger sizes, repeat the pattern
    full_repeats = size // len(pattern)
    remainder = size % len(pattern)
    
    payload = pattern * full_repeats + pattern[:remainder]
    return payload


def main():
    # Check if we have the required arguments
    if len(sys.argv) < 3:
        print("Usage: python sendVariablePackets.py <dport_hex> <num_packets> [payload_size]")
        print("Example: python sendVariablePackets.py 1000 10 64")
        print("  dport_hex: Destination port in hex")
        print("  num_packets: Number of packets to send")
        print("  payload_size: Size of payload in bytes (optional, default: 20)")
        exit(1)

    inputOne = "10.0.2.2"    # THE DESTINATION HOST NAME (THE IP ADDRESS)
    
    # Get payload size from command line argument or use default
    payload_size = 20  # Default payload size
    if len(sys.argv) >= 4:
        payload_size = int(sys.argv[3])
    
    # Generate payload of specified size
    inputTwo = generate_payload(payload_size)

    # gethostbyname() IS A FUNCTION (socket LIBRARY) THAT TAKES THE
    # DESTINATION ADDRESS inputOne AND TRANSLATES IT TO THE IPV4 ADDRESS FORMAT.
    addr = socket.gethostbyname(inputOne)

    packetDPORT = int(sys.argv[1], 16)
    numToSend = int(sys.argv[2])

    iface = get_if_new()
    
    # Create a test packet to calculate sizes
    test_pkt = Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff')
    test_pkt = test_pkt / IP(dst=addr) / TCP(sport=12345, dport=packetDPORT) / inputTwo
    
    total_packet_size = len(test_pkt)
    ip_packet_size = len(test_pkt) - 14  # -14 for the Ethernet Header
    payload_actual_size = len(inputTwo)
    
    print("=== Packet Size Information ===")
    print("Payload size: %d bytes" % payload_actual_size)
    print("IP packet size: %d bytes (IP + TCP + payload)" % ip_packet_size)
    print("Total packet size: %d bytes (Ethernet + IP + TCP + payload)" % total_packet_size)
    print("===============================")
    
    print("sending %d packets on interface %s to %s with dport 0x%x" % (numToSend, iface, str(addr), packetDPORT))
    print("Sending packets at 0.01s intervals...")

    # ETHERNET HEADER
    pkt =  Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff')

    # ADDING IP & TCP HEADERS AND PACKET PAYLOAD
    # TCP dport VALUE COMPARED AT RECEIVING HOST.
    pkt = pkt /IP(dst=addr) / TCP(sport=random.randint(49152,65535), dport=packetDPORT) / inputTwo

    # Send packets one by one with 0.01s intervals
    for i in range(numToSend):
        # Create a fresh packet for each send to avoid scapy issues
        fresh_pkt = Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff')
        fresh_pkt = fresh_pkt / IP(dst=addr) / TCP(sport=random.randint(49152,65535), dport=packetDPORT) / inputTwo
        
        print("Sending packet %d/%d - dport: 0x%x" % (i+1, numToSend, packetDPORT))
        fresh_pkt.show2()
        # sendp(fresh_pkt, iface=iface, verbose=False)
        send(fresh_pkt, iface=iface, verbose=False)
        
        # Wait 0.01s before sending next packet (except for the last one)
        if i < numToSend - 1:
            time.sleep(0.01)

    print('\n%d packets sent successfully.\n' % numToSend)


# THIS ENSURES THE PROGRAM WILL ONLY RUN IF THIS FILE IS CALLED DIRECTLY FROM BASH.
#if __name__ == '__main__':
main()
