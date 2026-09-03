## Clock Signal (100 MHz on Pin E3)
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk }];
#create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk }];

## Reset Button (Using Center Button N17 because it is Active High)
## We are NOT using the Red CPU_RESET because it is Active Low and your code expects Active High.
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { rst }];

## Function Buttons
## BTNU (M18) -> Start / Store
set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports { start_store_btn }];
## BTND (P18) -> Play Sequence
set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports { play_seq_btn }];

## Switches
## Switch 0-3 -> digit_in (Binary Input)
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { digit_in[0] }];
#set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports { digit_in[] }];
#set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports { digit_in[] }];
#set_property -dict { PACKAGE_PIN R15   IOSTANDARD LVCMOS33 } [get_ports { digit_in[] }];

## Switch 15 (Far Left) -> Mode Switch (0 = Single, 1 = Sequence)
set_property -dict { PACKAGE_PIN V10   IOSTANDARD LVCMOS33 } [get_ports { mode_sw }];

## LEDs
## LED 0 -> Morse Output
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { led_out }];

## Debug LEDs (Shows current State of FSM)
set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports { state_led[0] }];
set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS33 } [get_ports { state_led[1] }];
set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports { state_led[2] }];