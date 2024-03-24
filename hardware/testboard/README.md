# Errata

* MC68150's TA line is *not* open-collector! Another 74LVC1G08 AND gate should
be used to connect FPGA TA and MC68150 TA to the CPU's TA.

* U802A schematic pin markings are incorrect. At the FPGA, the following changes
need to be made:
    - LV\_SIZ1 -> R/W
    - LV\_SIZ0 -> LV\_SIZ0
    - R/W -> LV\_SIZ1
