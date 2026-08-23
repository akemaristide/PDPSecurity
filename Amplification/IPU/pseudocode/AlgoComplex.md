# Pseudocode for Amplification Attack (Mirroring & Recirculation) on Intel IPU

---

## 1. Parse Packet Headers

- Parse all relevant packet headers (Ethernet, MAC, IPv4, etc.) using the platform's parser logic.

---

## 2. Table and Action Definitions

- **Mirror Profile Table (`mir_prof`)**
  - Maps mirror profile keys to configuration values for mirroring behavior.

- **Actions:**
  - `drop()`: Drop the packet.
  - `send(port)`: Send the packet to the specified port.
  - `mirror_and_send(mirror_session_id)`: Mirror the packet using the specified session, then recirculate the packet (send it back to the pipeline for another pass).
  - `mirror_and_forward(mirror_session_id, port)`: Mirror the packet using the specified session, then forward it to the specified port.

- **Tables:**
  - `l3_l4_match`:
    - Matches on IPv4 source/destination, MAC source/destination, and protocol fields (ternary match).
    - Actions: `drop`, `mirror_and_send`.
    - Used for L3/L4-based mirroring and recirculation.
  - `l2_fwd_tx`:
    - Matches on destination MAC (exact match).
    - Actions: `drop`, `send`, `mirror_and_forward`.
    - Used for L2 forwarding and mirroring on egress (Tx).
  - `l2_fwd_rx`:
    - Matches on destination MAC (exact match).
    - Actions: `drop`, `send`, `mirror_and_forward`.
    - Used for L2 forwarding and mirroring on ingress (Rx).

---

## 3. Control Flow and Pass Metadata

- The program uses the `pass` field in the packet metadata to distinguish between multiple passes of the same packet through the pipeline:
  - `pass_1st(meta)`: First pass (original packet entry)
  - `pass_2nd(meta)`: Second pass (after first recirculation)
  - `pass_3rd(meta)`: Third pass (after second recirculation)

- **Apply Block Logic:**
  - **Third Pass:**
    - If Rx and MAC is valid and `pass == 2` (third pass):
      - Apply `l2_fwd_rx` (L2 forwarding and mirroring for Rx)
    - Else if Tx and MAC is valid and `pass == 2` (third pass):
      - Apply `l2_fwd_tx` (L2 forwarding and mirroring for Tx)
  - **First and Second Passes:**
    - If MAC and IPv4 are valid and `pass == 0` (first pass):
      - Apply `l3_l4_match` (L3/L4-based mirroring and recirculation)
    - Else if MAC and IPv4 are valid and `pass == 1` (second pass):
      - Apply `l3_l4_match` (L3/L4-based mirroring and recirculation)

---

## 4. Table Entry Configuration and Mirroring Behavior

- **Mirror Profile Table:**
  - Populated with rules mapping mirror profile keys to vport IDs and destination IDs, enabling mirroring to specific virtual ports.

- **L3/L4 Match Table:**
  - Populated with rules that match on protocol, source/destination IP, and MAC addresses.
  - Example: Packets with protocol 0x11 (UDP), specific source/destination IPs, and MAC addresses are mirrored using session 19 and recirculated for further processing.

- **L2 Forwarding Tables:**
  - `l2_fwd_rx` and `l2_fwd_tx` are populated with rules for both normal forwarding and mirroring+forwarding.
  - Example: Packets with destination MAC `0x00000000921` (Rx) or `0x00000000922` (Tx) are both forwarded and mirrored to the appropriate port.

- **Mirroring and Recirculation Simulation:**
  - On the first and second passes, packets matching the L3/L4 rules are mirrored and recirculated, simulating repeated processing and output generation.
  - On the third pass, packets are forwarded and mirrored at L2, producing both an original and a mirrored copy at the output.

---

## 5. Deparser

- Output all parsed headers and metadata as received (no custom logic).

---

## 6. Main Pipeline Instantiation

- Instantiate the main PNA_NIC pipeline with:
  - `main_parser = FXPParser` (assumed to parse all relevant headers)
  - `main_control = my_control` (the control block above)
  - `main_deparser = MainDeparserImpl` (the deparser above)

---

## Notes

- The use of the `pass` metadata is essential to distinguish between the original packet and its recirculated copies, ensuring correct table application and mirroring behavior at each stage.
- This design enables a single trigger packet to generate repeated mirroring and recirculation, simulating an amplification attack that can multiply output traffic and stress the switch pipeline. However, the hardware's cap of 3 passes per packet mitigates this attack.
- All NDA-restricted code details are abstracted into this pseudocode for reproducibility.
