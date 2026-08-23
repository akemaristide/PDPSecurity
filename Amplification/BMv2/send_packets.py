#!/usr/bin/env python3
import argparse
from scapy.all import Ether, IP, TCP, sendp

def main():
    parser = argparse.ArgumentParser(
        description="Send TCP packet with specific destination port for BMv2 test."
    )
    parser.add_argument(
        "-p",
        type=int,
        choices=[2, 3, 4, 5],
        default=3,
        help="Port identifier (2 -> 0x2000, 4 -> 0x4000, 5 -> 0x5000; default: 3 -> 0x3000)"
    )
    
    args = parser.parse_args()

    # Maps p=2 to 0x2000, p=3 to 0x3000, etc.
    dport_val = args.p * 0x1000

    # Build Ethernet / IP / TCP packet
    pkt = Ether(dst="ff:ff:ff:ff:ff:ff") / IP(dst="10.0.0.2") / TCP(dport=dport_val, sport=1234)

    print(f"Sending packet on interface 'eth0' with TCP dport = {hex(dport_val)} ({dport_val})...")
    sendp(pkt, iface="eth0", verbose=True)

if __name__ == "__main__":
    main()