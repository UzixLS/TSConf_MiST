# Clock constraints

create_clock -name "CLOCK_27" -period 37.037 [get_ports {CLOCK_27}]
create_clock -name {SPI_SCK}  -period 41.666 -waveform { 20.8 41.666 } [get_ports {SPI_SCK}]

# Automatically constrain PLL and other generated clocks
derive_pll_clocks -create_base_clocks

# Automatically calculate clock uncertainty to jitter and other effects.
derive_clock_uncertainty

# Clock groups
set_clock_groups -asynchronous -group [get_clocks {SPI_SCK}] -group [get_clocks {pll|altpll_component|auto_generated|pll1|clk[*]}]

# SDRAM
set_input_delay -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -reference_pin [get_ports SDRAM_CLK] -max 6.4 [get_ports SDRAM_DQ[*]]
set_input_delay -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -reference_pin [get_ports SDRAM_CLK] -min 3.2 [get_ports SDRAM_DQ[*]]

# SDRAM: max(tCMS, tAS, tDS) = 1.5ns ; max(tCMH, tAH, tDH) = 0.8ns
set_output_delay -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -reference_pin [get_ports SDRAM_CLK] -max 1.5 [get_ports {SDRAM_D* SDRAM_A* SDRAM_BA* SDRAM_n* SDRAM_CKE}]
set_output_delay -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -reference_pin [get_ports SDRAM_CLK] -min -0.8 [get_ports {SDRAM_D* SDRAM_A* SDRAM_BA* SDRAM_n* SDRAM_CKE}]

# SDRAM_CLK to internal memory clock
set_multicycle_path -from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 2

# Some relaxed constrain to the VGA pins. The signals should arrive together, the delay is not really important.
set_output_delay -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -max 0 [get_ports {VGA_*}]
set_output_delay -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -min -5 [get_ports {VGA_*}]
set_multicycle_path -to [get_ports {VGA_*}] -setup 5
set_multicycle_path -to [get_ports {VGA_*}] -hold 4

set_false_path -to {dac:*}
set_false_path -to [get_ports {AUDIO_L}]
set_false_path -to [get_ports {AUDIO_R}]
set_false_path -to [get_ports {LED}]
set_false_path -from [get_ports {UART_RX}]

set_multicycle_path -from {tsconf|CPU|*} -setup 2
set_multicycle_path -from {tsconf|CPU|*} -hold 1
set_multicycle_path -to {tsconf|CPU|*} -setup 2
set_multicycle_path -to {tsconf|CPU|*} -hold 1

set_multicycle_path -to {tsconf|saa1099|*} -setup 2
set_multicycle_path -to {tsconf|saa1099|*} -hold 1

set_multicycle_path -to {tsconf|gs|*} -setup 2
set_multicycle_path -to {tsconf|gs|*} -hold 1
