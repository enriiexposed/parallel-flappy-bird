#
# Voltaje del interfaz de configuraciï¿½n de la FPGA
#
set_property CFGBVS VCCO [current_design];
set_property CONFIG_VOLTAGE 3.3 [current_design];

#
# Reloj del sistema: 100 MHz
#
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk];
create_clock -name sysClk -period 10.0 -waveform {0 5} [get_ports clk];

#
# Pines conectados a los pulsadores
#
set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS33 } [get_ports rst];    # btnUp

#
# Pin conectado al switch
#
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports mode];    # SW0
set_property -dict { PACKAGE_PIN R2 IOSTANDARD LVCMOS33 } [get_ports background];    # SW15
#
# Pines conectados al display 7 segmentos
#
set_property -dict { PACKAGE_PIN W7 IOSTANDARD LVCMOS33 } [get_ports {segs_n[6]}];
set_property -dict { PACKAGE_PIN W6 IOSTANDARD LVCMOS33 } [get_ports {segs_n[5]}];
set_property -dict { PACKAGE_PIN U8 IOSTANDARD LVCMOS33 } [get_ports {segs_n[4]}];
set_property -dict { PACKAGE_PIN V8 IOSTANDARD LVCMOS33 } [get_ports {segs_n[3]}];
set_property -dict { PACKAGE_PIN U5 IOSTANDARD LVCMOS33 } [get_ports {segs_n[2]}];
set_property -dict { PACKAGE_PIN V5 IOSTANDARD LVCMOS33 } [get_ports {segs_n[1]}];
set_property -dict { PACKAGE_PIN U7 IOSTANDARD LVCMOS33 } [get_ports {segs_n[0]}];
set_property -dict { PACKAGE_PIN V7 IOSTANDARD LVCMOS33 } [get_ports {segs_n[7]}];

set_property -dict { PACKAGE_PIN U2 IOSTANDARD LVCMOS33 } [get_ports {an_n[0]}];
set_property -dict { PACKAGE_PIN U4 IOSTANDARD LVCMOS33 } [get_ports {an_n[1]}];
set_property -dict { PACKAGE_PIN V4 IOSTANDARD LVCMOS33 } [get_ports {an_n[2]}];
set_property -dict { PACKAGE_PIN W4 IOSTANDARD LVCMOS33 } [get_ports {an_n[3]}];

#
# Pines conectados al USB HID (PS/2)
#
set_property -dict { PACKAGE_PIN C17 IOSTANDARD LVCMOS33 PULLUP true } [get_ports ps2Clk];
set_property -dict { PACKAGE_PIN B17 IOSTANDARD LVCMOS33 PULLUP true } [get_ports ps2Data];

#
# Pines conectados a la VGA
#
set_property -dict { PACKAGE_PIN P19 IOSTANDARD LVCMOS33 } [get_ports hSync];
set_property -dict { PACKAGE_PIN R19 IOSTANDARD LVCMOS33 } [get_ports vSync];
set_property -dict { PACKAGE_PIN N19 IOSTANDARD LVCMOS33 } [get_ports {RGB[11]}];    #R3
set_property -dict { PACKAGE_PIN J19 IOSTANDARD LVCMOS33 } [get_ports {RGB[10]}];    #R2
set_property -dict { PACKAGE_PIN H19 IOSTANDARD LVCMOS33 } [get_ports {RGB[9]}];     #R1
set_property -dict { PACKAGE_PIN G19 IOSTANDARD LVCMOS33 } [get_ports {RGB[8]}];     #R0
set_property -dict { PACKAGE_PIN D17 IOSTANDARD LVCMOS33 } [get_ports {RGB[7]}];     #G3
set_property -dict { PACKAGE_PIN G17 IOSTANDARD LVCMOS33 } [get_ports {RGB[6]}];     #G2
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports {RGB[5]}];     #G1
set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports {RGB[4]}];     #G0
set_property -dict { PACKAGE_PIN J18 IOSTANDARD LVCMOS33 } [get_ports {RGB[3]}];     #B3
set_property -dict { PACKAGE_PIN K18 IOSTANDARD LVCMOS33 } [get_ports {RGB[2]}];     #B2
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports {RGB[1]}];     #B1
set_property -dict { PACKAGE_PIN N18 IOSTANDARD LVCMOS33 } [get_ports {RGB[0]}];     #B0

#
# Pines conectados a la cámara
#
set_property -dict { PACKAGE_PIN J1   IOSTANDARD LVCMOS33 } [get_ports {cData[7]}];
set_property -dict { PACKAGE_PIN L2   IOSTANDARD LVCMOS33 } [get_ports pClk];
set_property -dict { PACKAGE_PIN J2   IOSTANDARD LVCMOS33 } [get_ports cvSync];
set_property -dict { PACKAGE_PIN G2   IOSTANDARD LVCMOS33 } [get_ports sioc];
set_property -dict { PACKAGE_PIN H1   IOSTANDARD LVCMOS33 } [get_ports {cData[6]}];
set_property -dict { PACKAGE_PIN K2   IOSTANDARD LVCMOS33 } [get_ports xClk];
set_property -dict { PACKAGE_PIN H2   IOSTANDARD LVCMOS33 } [get_ports hRef];
set_property -dict { PACKAGE_PIN G3   IOSTANDARD LVCMOS33 } [get_ports siod];
set_property -dict { PACKAGE_PIN J3   IOSTANDARD LVCMOS33 } [get_ports rst_n];
set_property -dict { PACKAGE_PIN L3   IOSTANDARD LVCMOS33 } [get_ports {cData[1]}];
set_property -dict { PACKAGE_PIN M2   IOSTANDARD LVCMOS33 } [get_ports {cData[3]}];
set_property -dict { PACKAGE_PIN N2   IOSTANDARD LVCMOS33 } [get_ports {cData[5]}];
set_property -dict { PACKAGE_PIN K3   IOSTANDARD LVCMOS33 } [get_ports pwdn];
set_property -dict { PACKAGE_PIN M3   IOSTANDARD LVCMOS33 } [get_ports {cData[0]}];
set_property -dict { PACKAGE_PIN M1   IOSTANDARD LVCMOS33 } [get_ports {cData[2]}];
set_property -dict { PACKAGE_PIN N1   IOSTANDARD LVCMOS33 } [get_ports {cData[4]}];

#
# Pines conectados al PMOD JC
#
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports speaker]