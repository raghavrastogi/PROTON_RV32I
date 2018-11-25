# PROTON_RV32I
PROTON RV_32I is a basic microprocessor coded in Verilog which supports limited set of RISC-V Base Integer ISA. It can be dumped on a FPGA to observe the RISC-V ISA.
## Features
* Supports RISC-V Base Integer ISA version 2.2
* 5 Stage Pipelined processor.
* 4MBytes internal Memory (can be increased/decreased by changing the ADDRESS_LINES parameter in the top file).
* Supports Dual phased Clock.
* Asynchronous RESET.
## Getting Started
* Use the file in 'src/' folder to compile the processor.
* For testing the processor use the file located in 'testbench/' folder, It uses the program located in 'testCode/' folder.
## BUGS or NAME conflict
Please mail any conflict to raghavrastogi08@yahoo.co.in
