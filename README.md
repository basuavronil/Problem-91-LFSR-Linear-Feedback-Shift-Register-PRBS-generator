# Linear Feedback Shift Register (LFSR) — PRBS Generator

## Overview
The `lfsr_prbs` module is an 8-bit maximal-length Linear Feedback Shift Register (LFSR) used to generate Pseudo-Random Binary Sequences (PRBS). 

It utilizes a Galois implementation based on the primitive polynomial $x^8 + x^6 + x^5 + x^4 + 1$. The module continuously shifts internal bit states on every clock edge, producing a deterministic, uniform pseudo-random output sequence with a maximum repeating period of $2^8 - 1 = 255$ clock cycles before recycling.

---

## Architecture & Logic Flow

The Galois LFSR applies XOR feedback inline along the shift register chain at specific tap positions determined by the feedback polynomial.

```text
                  +-------------------------------------------------------+
                  |                      GALOIS LFSR                      |
                  |                                                       |
                  |  +-----+     +-----+     +-----+           +-----+    |
               +---->| Q[0] |--+->| Q[1] |-->| Q[2] |--> ... ->| Q[7] |---+
               |  |  +-----+   | +-----+     +-----+           +-----+    |
               |  +------------|----+                                     |
               |               v    |                                     |
               |             (XOR)  |  (Taps at bits 6, 5, 4, 0)          |
               |               |    |                                     |
               +---------------+----+                                     |
                  +-------------------------------------------------------+
