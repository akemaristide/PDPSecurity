# Traffic amplification attack leveraging recirculation and replication

## Attack Overview

This attack leverages the recirculation and packet-replication mechanisms (mirroring or cloning) features of switches to create a feedback loop, where a single or small number of crafted packets can generate a sustained high-rate packet stream. The P4 program classifies packets based on their TCP destination port (dport) and applies different forwarding behaviors:

- **dport 0x4000:** Packets are continuously recirculated within the switch, never egressing.
- **dport 0x5000:** Packets are both recirculated and mirrored to a physical port, creating a loop that emits a copy on each pass while reintroducing the packet for another iteration.
- **default path:** Packets are forwarded normally.

## Evaluation on Tofino (Tofino)

### Switch and Server Characteristics

#### Switch Characteristics

- **Switch Model:** Netberg Aurora 710 
- **Chip:** Intel Tofino, 32×100GbE ports
- **SDE:** bf-sde-9.9.0
- **Switch CPU:** Intel Xeon D-1527 @ 2.20GHz, 8 cores
- **Switch OS:** 4.19.81-OpenNetworkLinux

#### Server Characteristics

- **CPU:** AMD EPYC 7443P 24-Core Processor @ 2.1GHz (48 threads, 24 cores, 1 socket)
- **Memory:** 256GB DDR4
- **NIC:** Dual-port Mellanox ConnectX-5 100GE
- **Architecture:** x86_64, 32/64-bit
- **Threads per core:** 2

### Experiment workflow

1. **Compile the P4 program**
   - Use the provided `p4_build.sh` script to compile the P4 source code:
     ```
     ./p4_build.sh SoK_Amp_P4_16.p4
     ```
2. **Deploy the P4 program on the switch**
   - Run the compiled program using the SDE:
     ```
     cd $SDE
     ./run_switchd.sh -p SoK_Amp_P4_16
     ```
3. **Activate ports and enable loopback**
   - Use the following commands to activate ports:
     ```
     bfshell -f activate_ports.txt
     ```

4. **Generate and inject trigger packets**
    - Use the provided Python script `sendVariablePackets.py` to craft and send packets with the desired dport values (0x4000 or 0x5000) -- Requires scapy.
    - Example for ten 1024B payloads with dport 0x5000:
      ```
      python3 sendVariablePackets.py 5000 10 1024
      ```

5. **Monitor switch and server output**
   - On the switch, monitor port counters to observe the effect of the attack:
     ```
     ucli
     pm
     rate-period 1
     rate-show
     ```
   - On the receiving server, monitor egress traffic to measure the sustained packet stream.


### Experiment Details
#### Test 1: Recirculation without Mirroring
- **Trigger:** TCP dport 0x4000
- **Expected Behavior:** Packet is recirculated indefinitely within the switch, never egressing.
- **Observation:** No packets observed at the receiver, confirming infinite recirculation is possible.

#### Test 2: Recirculation with Mirroring
- **Trigger:** TCP dport 0x5000
- **Expected Behavior:** Each recirculation pass emits a mirrored copy to the output port, creating a sustained packet stream.
- **Observation:**
  - A single input packet induced a continuous output stream at the receiver.
  - 64 B payloads: 1.93 Mpps, 2.41 Gbps
  - 1024 B payloads: 1.72 Mpps, 15.36 Gbps

**Note**: The Tofino implementation used for these measurements prepends a 14 B Ethernet header to each mirrored copy. The reported payload sizes refer to the TCP payload.

#### Test 3: Scaling Behaviour
- **Method:** Vary the number of trigger packets and payload sizes.
- **Observation:**
  - Fewer trigger packets are needed to saturate the 100Gbps link as payload size increases (e.g., 42 packets at 64B payload, 7 at 1024 B payload).
  - The attack loop can drive the link to capacity with only a modest number of packets.

---

## Evaluation on Nvidia Spectrum-2 (Spectrum2)

#### Switch Characteristics
- **Switch Model:** Nvidia Spectrum-2 
- **Kernel:** Linux 5.10.0-12-2-amd64 x86_64
- **Switch OS:** Debian GNU/Linux 11

#### Server Characteristics

- **CPU:** AMD EPYC 7443P 24-Core Processor @ 2.1GHz (48 threads, 24 cores, 1 socket)
- **Memory:** 256GB DDR4
- **NIC:** Dual-port Mellanox ConnectX-5 100GE
- **Architecture:** x86_64, 32/64-bit
- **Threads per core:** 2

### Experiment details

1. [Switch] In the P4 program, only mirroring is implemented (no recirculation). To compile the P4 code and C code (for table entries), run `make` under the `p4src` folder:
   ```
   make
   ```
   Then, to execute the program, go to the output directory and run:
   ```
   cd _out/spectrum2/
   ./Amplification
   ```
   (Do not change the file names, as the C program uses APIs generated from the P4 program.)

2. [Switch] Configure the switch as needed (e.g., VLANs, port settings) using the provided scripts, similar to the MemoryDisturbance experiment:
   ```
   python3 configure_port.py
   ```

3. [Server] Generate packets using your preferred tool (e.g., pktgen or tcpreplay) to inject trigger packets for the mirroring logic.

4. [Switch] Monitor counters and mirrored traffic as in the Tofino experiments.

### Absence of recirculation

Packet mirroring is supported in Spectrum-2 switches via the built-in `nv_mirror()` action. While Spectrum-2 does provide a recirculation mechanism, it is strictly managed by the operating system and not exposed to user-space P4 programs for programmable, packet-level recirculation. When a port is set as a recirculation port, administrative control is transferred to the OS, which uses it for buffer-dropped packets and does not allow user packet re-injection into the pipeline. 

While physical port interconnection can emulate such a loop, it does not represent the same architectural behavior. As a result, the programmable feedback loop demonstrated on Tofino cannot be constructed on Spectrum-2.


#### Test 1: Mirroring
- **Trigger:** TCP dport 0x5000
- **Expected Behavior:** Packet is mirrored to the output port.
- **Observation:** For every input packet, two packets were output: the original packet and a mirrored copy.


## Tests on the Intel IPU E2100 (IPU)

Due to a non-disclosure agreement (NDA) with Intel Corporation for the Intel IPU Software Development Kit, we cannot release the P4 code for this platform. Instead, we provide detailed pseudocode and accompanying scripts to enable reproducibility by other Intel IPU E2100 users.

### Hardware Setup

- **IPU Adapter:** Intel® Infrastructure Processing Unit (IPU) Adapter E2100-CCQDA2 (PCIe 4.0 ×16 card, two 100GE ports)
- **IPU SoC:** Intel IPU E2100 SoC with P4-programmable packet-processing pipeline (up to 200 Mpps)
- **IPU Compute Complex:** 16 Arm Neoverse N1 cores (up to 2.5 GHz), 32 MB system-level cache, 48 GB LPDDR4x, NVMe, compression, and lookaside cryptography accelerators
- **Host Server:** 2.4GHz INTEL(R) XEON(R) SILVER 4510, 375GB DDR4
- **NIC:** 2 × Mellanox ConnectX-5 100GE NIC ports (connected to IPU ports)

The IPU is slotted into a PCIe port on the server, and the IPU ports are directly connected to the server's Mellanox NICs.

For details on the P4 logic and vulnerabilities, see the provided pseudocode and scripts in the IPU folder.


## Tests on BMv2 (BMv2)

We demonstrate packet amplification on BMv2 using internal packet recirculation combined with ingress-to-egress cloning (mirroring).

The experiment was run from a folder in the ```/home/user/tutorials/exercises/BMv2/P4_16``` folder in the P4 tutorials VM.

---

### Environment Topology

The network consists of switch **s1** connected to **3 hosts** mapped directly to switch ports:

| Host | IP Address | MAC Address | Switch Port | Role |
| --- | --- | --- | --- | --- |
| **h1** | `10.0.1.1` | `08:00:00:00:01:01` | Port 1 | Traffic Generator / Attacker |
| **h2** | `10.0.1.2` | `08:00:00:00:01:02` | Port 2 | Normal Traffic Receiver |
| **h3** | `10.0.1.3` | `08:00:00:00:01:03` | Port 3 | Mirror / Amplification Target |

---

### Compilation & Network Launch

To compile the P4 program, start the switch, and initialize the Mininet topology:

```bash
make
```

### Configure Mirror Session

To enable packet mirroring, configure Mirror Session **`5`** to send cloned traffic to Port **3** (**h3**).

Run `simple_switch_CLI` in a separate terminal:

```bash
simple_switch_CLI --thrift-port 9090
```

Then execute:

```text
mirroring_add 5 3
```

If working in ```P4_14```, then also set a default action:

```
table_set_default experiment default_branch
```

---

### Sending Test Packets (`send_packets.py`)

Execute the packet sender script from host **h1** inside the Mininet environment. Requires scapy.

#### Execution Options

You can send packets directly from the Mininet CLI or via `xterm`:

**Option A: Directly from Mininet CLI**

```text
mininet> h1 python3 send_packets.py -p <port_option>
```

**Option B: Using Host Terminal**

```text
mininet> xterm h1
# Inside h1 terminal:
python3 send_packets.py -p <port_option>
```

---

### Test Cases & Observed Behaviors

* **Normal Forwarding (e.g. Port `0x2000`):**
```bash
python3 send_packets.py -p 2
```

* **Behavior:** Packet is forwarded out Port 2 to **h2**.


* **Recirculation Only (Port `0x4000`):**
```bash
python3 send_packets.py -p 4
```

* **Behavior:** Packet recirculates internally without egressing cloned traffic.


* **Amplification Trigger (Port `0x5000`):**
```bash
python3 send_packets.py -p 5
```

* **Behavior:** Triggers infinite packet recirculation while continuously generating mirrored traffic copies sent out Port 3 to **h3**.
