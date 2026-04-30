# MLP Engine
<p align="center">
<img src=https://github.com/novwaul/MNIST-Accelerator/assets/53179332/e5473804-e3cc-4958-ba5a-be8593f5d748>
</p>

<p align="center">
The MNIST Classifier for Acceleration
</p>
  
## Motivation

### Baseline Issues
In the baseline case, there are too many accesses to external memory, resulting in excessive power consumption and total time delay. This is because the external memory is physically located far from the scalar core, and access to the external memory is fixed at 40ns. We aimed to reduce these overheads by utilizing SRAM to store calculated data (input, bias) and intermediate values of the calculation process.

### Instruction Cache
For the instruction cache, control is based on addresses. Applying this method to data control was deemed to be hardware inefficient, so we aimed to implement data control in software.

### Input Data Processing
We determined that input data forming an image being input to the scalar core one by one is inefficient, and sought to reduce total time and operational cycles by simultaneously processing a large amount of input data.

### Testing Robustness
We aimed to adjust the baseline environment to maintain significant accuracy and ensure that the techniques used operate robustly and efficiently even with an increased number of tests.

### PnR Verification
After completing PnR, we aimed to obtain results to ensure that Team 15's design operates effectively within the maximum metal available in the given process.

## Technique

<p align="center">
<img src=https://github.com/novwaul/MNIST-Accelerator/assets/53179332/4c8b91e2-b310-467f-bcd3-c8313822cb30>
</p>

We implemented a Systolic Array and Scratch Pad, both managed by software using unused instructions as control commands. Additionally, data compression was used to reduce the bit size required for data operations and storage.




### Software
Based on the baseline software, we modified the code to process four images simultaneously in the Systolic Array. All biases were managed in the Scratch Pad, and the inputs and outputs of Layer 1 and Layer 2, and the inputs of Layer 3 were stored in the Scratch Pad. As the inputs of the previous layer are not needed in the current layer, the Scratch Pad was managed by overwriting the input of the previous layer with the output of the current layer. Lastly, the code was modified to output control commands during compilation to control the Systolic Array and Scratch Pad as intended.

### Hardware

#### Memory Mapping
The proposed hardware memory mapping is as follows. Addresses from 0x4000 to 0x5000 are pre-allocated to the Scratch Pad, and data can be freely placed in all other addresses.

#### Instruction Set Mapping
The control commands for the Systolic Array and Scratch Pad are as follows.

#### Systolic Array
The Systolic Array operates using the Output Stationary method, receiving 9-bit input data. It consists of a 4x4 Processing Element (PE) grid, a 4x4 PE Buffer for bias and partial sums, and an 8x1 Data Buffer for inputs and weights. Each element of the PE Buffer has a size of 18 bits, and each element of the Data Buffer has a size of 9 bits. Each PE is directly connected to the PE Buffer and Data Buffer, and all PEs perform the same operation when executing the MULH or MULHU instructions.

#### Scratch Pad
The Systolic Array uses memory addresses from 0x4000 to 0x5000 and is composed of four 1024x8 SRAMs. Managed by software, it does not have valid and tag bits, and data is stored in a compressed 8-bit format for efficient use of storage space. The total number of bias data is 202, and the maximum number of input and output data are 3136 and 512 respectively. Thus, a 4KB capacity was chosen to accommodate all required data.

#### Instruction Explanation
- **LB**: Transfers bias from Scratch Pad to Systolic Array PE Buffer
- **LBU**: Transfers data from Systolic Array PE Buffer to Scratch Pad
- **LH**: Transfers data from Scratch Pad to Systolic Array Data Buffer
- **LHU**: Transfers data from External Memory to Systolic Array Data Buffer
- **SB**: Transfers data from Systolic Array PE Buffer to External Memory
- **SH**: Transfers data from External Memory to Scratch Pad
- **MULH**: Performs Multiply-Accumulation (MAC) in the Systolic Array PE
- **MULHU**: Converts negative values to zero in the Systolic Array PE (ACT)

### Data Compression

All data entering the Systolic Array is extracted from the 9~2 bits of the original 32-bit data, concatenating LSB 1. Therefore, the Scratch Pad also stores only the 9 ~ 2 bits of the 32-bit data. The intermediate output calculated by the Systolic Array is 18 bits, but since the storage size is set to 9 bits, a compression process is necessary. If the MSB of the 18-bit data is 1, all 9 bits are set to 1 (Maximum Value), otherwise, the data is stored by adding the 8th bit value to the 17 ~ 9 bits of data (Rounding).

## Performance Evaluation
All the results are based on PnR Report. Confirmed that accuracy, power consumption, area, and mcycle are in a trade-off relationship.

| Metric       | Baseline (100%)      | Our Design          |
|--------------|:----------------------:|:---------------------:|
| Time delay (ns) | 10.51             | 10.80 (102.76%)     |
| Total power (mW) | 2.91             | 3.46 (119%)         |
| Cell area (netlist and physical only) | 59729.98          | 179569.94 (301%)    |

### Mcycle (16 bit)
| Metric       | #10         | #100       | #1000      | #10000      | 
|--------------|:-------------:|:------------:|:------------:|:-------------:|
| Baseline     | 08f09001(100%)    | 596590d6(100%)   | 37df7940f(100%)  | None    |
| Our Design   |  031fe760(35%)   | 1a0866ae(29%)  | 10451f842(29%)|   a2b336cb9*          |

*The #10000 values are obtained by dividing 10000 into 1000 each and summing the results.

### Accuracy (%)
| Metric       | #10         | #100       | #1000      | #10000      | 
|--------------|-------------|------------|------------|-------------|
| Baseline     | 100.00      | 99.00      | 96.50      | 96.76       |
| Our Design   | 100.00      | 99.00      | 91.80      | 92.68**     |

**The #10000 values are averages obtained by dividing 10000 into 1000 each and averaging the results.


## Collaborator
- **Ju-Hyung Yeon**, KAIST EE MS candidate
