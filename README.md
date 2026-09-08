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
An implementation of an 8-bit Galois Linear Feedback Shift Register (LFSR) shifting right (MSB to LSB).

## Characteristic Polynomial

$$x^8 + x^6 + x^5 + x^4 + 1$$

## Block Diagram

```text
LEFTMOST (MSB)                                               RIGHTMOST (LSB)
+---------+---------+---------+---------+---------+---------+---------+---------+
| lfsr[7] | lfsr[6] | lfsr[5] | lfsr[4] | lfsr[3] | lfsr[2] | lfsr[1] | lfsr[0] |
+---------+---------+---------+---------+---------+---------+---------+---------+
     |          ^         ^         ^                                     ^
     |          |         |         |                                     |
     |        [XOR]     [XOR]     [XOR]                                   |
     |          ^         ^         ^                                     |
     |          |         |         |                                     |
     +----------+---------+---------+-------------------------------------+
                          FEEDBACK SIGNAL (lfsr[7])
```

## State Transition Matrix

Starting from a default reset seed of `8'h01`, the module steps through a maximal length sequence of $2^8 - 1 = 255$ unique non-zero states before repeating.

| Clock Cycle | Current State (`lfsr_out[7:0]`) | Feedback Bit (`lfsr[7]`) | Active Tap Action | Next State (`lfsr_out[7:0]`) |
| :---: | :---: | :---: | :--- | :---: |
| **Reset** | `8'h01` (`8'b00000001`) | `0` | Pure Shift Right | `8'h02` |
| **1** | `8'h02` (`8'b00000010`) | `0` | Pure Shift Right | `8'h04` |
| **2** | `8'h04` (`8'b00000100`) | `0` | Pure Shift Right | `8'h08` |
| **...** | `...` | `...` | `...` | `...` |
| **Active XOR** | `8'h80` (`8'b10000000`) | `1` | XOR taps `[6,5,4]`, feed `0` | `8'h71` |
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

# Tap-Out Values vs. PRBS Bit

## Overview

In Linear Feedback Shift Register (LFSR) designs, a common point of confusion is the difference between **tap-out values** and the **PRBS bit output**. 

While both originate from internal register bits, they serve completely different roles in hardware: tap-out values drive internal feedback logic, while the PRBS bit is exported for external system use.

---

## 1. Core Distinction

### Tap-Out Values (Internal Logic Drivers)
* **What They Are:** Specific intermediate register indices (e.g., bits 6, 5, and 4 for $x^8 + x^6 + x^5 + x^4 + 1$) selected strictly by the primitive polynomial to drive XOR feedback inputs.
* **Function:** They serve as internal feedback tap points that scramble and shift data across the register chain to prevent premature repetition. They exist purely to define state transition update logic.
* **Scope:** Internal module signals (not required on top-level ports).

### PRBS Bit (External Serial Output)
* **What It Is:** The actual single-bit output stream exported to external hardware or testbenches.
* **Function:** Provides the generated pseudo-random sequence to outside systems for Bit Error Rate Testing (BERT), built-in self-test (BIST), or payload scrambling.
* **Scope:** Primary module output port (`output wire prbs_bit`).

---

## 2. Is `prbs_bit` Required to be `lfsr[7]`?

**No, it is not mandatory.**

Because a maximal-length LFSR cycles through all $2^N - 1$ non-zero states, **every single bit index in the register generates a valid maximal-length PRBS bitstream**.

### Common Design Conventions
* **Interface Standards:** Designers typically select the MSB (`lfsr[7]`) or LSB (`lfsr[0]`) simply to establish a consistent, predictable port interface contract.
* **Phase Shift Across Bits:** Tapping `prbs_bit = lfsr[3]` yields the exact same pseudo-random sequence as `lfsr[7]`, shifted/delayed by 4 clock cycles in time.

---

## 3. Can a Tap-Out Value Be Used as a PRBS Bit?

**Yes, absolutely.** Any tap-out value (or any register bit inside the LFSR) can be used as a PRBS bit.

* **Identical Statistical Properties:** Every single bit position in a maximal-length LFSR generates the exact same pseudo-random sequence with identical randomness and distribution properties.
* **Time Delay / Phase Shift:** The only difference between taking the PRBS output from a tap-out bit versus a non-tap-out bit is a time delay (phase shift) relative to other bits in the register.

---

## Feature Comparison Matrix

| Feature | Tap-Out Values | PRBS Bit |
| :--- | :--- | :--- |
| **Primary Role** | Intermediate registers connected to XOR gates. | System-level single-bit output stream. |
| **Selection Criteria** | Fixed strictly by the mathematical polynomial ($x^8 + x^6 + x^5 + x^4 + 1$). | Arbitrary choice by the designer (any index from `0` to `7`, including tap positions). |
| **Visibility** | Internal to the module logic. | Primary output interface port. |
| **Phase Relationship** | Dictates transition dynamics. | Time-shifted copy of any other register bit. |
