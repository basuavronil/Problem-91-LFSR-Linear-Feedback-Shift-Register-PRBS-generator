# Galois LFSR (8-Bit PRBS Generator)

## Overview
The `lfsr_prbs` module is an 8-bit maximal-length Galois Linear Feedback Shift Register (LFSR) designed for Pseudo-Random Binary Sequence (PRBS) generation. 

It uses parallel inline XOR feedback gates placed at specific register taps. This architecture avoids long combinational logic trees in the feedback loop, maximizing the operating frequency ($F_{max}$) compared to standard Fibonacci topologies.

---

## Generator Polynomial & Tap Logic

The module implements the standard 8-bit primitive feedback polynomial:

$$P(x) = x^8 + x^6 + x^5 + x^4 + 1$$

### Equation & Tap Map
* **Highest Term ($x^8$):** Sets register width ($N = 8$). The MSB (`lfsr[7]`) is where feedback re-enters the register.
* **Constant Term ($+ 1$):** Makes the LSB (`lfsr[0]`) the feedback/exit tap — the bit that shifts out on a right shift.
* **Tap Out Locations ($x^6, x^5, x^4$):** Taps sit at indices **5, 4, and 3** (one position lower than the exponent, since the shift itself moves the bit down one slot before the XOR lands). As the register shifts right, these positions are XORed with the exiting bit `lfsr[0]`.

### Bit-Level Update Equations

$$lfsr[7]_{next} = lfsr[0]$$

$$lfsr[6]_{next} = lfsr[7]$$

$$lfsr[5]_{next} = lfsr[6] \oplus lfsr[0] \quad \text{(Tap } x^6\text{)}$$

$$lfsr[4]_{next} = lfsr[5] \oplus lfsr[0] \quad \text{(Tap } x^5\text{)}$$

$$lfsr[3]_{next} = lfsr[4] \oplus lfsr[0] \quad \text{(Tap } x^4\text{)}$$

$$lfsr[2]_{next} = lfsr[3]$$

$$lfsr[1]_{next} = lfsr[2]$$

$$lfsr[0]_{next} = lfsr[1]$$

---
An implementation of an 8-bit Galois Linear Feedback Shift Register (LFSR) shifting right: each bit's value moves toward the LSB every cycle, the bit exiting at `lfsr[0]` becomes the feedback, and it re-enters at `lfsr[7]`.

## Characteristic Polynomial

$$x^8 + x^6 + x^5 + x^4 + 1$$

## Block Diagram

```text
LEFTMOST (MSB)                                               RIGHTMOST (LSB)
+---------+---------+---------+---------+---------+---------+---------+---------+
| lfsr[7] | lfsr[6] | lfsr[5] | lfsr[4] | lfsr[3] | lfsr[2] | lfsr[1] | lfsr[0] |
+---------+---------+---------+---------+---------+---------+---------+---------+
     ^          |         |         |                                     |
     |          |         |         |                                     |
     |        [XOR]<----------------+                                     |
     |          |       [XOR]<--------------------------------------------|
     |          |         |       [XOR]<----------------------------------|
     |          v         v         v                                     |
     +----------+---------+---------+-------------------------------------+
                          FEEDBACK SIGNAL (lfsr[0])
```

Bits shift **right** each cycle. The bit exiting at `lfsr[0]` is the feedback; it re-enters at `lfsr[7]` and is XORed into taps 5, 4, and 3 as the shifted bits pass through those positions.

## State Transition Matrix

Starting from a default reset seed of `8'h01`, the module steps through a maximal length sequence of $2^8 - 1 = 255$ unique non-zero states before repeating.

| Clock Cycle | Current State (`lfsr_out[7:0]`) | Feedback Bit (`lfsr[0]`) | Active Tap Action | Next State (`lfsr_out[7:0]`) |
| :---: | :---: | :---: | :--- | :---: |
| **Reset** | `8'h01` (`8'b00000001`) | `1` | XOR taps `[5,4,3]`, feed `1` into MSB | `8'hB8` |
| **1** | `8'hB8` (`8'b10111000`) | `0` | Pure Shift Right | `8'h5C` |
| **2** | `8'h5C` (`8'b01011100`) | `0` | Pure Shift Right | `8'h2E` |
| **...** | `...` | `...` | `...` | `...` |
| **Cycle 255** | `...` | `...` | Sequence wraps around | `8'h01` |

> Because the reset seed `8'h01` has its LSB set, feedback is active from the very first cycle — there's no initial run of "pure shifts" the way the old (incorrect) version showed. A seed like `8'h80` will pure-shift for several cycles first (`0x80 → 0x40 → 0x20 → ... → 0x01`) before feedback kicks in.

---

## Port Definitions

### System & Stream Interface
* **`clk`**: System Clock.
* **`rst`**: Synchronous Active-High Reset (Loads non-zero seed `8'h01`).
* **`en`**: Clock Enable. Advances register state when high; freezes current sequence when low.
* **`lfsr_out[7:0]`** *(Output, 8 bits)*: Parallel 8-bit pseudo-random byte output.
* **`prbs_bit`** *(Output, 1 bit)*: Serial pseudo-random bitstream output driven by `lfsr[0]`.

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
* **What They Are:** Specific intermediate register indices (bits 5, 4, and 3 for $x^8 + x^6 + x^5 + x^4 + 1$, in this right-shift arrangement) selected strictly by the primitive polynomial to drive XOR feedback inputs.
* **Function:** They serve as internal feedback tap points that scramble and shift data across the register chain to prevent premature repetition. They exist purely to define state transition update logic.
* **Scope:** Internal module signals (not required on top-level ports).

### PRBS Bit (External Serial Output)
* **What It Is:** The actual single-bit output stream exported to external hardware or testbenches.
* **Function:** Provides the generated pseudo-random sequence to outside systems for Bit Error Rate Testing (BERT), built-in self-test (BIST), or payload scrambling.
* **Scope:** Primary module output port (`output wire prbs_bit`).

---

## 2. Is `prbs_bit` Required to be `lfsr[0]`?

**No, it is not mandatory.**

Because a maximal-length LFSR cycles through all $2^N - 1$ non-zero states, **every single bit index in the register generates a valid maximal-length PRBS bitstream**.

### Common Design Conventions
* **Interface Standards:** Designers typically select the LSB (`lfsr[0]`) or MSB (`lfsr[7]`) simply to establish a consistent, predictable port interface contract. Here, `lfsr[0]` doubles as the feedback tap, so it's a natural, zero-extra-logic choice for `prbs_bit`.
* **Phase Shift Across Bits:** Tapping `prbs_bit = lfsr[4]` yields the exact same pseudo-random sequence as `lfsr[0]`, shifted/delayed by a fixed number of clock cycles in time.

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

# LFSR Tap Mapping Rule: "Subtract 1" Galois Trick

A simple, memorable rule of thumb to instantly map polynomial terms to Galois LFSR states during **right-shift (MSB to LSB)** operations.

---

## The Rule

For an $N$-bit register defined by polynomial degree $N$, where states are named $S_{N-1}$ down to $S_0$:

$${\large \text{Target State } (S_{k-1}) \leftarrow S_k \oplus \text{Feedback}}$$

### Quick Summary Matrix

| Polynomial Term | Target State Index | Source State Index | Next State Value |
| :---: | :---: | :---: | :---: |
| **$x^k$** | **$S_{k-1}$** | **$S_k$** | **$S_k \oplus \text{Feedback}$** |

---

## 3-Step Process

1. **Highest Term ($x^N$):** Defines total register width $N$. The MSB ($S_{N-1}$) generates the **Feedback Signal**.
2. **Constant Term ($1$ / $x^0$):** Connects feedback directly back via wraparound.
3. **Middle Terms ($x^k$):** Subtract 1 from the exponent $k$ to identify the target state index ($S_{k-1}$).

---

## Applied Example

For polynomial $P(x) = x^8 + x^6 + x^5 + x^4 + 1$:

* **$x^8$ (Degree $N=8$):** States are $S_7$ down to $S_0$. Feedback comes from $S_7$.
* **$x^6$ Tap ($k=6$):** Target is $S_{6-1} = S_5$. 
  $$\text{XOR Output} \longrightarrow S_5 = S_6 \oplus \text{Feedback}$$
* **$x^5$ Tap ($k=5$):** Target is $S_{5-1} = S_4$. 
  $$\text{XOR Output} \longrightarrow S_4 = S_5 \oplus \text{Feedback}$$
* **$x^4$ Tap ($k=4$):** Target is $S_{4-1} = S_3$. 
  $$\text{XOR Output} \longrightarrow S_3 = S_4 \oplus \text{Feedback}$$

---

## Visual Signal Flow

```text
       S_k (Source State)
        |
        v
      [XOR] <--- Feedback Signal (S_{N-1})
        |
        v
      S_{k-1} (Target State)
