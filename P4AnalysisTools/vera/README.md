# Vera

We evaluated the released Vera2 implementation using the P4_14 version of our amplification program.

## Source

- Paper: *Debugging P4 Programs with Vera*
- Repository: https://github.com/dragosdmtrsc/vera2

## Input

The `input/` directory contains the P4_14 amplification program and the `commands.txt` file specifying the control-plane configuration.

Preprocess the program into the P4_14 syntax accepted by the released Vera2 implementation.

```
cpp -P input/SoK_Amp_P4_14.p4 > input/SoK_Amp_P4_14-ppc.p4
```

## Running

Follow the setup instructions in the Vera2 repository, then run Vera on the supplied program and control-plane configuration.

```
./target/vera.sh \
  --print-solver --commands input/commands.txt \
  input/SoK_Amp_P4_14-ppc.p4  > output/vera-amp.log 2>&1
```

## Result

Vera successfully analyzes the program and control-plane configurations in ```commands.txt``` and reports no violation.

Vera models cloning and recirculation as packet outcomes, but a recirculated packet is not reprocessed through the parser and ingress pipeline. It therefore cannot represent the repeated clone-recirculate feedback responsible for the amplification.