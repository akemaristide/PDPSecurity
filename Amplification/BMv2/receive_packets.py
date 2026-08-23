#!/usr/bin/env python3
import argparse
import socket
import sys
import time

def main():
    parser = argparse.ArgumentParser(
        description="Monitor packet reception rate and calculate amplification factor on h3."
    )
    parser.add_argument(
        "-i", "--interface",
        default="eth0",
        help="Interface to listen on (default: eth0)"
    )
    parser.add_argument(
        "-s", "--interval",
        type=float,
        default=1.0,
        help="Reporting interval in seconds (default: 1.0)"
    )
    args = parser.parse_args()

    # Create raw socket bound to all protocol types
    try:
        sock = socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.ntohs(0x0003))
        sock.bind((args.interface, 0))
    except PermissionError:
        print("Error: Root privileges required. Run with 'sudo'.", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error opening socket on {args.interface}: {e}", file=sys.stderr)
        sys.exit(1)

    print(f"Monitoring incoming traffic on '{args.interface}'...")
    print("Press Ctrl+C to stop and view overall summary.\n")
    print(f"{'Elapsed (s)':<12}{'Packets/sec':<15}{'Bandwidth (Mbps)':<18}{'Total Packets':<15}")
    print("-" * 60)

    total_packets = 0
    total_bytes = 0
    interval_packets = 0
    interval_bytes = 0

    start_time = time.time()
    last_report_time = start_time

    try:
        while True:
            raw_data, _ = sock.recvfrom(65535)
            pkt_len = len(raw_data)

            total_packets += 1
            total_bytes += pkt_len
            interval_packets += 1
            interval_bytes += pkt_len

            now = time.time()
            elapsed_interval = now - last_report_time

            if elapsed_interval >= args.interval:
                pps = interval_packets / elapsed_interval
                mbps = (interval_bytes * 8) / (elapsed_interval * 1e6)
                elapsed_total = now - start_time

                print(f"{elapsed_total:<12.1f}{pps:<15.2f}{mbps:<18.2f}{total_packets:<15}")

                interval_packets = 0
                interval_bytes = 0
                last_report_time = now

    except KeyboardInterrupt:
        end_time = time.time()
        duration = end_time - start_time
        avg_pps = total_packets / duration if duration > 0 else 0
        avg_mbps = (total_bytes * 8) / (duration * 1e6) if duration > 0 else 0

        print("\n" + "=" * 60)
        print("FINAL AMPLIFICATION SUMMARY")
        print("=" * 60)
        print(f"Total Duration      : {duration:.2f} seconds")
        print(f"Total Packets Recv  : {total_packets}")
        print(f"Total Data Recv     : {total_bytes / 1e6:.2f} MB")
        print(f"Average Packet Rate : {avg_pps:.2f} pkts/sec")
        print(f"Average Throughput  : {avg_mbps:.2f} Mbps")
        print(f"Amplification Ratio : {total_packets}:1 (Received per 1 attack packet)")
        print("=" * 60)

if __name__ == "__main__":
    main()