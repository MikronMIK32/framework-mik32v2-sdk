# framework-mik32v2-sdk

Repository for the MIK32V2 microcontroller support in the Platformio IDE.

## Contents of the folders:

* hal/ - contains libraries for programming MIK32V0 peripherals
* openocd/share/openocd/scripts/ - scripts of the OpenOCD debugger
  * include_eeprom.tcl - script for flashing the built-in EEPROM (pass the path of hex file to the function eeprom_write_file)
  * interface/ftdi/ - JTAG emulator configuration scripts, based on ftdi chip
  * target/ - scripts to set debugging target (use mik32.cfg)
* shared/ - contains header files, startup files, linking scripts and some basic libraries related to MIK32 V1
