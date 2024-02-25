# Buffer Directions

## Bus Master Outputs

* Address
* TS
* TIP
* BR
* BB
* R/W
* SIZ[1:0]

## Bus Master Inputs

* TA
* TEA
* TCI
* TBI
* BG

## Bus Master Bidirectional

* Data

## Bus Slave Inputs

* Address
* TS
* TIP
* R/W
* SIZ[1:0]

## Bus Slave Outputs

* TA
* TEA
* TCI
* TBI

# Expansion Buffer States

* EXP is master
    * Address Enabled, EXP -> System
    * Data Enabled, R/W ? System -> EXP : EXP -> System

* EXP is slave
    * Address Enabled, System -> EXP
    * Data Enabled, R/W ? EXP -> System : System -> EXP
