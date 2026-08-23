# SoK: The Security of P4-Programmable Network Devices

This repository contains the artifacts accompanying our paper, including the cross-target traffic-amplification case study and its evaluation with existing P4 analysis tools.

## Repository Structure

- [`Amplification/`](./Amplification/) — P4 programs, scripts, configurations, and reproduction instructions for the amplification experiments on:
  - Intel Tofino
  - NVIDIA Spectrum-2
  - Intel IPU E2100
  - BMv2

- [`P4AnalysisTools/`](./P4AnalysisTools/) — inputs, outputs, and reproduction notes for the four P4 analysis tools evaluated in the paper:
  - P4Testgen
  - Vera
  - ASSERT-P4
  - bf4

Each directory contains its own `README.md` with platform or tool-specific setup and reproduction instructions.

## Reproducing the Results

For the cross-target amplification experiments, see [`Amplification/README.md`](./Amplification/README.md).

For the P4 analysis-tool evaluation, see [`P4AnalysisTools/README.md`](./P4AnalysisTools/README.md).

Some experiments require platform-specific hardware or software that cannot be redistributed. Where applicable, the corresponding README documents these requirements and provides the releasable experimental material.

## License

See [`LICENSE`](./LICENSE).