# bf4

We evaluated bf4 using its publicly released implementation.

## Source

- Paper: *bf4: Towards Bug-Free P4 Programs*
- Repository: https://github.com/dragosdmtrsc/bf4

The released implementation targets P4_14, so we use the equivalent P4_14 version of our amplification program.

## Input

The `input/` directory contains the P4_14 amplification program used in the evaluation.

## Running

Follow the setup instructions in the bf4 repository, then from the ```build``` folder, run preprocessor on the original program.

```
python3 ../sigcomm-2020/cleanup_v1.py SoK_Amp_P4_14.p4
```

Then run bf4 on the integrated program:

```
p4c-analysis SoK_Amp_P4_14-integrated.p4
```

## Result

bf4 successfully instruments and verifies the program. It reports two reachable bugs, both before and after specification inference, ultimately reporting:

> `WARNING: uncontrolled bug`

Inspection of the instrumented program shows that these warnings arise from bf4's built-in correctness checks: a TCP-header validity check associated with accessing `tcp.dport`, and a check that the egress port is assigned on every ingress path.

No violation condition is inserted for the amplification behavior. Cloning and recirculation are treated as valid operations, so the repeated clone-recirculate feedback is not detected.

See ```output/bf.log``` for full experiment log.