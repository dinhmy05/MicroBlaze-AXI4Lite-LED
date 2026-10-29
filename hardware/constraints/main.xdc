## ZedBoard XC7Z020-CLG484-1 - Proposed constraints
## 100MHz PL oscillator, bank13 fixed 3.3V
set_property PACKAGE_PIN Y9 [get_ports {sys_clock}]
set_property IOSTANDARD LVCMOS33 [get_ports {sys_clock}]
create_clock -period 10.000 -name sys_clock [get_ports {sys_clock}]

## SW0 used as active-low reset: SW0=0 RESET, SW0=1 RUN
## Check ZedBoard Bank35 VADJ is 1.8V before using LVCMOS18.
set_property PACKAGE_PIN F22 [get_ports {sys_reset_n[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {sys_reset_n[0]}]

## ZedBoard LD0 LD1 LD2 LD3, bank33 fixed 3.3V
set_property PACKAGE_PIN T22 [get_ports {led_out[0]}]
set_property PACKAGE_PIN T21 [get_ports {led_out[1]}]
set_property PACKAGE_PIN U22 [get_ports {led_out[2]}]
set_property PACKAGE_PIN U21 [get_ports {led_out[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_out[*]}]
