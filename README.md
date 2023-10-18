# 6111-Final-Project

Copy the remote directory from one of your labs 

To compile and upload:
`./remote/r.py build.py build.tcl hdl/top_level.sv hdl/hdmi_clk_vis.v hdl/tm_choice.sv hdl/tmds_encoder.sv hdl/tmds_serializer.sv hdl/video_sig_gen.sv hdl/raymarcher.sv hdl/xilinx_true_dual_port_read_first_2_clock_ram.v hdl/renderer.sv xdc/top_level.xdc obj/ && openFPGALoader -b arty_s7_50 obj/final.bit`

To run raymarcher test bench
iverilog -g2012 -o sim/sim.out sim/raymarcher_tb.sv hdl/raymarcher.sv && vvp sim/sim.out


RAHHHHH
 AIDAN BLUM LEVINE METAVERESE


#I HATE AIDAN
