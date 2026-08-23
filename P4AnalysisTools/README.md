# P4 Analysis Tools

This directory contains the inputs, outputs, and reproduction notes for the four P4 analysis tools evaluated in the amplification case study:

- **P4Testgen** — https://doi.org/10.5281/zenodo.10014918
- **Vera** — https://github.com/dragosdmtrsc/vera2
- **ASSERT-P4** — https://github.com/LucasMFreire/assert-p4
- **bf4** — https://github.com/dragosdmtrsc/bf4

The tools are third-party artifacts and are not redistributed here. Each subdirectory contains the experimental inputs and outputs used in our evaluation, together with a `README.md` describing the upstream source, setup or compatibility requirements, execution procedure, and observed result.

The released implementations differ in supported P4 versions, architectures, and dependencies. Where necessary, we adapted the case-study program or input representation to the format expected by the tool; these transformations and relevant compatibility steps are documented in the corresponding subdirectory.

For the analysis and interpretation of these results, see §8.4 of the paper.