# Ideas

* Use a tiered boot system. The FPGA can provide a bootstrap ROM routine which loads a stage 2 from the SPI flash chip (the same one used for the FPGA configuration) into SRAM.
* Use ATF1508 for the DRAM controller. This leaves more pins for a non-BGA FPGA to be useful.

# Problems

* How to power-on reset, keep the CPU in reset while the FPGA is being configured.
    * Probably simple logic gates combining CDONE pin from FPGA with power-on reset circuitry.
