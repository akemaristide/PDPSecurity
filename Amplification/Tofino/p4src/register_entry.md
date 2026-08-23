% Configure mirror session from control plane
bfrt.mirror.cfg.add_with_normal(sid=5, session_enable=True, direction = "BOTH", ucast_egress_port = 4, ucast_egress_port_valid = True, max_pkt_len=16384)
