# ipv4 pkt. send from physical port. mirror copy at vsi=1, original copy at vsi=6
sendp(Ether(dst="00:00:00:00:09:21", src="9e:ba:ce:98:d9:d3")/IP(src="198.169.1.201", dst="198.169.1.198")/UDP(sport=1000, dport=2000)/Raw(load="0"*50), iface='ens5f0np0')

# ipv4 pkt. send from any VSI interface, mirror copy at vsi=1, original copy at physical port=1
sendp(Ether(dst="00:00:00:00:09:22", src="9e:ba:ce:98:d9:d3")/IP(src="198.169.1.201", dst="198.169.1.198")/UDP(sport=1000, dport=2000)/Raw(load="0"*50), iface='ens2f0d2')

# ipv4 pkt. send from any VSI interface, mirror copy at vsi=1, original copy at physical port=1
sendp(Ether(dst="00:00:00:00:09:23", src="9e:ba:ce:98:d9:d3")/IP(src="198.169.1.201", dst="198.169.1.198")/UDP(sport=1000, dport=2000)/Raw(load="0"*50), iface='eth2')
