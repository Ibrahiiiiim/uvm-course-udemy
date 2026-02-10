# Aligner Verification Using UVM (SystemVerilog)

## Overview
The Aligner module receives an unaligned stream of data and outputs an aligned data stream based on programmable configuration registers.  
The purpose of the Aligner is to optimize memory writes by performing only the writes best suited to the target memory type used in the system.

This repository contains a **UVM-based verification environment** written in **SystemVerilog** to verify the functionality and correctness of the Aligner module.

---

## System Architecture

### Interfaces

The Aligner module communicates using the following interfaces:

#### 1. APB Interface (AMBA 3)
- Used for register access and configuration.
- Verified using an **APB UVM agent** operating as an active agent.

#### 2. Memory Data (MD) Interfaces
The design uses a custom **MD (Memory Data) protocol** for data transfer.

- **RX Interface**
  - Receives unaligned input data.
  - Driven by an active MD RX agent.

- **TX Interface**
  - Outputs aligned data.
  - Monitored by a passive MD TX agent.
<img width="571" height="219" alt="image" src="https://github.com/user-attachments/assets/69c789dc-c620-496f-96ae-390d643b0b0c" />

---

## 3. Interface Signals

| Signal Name | Signal Width | Description |
|------------|--------------|-------------|
| clk | Bit | Clock signal on which the entire module is working |
| reset_n | Bit | Reset signal – active low |
| psel | Bit | APB select |
| penable | Bit | APB enable |
| pwrite | Bit | APB write |
| paddr | [15:0] | APB address. Bits `paddr[1:0]` are ignored and treated as `2'b00`, meaning all accesses are word (4 bytes) aligned |
| pwdata | [31:0] | APB write data |
| pready | Bit | APB ready |
| prdata | [31:0] | APB read data |
| pslverr | Bit | APB slave error |

### MD RX Interface

| Signal Name | Signal Width | Description |
|------------|--------------|-------------|
| md_rx_valid | Bit | RX valid. Must remain high until `md_rx_ready` is asserted |
| md_rx_data | [31:0] | RX data. Valid while `md_rx_valid` is high and remains constant until `md_rx_ready` is asserted |
| md_rx_offset | max(1, log2(ALGN_DATA_WIDTH/8)) | RX byte offset. Valid while `md_rx_valid` is high and remains constant until `md_rx_ready` |
| md_rx_size | log2(ALGN_DATA_WIDTH/8)+1 | RX size in bytes. Value 0 is illegal |
| md_rx_ready | Bit | RX ready |
| md_rx_err | Bit | RX error. Valid only when both `md_rx_valid` and `md_rx_ready` are high |

Legal RX offset/size combinations:

((ALGN_DATA_WIDTH / 8) + offset) % size == 0
(size + offset) <= (ALGN_DATA_WIDTH / 8)


### MD TX Interface

| Signal Name | Signal Width | Description |
|------------|--------------|-------------|
| md_tx_valid | Bit | TX valid. Must remain high until `md_tx_ready` is asserted |
| md_tx_data | [31:0] | TX data. Valid while `md_tx_valid` is high and remains constant until `md_tx_ready` is asserted |
| md_tx_offset | max(1, log2(ALGN_DATA_WIDTH/8)) | TX byte offset. Valid while `md_tx_valid` is high and remains constant until `md_tx_ready` |
| md_tx_size | log2(ALGN_DATA_WIDTH/8)+1 | TX size in bytes. Value 0 is illegal |
| md_tx_ready | Bit | TX ready |
| md_tx_err | Bit | TX error. Valid only when both `md_tx_valid` and `md_tx_ready` are high |

Legal TX offset/size combinations:
((ALGN_DATA_WIDTH / 8) + offset) % size
(size + offset) <= (ALGN_DATA_WIDTH / 8)


### Interrupt

| Signal Name | Signal Width | Description |
|------------|--------------|-------------|
| irq | Bit | Interrupt request. All interrupt sources are ORed into this signal |

----------
## 4. UVM Architecture
<img width="485" height="427" alt="image" src="https://github.com/user-attachments/assets/7393a2c5-a801-4059-9513-46caa83dfc3f" />

----
## 5. Sequence Items

The following sequence items are used in the UVM verification environment:

- `apb_item_base`
- `apb_item_drv`
- `apb_item_mon`
- `md_item_base`
- `md_item_drv`
- `md_item_drv_master`
- `md_item_drv_slave`
- `md_item_mon`

---

## 6. Sequences

The verification environment uses the following UVM sequences:

### Virtual Sequences
- `algn_virtual_sequence_reg_access_random`
- `algn_virtual_sequence_reg_access_unmapped`
- `algn_virtual_sequence_reg_config`
- `algn_virtual_sequence_reg_status`
- `algn_virtual_sequence_rx_err`
- `algn_virtual_sequence_rx`
- `algn_virtual_sequence_slow_pace`

### APB Sequences
- `apb_sequence_base`
- `apb_sequence_random`
- `apb_sequence_rw`
- `apb_sequence_simple`

### MD Sequences
- `md_sequence_base`
- `md_sequence_base_slave`
- `md_sequence_base_master`
- `md_sequence_simple_master`
- `md_sequence_simple_slave`
- `md_sequence_slave_response`
- `md_sequence_slave_response_forever`

---

## 7. Test Scenarios

| Test Name | Scenario Description |
|----------|----------------------|
| `algn_test_reg_access` | Register access and configuration verification |
| `algn_test_random` | Constrained-random functional testing |
| `algn_test_random_rx_err` | Random testing with RX error injection |
<img width="1334" height="565" alt="image" src="https://github.com/user-attachments/assets/fe6e8549-2e84-4e3c-97f8-a17d168f99d6" />

---

## What I Have Learned

Through this project, I gained hands-on experience and a deeper understanding of the following concepts:

- Building UVM agents and understanding their roles (driver, monitor, sequencer)
- Modeling design registers using the UVM register layer
- Setting up a Device Under Test (DUT) within a UVM-based verification environment
- Verifying DUT outputs to ensure functional correctness and data integrity
- Implementing functional coverage in SystemVerilog to achieve thorough verification
- Writing and executing constrained-random tests to cover a wide range of scenarios
- Employing advanced debugging techniques to identify and resolve functional issues
- Exploring and utilizing advanced and lesser-known features of the UVM library to enhance verification quality




