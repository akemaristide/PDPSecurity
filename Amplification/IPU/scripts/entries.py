# dest_id ( vsi_id) should be equal to vport_id
tdi.Amplification.main.my_control.mir_prof.add(mir_prof_key=19, vport_id=1, port_dest_type=0, dest_id=1, func_valid=1, store_vsi=1)
tdi.Amplification.main.my_control.mir_prof.add(mir_prof_key=20, vport_id=1, port_dest_type=0, dest_id=1, func_valid=1, store_vsi=1)

# Mirroring based on src_address and dest_address
from netaddr import IPAddress
tdi.Amplification.main.my_control.l3_l4_match.add_with_mirror_and_send(mirror_session_id=19, protocol = 0x11, protocol_mask = 0x00, src_ip=IPAddress('198.169.1.0'),src_ip_mask=IPAddress('0.0.0.0'),dst_ip=IPAddress('198.169.1.0'),dst_ip_mask=IPAddress('0.0.0.0'), da=0x00000000921 , da_mask = 0xffffffffffff, sa = 0x9ebace98d9d3, sa_mask = 0xffffffffffff,  MATCH_PRIORITY=53)
tdi.Amplification.main.my_control.l3_l4_match.add_with_mirror_and_send(mirror_session_id=19, protocol = 0x11, protocol_mask = 0x00, src_ip=IPAddress('198.169.1.0'),src_ip_mask=IPAddress('0.0.0.0'),dst_ip=IPAddress('198.169.1.0'),dst_ip_mask=IPAddress('0.0.0.0'), da=0x00000000922 , da_mask = 0xffffffffffff, sa = 0x9ebace98d9d3, sa_mask = 0xffffffffffff,  MATCH_PRIORITY=54)

# case-1 RX local mirroring :
# Rule ADD
tdi.Amplification.main.my_control.l2_fwd_rx.add_with_send(da=0x00000000921, port=27)
tdi.Amplification.main.my_control.l2_fwd_rx.add_with_mirror_and_forward(da=0x00000000921, port=27)

# case-2 TX Only local mirroring 
# Rule ADD
tdi.Amplification.main.my_control.l2_fwd_tx.add_with_send(da=0x00000000922, port=1)
tdi.Amplification.main.my_control.l2_fwd_tx.add_with_mirror_and_forward(da=0x00000000922, port=1)


