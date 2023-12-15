Signals which come from 68040 exclusively
---

- ~{BR}
- ~{RSTO}
- ~{LOCK}
- ~{LOCKE}
- ~{TIP}

68040 Snoop Signals
---

- ~{TS}
- ~{TA}
- ~{TCI}
- TT[0..1]
- SIZ[0..1]
- SC[0..1]
- R/~{W}

Signals which bus masters drive (68040 and others, buffer these to FPGA, CPLD)
---

- R/~{W}
- SIZ[0..1]
- ~{TS}

Signals which bus slaves drive
---

- ~{TBI}
