# P4Testgen

We evaluated P4Testgen using the containerized artifact released with the SIGCOMM 2023 paper.

## Source

- Paper: *P4Testgen: An Extensible Test Oracle for P4*
- Artifact: https://doi.org/10.5281/zenodo.10014918

We used the containerized version distributed with the artifact.

## Input

The experiment uses our P4_16/v1model amplification program, provided in ```input/```.

## Running

Follow the setup instructions provided with the P4Testgen artifact, then run P4Testgen in the container on the supplied program.

```
p4testgen --target bmv2 --arch v1model --test-backend PTF \
  --out-dir results \
  --seed 1 \
  --track-coverage STATEMENTS \
  --max-tests 100 \
  --packet-size-range 12000:12000 \
  -DTESTGEN_ASSUME_IP -DTESTGEN_ASSUME_TCP \
  /p4c/p4/SoK_Amp_P4_16.p4
```

## Result

P4Testgen successfully analyzes the program and:

- achieves 100% statement coverage (18/18 nodes);
- generates the amplification trigger (`TCP dport = 0x5000`);
- exercises both cloning and recirculation.

On the recirculation path, it reports:

> `Only single recirculation supported for now. Dropping packet.`

P4Testgen therefore reaches the vulnerable path but stops execution after one recirculation, preventing it from capturing the repeated feedback responsible for sustained amplification.