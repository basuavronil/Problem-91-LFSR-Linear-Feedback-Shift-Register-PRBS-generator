# Galois LFSR (8-Bit PRBS Generator)

## Overview
The `lfsr_prbs` module is an 8-bit maximal-length Galois Linear Feedback Shift Register (LFSR) designed for Pseudo-Random Binary Sequence (PRBS) generation. 

It uses parallel inline XOR feedback gates placed at specific register taps. This architecture avoids long combinational logic trees in the feedback loop, maximizing the operating frequency ($F_{max}$) compared to standard Fibonacci topologies.

---

## Generator Polynomial & Tap Logic

The module implements the standard 8-bit primitive feedback polynomial:

$$P(x) = x^8 + x^6 + x^5 + x^4 + 1$$

### Equation & Tap Map
* **Highest Term ($x^8$):** Sets register width ($N = 8$). The MSB (`lfsr[7]`) serves as the feedback signal.
* **Constant Term ($+ 1$):** Connects the feedback signal directly into the lowest bit (`lfsr[0]`).
* **Tap Out Locations ($x^6, x^5, x^4$):** Taps sit at indices **6, 5, and 4**. During a shift cycle, incoming register values into these bit positions are XORed with `lfsr[7]`.

### Bit-Level Update Equations

$$lfsr[0]_{next} = lfsr[7]$$

$$lfsr[1]_{next} = lfsr[0]$$

$$lfsr[2]_{next} = lfsr[1]$$

$$lfsr[3]_{next} = lfsr[2]$$

$$lfsr[4]_{next} = lfsr[3] \oplus lfsr[7] \quad \text{(Tap } x^4\text{)}$$

$$lfsr[5]_{next} = lfsr[4] \oplus lfsr[7] \quad \text{(Tap } x^5\text{)}$$

$$lfsr[6]_{next} = lfsr[5] \oplus lfsr[7] \quad \text{(Tap } x^6\text{)}$$

$$lfsr[7]_{next} = lfsr[6]$$

---

## State Transition Matrix

Starting from a default reset seed of `8'h01`, the module steps through a maximal length sequence of $2^8 - 1 = 255$ unique non-zero states before repeating.

| Clock Cycle | Current State (`lfsr_out[7:0]`) | Feedback Bit (`lfsr[7]`) | Active Tap Action | Next State (`lfsr_out[7:0]`) |
| :---: | :---: | :---: | :--- | :---: |
| **Reset** | `8'h01` (`8'b00000001`) | `0` | Pure Shift Right | `8'h02` |
| **1** | `8'h02` (`8'b00000010`) | `0` | Pure Shift Right | `8'h04` |
| **2** | `8'h04` (`8'b00000100`) | `0` | Pure Shift Right | `8'h08` |
| **...** | `...` | `...` | `...` | `...` |
| **Active XOR** | `8'h80` (`8'b10000000`) | `1` | XOR taps `[6,5,4,0]` with `1` | `8'h71` |
| **Cycle 255** | `8'h80` | `1` | Sequence wraps around | `8'h01` |

---

## Port Definitions

### System & Stream Interface
* **`clk`**: System Clock.
* **`rst`**: Synchronous Active-High Reset (Loads non-zero seed `8'h01`).
* **`en`**: Clock Enable. Advances register state when high; freezes current sequence when low.
* **`lfsr_out[7:0]`** *(Output, 8 bits)*: Parallel 8-bit pseudo-random byte output.
* **`prbs_bit`** *(Output, 1 bit)*: Serial pseudo-random bitstream output driven by `lfsr[7]`.

---

## Key Features

* **Maximal Period:** Full 255-cycle PRBS repeat period ($2^N - 1$).
* **High-Speed Galois Topology:** Inline XOR gates eliminate deep tree delays on feedback lines.
* **Zero-Lockup Safe:** Synchronous reset guarantees boot into a valid non-zero seed state (`8'h01`).
