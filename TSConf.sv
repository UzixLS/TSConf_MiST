//============================================================================
//  TSConf for MiST
//
//  Port to MiST
//  Copyright (C) 2024 Eugene Lozovoy
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module TSConf_top
(
	input         CLOCK_27,
`ifdef USE_CLOCK_50
	input         CLOCK_50,
`endif

	output        LED,
	output [VGA_BITS-1:0] VGA_R,
	output [VGA_BITS-1:0] VGA_G,
	output [VGA_BITS-1:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,

`ifdef USE_HDMI
	output        HDMI_RST,
	output  [7:0] HDMI_R,
	output  [7:0] HDMI_G,
	output  [7:0] HDMI_B,
	output        HDMI_HS,
	output        HDMI_VS,
	output        HDMI_PCLK,
	output        HDMI_DE,
	inout         HDMI_SDA,
	inout         HDMI_SCL,
	input         HDMI_INT,
`endif

	input         SPI_SCK,
	inout         SPI_DO,
	input         SPI_DI,
	input         SPI_SS2,    // data_io
	input         SPI_SS3,    // OSD
	input         CONF_DATA0, // SPI_SS for user_io

`ifdef USE_QSPI
	input         QSCK,
	input         QCSn,
	inout   [3:0] QDAT,
`endif
`ifndef NO_DIRECT_UPLOAD
	input         SPI_SS4,
`endif

	output [12:0] SDRAM_A,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nWE,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nCS,
	output  [1:0] SDRAM_BA,
	output        SDRAM_CLK,
	output        SDRAM_CKE,

`ifdef DUAL_SDRAM
	output [12:0] SDRAM2_A,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_DQML,
	output        SDRAM2_DQMH,
	output        SDRAM2_nWE,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nCS,
	output  [1:0] SDRAM2_BA,
	output        SDRAM2_CLK,
	output        SDRAM2_CKE,
`endif

	output        AUDIO_L,
	output        AUDIO_R,
`ifdef I2S_AUDIO
	output        I2S_BCK,
	output        I2S_LRCK,
	output        I2S_DATA,
`endif
`ifdef I2S_AUDIO_HDMI
	output        HDMI_MCLK,
	output        HDMI_BCK,
	output        HDMI_LRCK,
	output        HDMI_SDATA,
`endif
`ifdef SPDIF_AUDIO
	output        SPDIF,
`endif
`ifdef USE_AUDIO_IN
	input         AUDIO_IN,
`endif
`ifdef USE_MIDI_PINS
	input         MIDI_IN,
	output        MIDI_OUT,
`endif
	input         UART_RX,
	output        UART_TX
);

`ifdef NO_DIRECT_UPLOAD
localparam bit DIRECT_UPLOAD = 0;
wire SPI_SS4 = 1;
`else
localparam bit DIRECT_UPLOAD = 1;
`endif

`ifdef USE_QSPI
localparam bit QSPI = 1;
assign QDAT = 4'hZ;
`else
localparam bit QSPI = 0;
`endif

`ifdef VGA_8BIT
localparam VGA_BITS = 8;
`else
localparam VGA_BITS = 6;
`endif

`ifdef USE_HDMI
localparam bit HDMI = 1;
assign HDMI_RST = 1'b1;
`else
localparam bit HDMI = 0;
`endif

`ifdef BIG_OSD
localparam bit BIG_OSD = 1;
`define SEP "-;",
`else
localparam bit BIG_OSD = 0;
`define SEP
`endif

`ifdef USE_AUDIO_IN
localparam bit USE_AUDIO_IN = 1;
`else
localparam bit USE_AUDIO_IN = 0;
`endif

`ifdef USE_MIDI_PINS
localparam bit USE_MIDI_PINS = 1;
`else
localparam bit USE_MIDI_PINS = 0;
`endif

// remove this if the 2nd chip is actually used
`ifdef DUAL_SDRAM
assign SDRAM2_A = 13'hZZZZ;
assign SDRAM2_BA = 0;
assign SDRAM2_DQML = 0;
assign SDRAM2_DQMH = 0;
assign SDRAM2_CKE = 0;
assign SDRAM2_CLK = 0;
assign SDRAM2_nCS = 1;
assign SDRAM2_DQ = 16'hZZZZ;
assign SDRAM2_nCAS = 1;
assign SDRAM2_nRAS = 1;
assign SDRAM2_nWE = 1;
`endif

`ifdef I2S_AUDIO
`ifdef I2S_AUDIO_HDMI
assign HDMI_MCLK = 0;
assign HDMI_BCK = I2S_BCK;
assign HDMI_LRCK = I2S_LRCK;
assign HDMI_SDATA = I2S_DATA;
`endif
`endif

assign LED = ~ioctl_download & ~ioctl_upload & UART_RX;

`include "build_id.v"

localparam CONF_STR = {
	"TSConf;;",
	"O78,Joystick 1,Kempston,Sinclair 1,Sinclair 2,Cursor;",
	"O9A,Joystick 2,Kempston,Sinclair 1,Sinclair 2,Cursor;",
	"O3,Swap mouse buttons,OFF,ON;",
	"O12,Scandoubler Fx,None,CRT 25%,CRT 50%,CRT 75%;",
	"O4,Vsync,49 Hz,60 Hz;",
	"O5,VDAC1,ON,OFF;",
	"O6,CPU Type,CMOS,NMOS;",
	"R256,Save NVRAM settings;",
	"T0,Reset;",
	"V,v",`BUILD_DATE
};

wire st_reset = status[0];
wire [1:0] st_joystick1 = status[8:7];
wire [1:0] st_joystick2 = status[10:9];
wire st_mouseswap = status[3];
wire [1:0] st_scanlines = status[2:1];
wire st_60hz = ~status[4];
wire st_vdac = ~status[5];
wire st_out0 = ~status[6];


////////////////////   CLOCKS   ///////////////////
wire clk_sys;
wire clk_ram;
pll pll
(
`ifdef CLOCK_IN_50
	.inclk0(CLOCK_50),
`else
	.inclk0(CLOCK_27),
`endif
	.c0(clk_ram),			// 84MHz
	.c1(clk_sys),
	.locked()
);

`ifdef CLOCK_IN_50
//    SDRAM_CLK = ~clk_ram,
`else
altclkctrl
#(
	.number_of_clocks(1),
	.clock_type("External Clock Output"),
	.ena_register_mode("none"),
	.intended_device_family("Cyclone III")
)
altclkctrl
(
	.inclk(clk_ram),
	.outclk(SDRAM_CLK)
);
`endif

reg ce_28m;
always @(negedge clk_sys) begin
	reg [1:0] div;
	
	div <= div + 1'd1;
	if(div == 2) div <= 0;
	ce_28m <= !div;
end


//////////////////   MIST ARM I/O   ///////////////////
wire  [31:0] joystick_0;
wire  [31:0] joystick_1;

wire  [1:0] buttons;
wire  [1:0] switches;
wire        scandoubler_disable;
wire        ypbpr;
wire        no_csync;
wire [63:0] status;

wire [63:0] rtc;

wire        sd_busy_mmc;
wire        sd_rd_mmc;
wire        sd_wr_mmc;
wire [31:0] sd_lba_mmc;
wire  [7:0] sd_buff_din_mmc;

wire [31:0] sd_lba = sd_lba_mmc;
wire  [1:0] sd_rd = { 1'b0, sd_rd_mmc };
wire  [1:0] sd_wr = { 1'b0, sd_wr_mmc };

wire        sd_ack;
wire  [8:0] sd_buff_addr;
wire  [7:0] sd_buff_dout;
wire  [7:0] sd_buff_din = sd_buff_din_mmc;
wire        sd_buff_wr;
wire  [1:0] img_mounted;
wire [63:0] img_size;

wire        sd_ack_conf;
wire        sd_conf;
wire        sd_sdhc;

wire        key_strobe;
wire        key_pressed;
wire        key_extended;
wire  [7:0] key_code;

wire  [8:0] mouse_x;
wire  [8:0] mouse_y;
wire  [7:0] mouse_flags;
wire        mouse_strobe;

wire        mouse_b0 = st_mouseswap? mouse_flags[0] : mouse_flags[1];
wire        mouse_b1 = st_mouseswap? mouse_flags[1] : mouse_flags[0];
wire [24:0] ps2_mouse = { mouse_strobe_level, mouse_y[7:0], mouse_x[7:0], mouse_flags[7:2], mouse_b1, mouse_b0 };
reg         mouse_strobe_level;
always @(posedge clk_sys) if (mouse_strobe) mouse_strobe_level <= ~mouse_strobe_level;

user_io #(.STRLEN($size(CONF_STR)>>3), .SD_IMAGES(2), .FEATURES(32'h0 | (BIG_OSD << 13))) user_io
(
	.clk_sys(clk_sys),
	.clk_sd(clk_sys),
	.conf_str(CONF_STR),

	.SPI_CLK(SPI_SCK),
	.SPI_SS_IO(CONF_DATA0),
	.SPI_MOSI(SPI_DI),
	.SPI_MISO(SPI_DO),

	.img_mounted(img_mounted),
	.img_size(img_size),
	.sd_conf(sd_conf),
	.sd_ack_conf(sd_ack_conf),
	.sd_sdhc(sd_sdhc),
	.sd_lba(sd_lba),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_din(sd_buff_din),
	.sd_dout(sd_buff_dout),
	.sd_dout_strobe(sd_buff_wr),

	.key_strobe(key_strobe),
	.key_code(key_code),
	.key_pressed(key_pressed),
	.key_extended(key_extended),

	.mouse_x(mouse_x),
	.mouse_y(mouse_y),
	.mouse_flags(mouse_flags),
	.mouse_strobe(mouse_strobe),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1),

	.buttons(buttons),
	.status(status),
	.scandoubler_disable(scandoubler_disable),
	.ypbpr(ypbpr),
	.no_csync(no_csync),
	.rtc(rtc)
);

wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;
wire        ioctl_download;
wire        ioctl_upload;
wire  [5:0] ioctl_index;
wire  [1:0] ioctl_ext_index;

data_io data_io
(
	.clk_sys(clk_sys),

	.SPI_SCK(SPI_SCK),
	.SPI_SS2(SPI_SS2),
	.SPI_DI(SPI_DI),
	.SPI_DO(SPI_DO),

	.clkref_n(1'b0),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_din(ioctl_din),
	.ioctl_download(ioctl_download),
	.ioctl_upload(ioctl_upload),
	.ioctl_index({ioctl_ext_index, ioctl_index})
);


reg init_reset = 1;
reg old_download;
always @(posedge clk_sys) begin
	old_download <= ioctl_download;
	if(ioctl_download) init_reset <= 1'b1;
	if(old_download & ~ioctl_download) init_reset <= 0;
end


//////////////////   SD   ///////////////////
wire        sdss;
wire        sdclk;
wire        sdmiso;
wire        sdmosi;
sd_card sd_card
(
	.clk_sys(clk_sys),
	.img_mounted(img_mounted[0]), //first slot for SD-card emulation
	.img_size(img_size),
	.sd_busy(sd_busy_mmc),
	.sd_rd(sd_rd_mmc),
	.sd_wr(sd_wr_mmc),
	.sd_lba(sd_lba_mmc),

	.sd_buff_din(sd_buff_din_mmc),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_wr(sd_buff_wr),
	.sd_buff_addr(sd_buff_addr),

	.sd_ack(sd_ack),
	.sd_ack_conf(sd_ack_conf),

	.allow_sdhc(1),
	.sd_sdhc(sd_sdhc),
	.sd_conf(sd_conf),

	.sd_cs(sdss),
	.sd_sck(sdclk),
	.sd_sdi(sdmosi),
	.sd_sdo(sdmiso)
);


////////////////////  MAIN  //////////////////////
wire [7:0] R,G,B;
wire VS, HS;
wire [15:0] SOUND_L;
wire [15:0] SOUND_R;
wire tape_out, midi_out, uart_out;

tsconf tsconf
(
	.clk(clk_sys),
	.ce(ce_28m),

	.SDRAM_DQ(SDRAM_DQ),
	.SDRAM_A(SDRAM_A),
	.SDRAM_BA(SDRAM_BA),
	.SDRAM_DQML(SDRAM_DQML),
	.SDRAM_DQMH(SDRAM_DQMH),
	.SDRAM_nWE(SDRAM_nWE),
	.SDRAM_nCAS(SDRAM_nCAS),
	.SDRAM_nRAS(SDRAM_nRAS),
	.SDRAM_CKE(SDRAM_CKE),
	.SDRAM_nCS(SDRAM_nCS),
	.SDRAM_CLK(SDRAM_CLK),

	.VRED(R),
	.VGRN(G),
	.VBLU(B),
	.VHSYNC(HS),
	.VVSYNC(VS),

	.SD_SO(sdmiso),
	.SD_SI(sdmosi),
	.SD_CLK(sdclk),
	.SD_CS_N(sdss),

	.SOUND_L(SOUND_L),
	.SOUND_R(SOUND_R),

	.COLD_RESET(init_reset | st_reset),
	.WARM_RESET(buttons[1]),
	.RTC(rtc),
	.TAPE_IN(UART_RX),
	.TAPE_OUT(tape_out),
	.MIDI_OUT(midi_out),
	.UART_RX(UART_RX),
	.UART_TX(uart_out),

	.CFG_OUT0(st_out0),
	.CFG_60HZ(st_60hz),
	.CFG_SCANDOUBLER(1'b0),
	.CFG_VDAC(st_vdac),
	.CFG_JOYSTICK1(st_joystick1),
	.CFG_JOYSTICK2(st_joystick2),

	.PS2_KEY({key_strobe,key_pressed,key_extended,key_code}),
	.PS2_MOUSE(ps2_mouse),
	.JOYSTICK1({joystick_0[9:8], joystick_0[5:0]}),
	.JOYSTICK2({joystick_1[9:8], joystick_1[5:0]}),

	.loader_act(ioctl_download),
	.loader_addr(ioctl_addr[15:0]),
	.loader_do(ioctl_dout),
	.loader_di(ioctl_din),
	.loader_wr(ioctl_wr),
	.loader_cs_rom_main(ioctl_index == 6'h0),
	.loader_cs_rom_gs(ioctl_index == 6'h1),
	.loader_cs_cmos(ioctl_index == 6'h3f)
);


//////////////////  UART_TX  //////////////////
reg uart_tx = 1'b1;
reg tape_out_old = 1'b0;
reg midi_out_old = 1'b0;
reg uart_out_old = 1'b0;

always @(posedge clk_sys) begin
	if (tape_out_old != tape_out) begin
		tape_out_old <= tape_out;
		uart_tx <= tape_out;
	end
	if (midi_out_old != midi_out) begin
		midi_out_old <= midi_out;
		uart_tx <= midi_out;
	end
	if (uart_out_old != uart_out) begin
		uart_out_old <= uart_out;
		uart_tx <= uart_out;
	end
end

assign UART_TX = uart_tx;


//////////////////   VIDEO   ///////////////////
reg VSync, HSync;
always @(posedge clk_sys) begin
	HSync <= HS;
	if(~HSync & HS) VSync <= VS;
end

mist_video #(.COLOR_DEPTH(8), .SD_HCNT_WIDTH(11), .OUT_COLOR_DEPTH(VGA_BITS), .BIG_OSD(BIG_OSD)) mist_video (
	.clk_sys     ( clk_sys    ),

	// OSD SPI interface
	.SPI_SCK     ( SPI_SCK    ),
	.SPI_SS3     ( SPI_SS3    ),
	.SPI_DI      ( SPI_DI     ),

	// scanlines (00-none 01-25% 10-50% 11-75%)
	.scanlines   ( st_scanlines  ),

	// non-scandoubled pixel clock divider 0 - clk_sys/4, 1 - clk_sys/2
	.ce_divider  ( 3'd2       ),

	// 0 = HVSync 31KHz, 1 = CSync 15KHz
	.scandoubler_disable ( scandoubler_disable ),
	// disable csync without scandoubler
	.no_csync    ( no_csync   ),
	// YPbPr always uses composite sync
	.ypbpr       ( ypbpr      ),
	// Rotate OSD [0] - rotate [1] - left or right
	.rotate      ( 2'b00      ),
	// composite-like blending
	.blend       ( 1'b0       ),

	// video in
	.R           ( R ),
	.G           ( G ),
	.B           ( B ),

	.HSync       ( HSync      ),
	.VSync       ( VSync      ),

	// MiST video output signals
	.VGA_R       ( VGA_R      ),
	.VGA_G       ( VGA_G      ),
	.VGA_B       ( VGA_B      ),
	.VGA_VS      ( VGA_VS     ),
	.VGA_HS      ( VGA_HS     )
);


//////////////////   SOUND   ///////////////////

wire DAC_L, DAC_R;

//hybrid_pwm_sd_2ndorder #(.signalwidth(16)) dac (
//	.clk(clk_sys & ce_28m),
//	.reset_n(~init_reset),
//	.d_l({~SOUND_L[15], SOUND_L[14:0]}),
//	.q_l(dac_l),
//	.d_r({~SOUND_R[15], SOUND_R[14:0]}),
//	.q_r(dac_r)
//);

reg [23:0] mute_cnt = 0;
always @(posedge clk_sys) begin
	if (init_reset)
		mute_cnt <= 1;
	else if (mute_cnt && ce_28m)
		mute_cnt <= mute_cnt + 1'b1;
end
assign AUDIO_L = mute_cnt? 1'bZ : DAC_L;
assign AUDIO_R = mute_cnt? 1'bZ : DAC_R;


////////////////////////////////////////////////////////

sigma_delta_dac #(10) dac_l
(
	//.CLK(clk_sys && ce_28m),
	.CLK(clk_sys),
	.RESET(~init_reset),
	//.DACin(SOUND_L),
	.DACin({~SOUND_L[15], SOUND_L[14:0]}),
	.DACout(DAC_L)
);

sigma_delta_dac #(10) dac_r
(
	//.CLK(clk_sys && ce_28m),
	.CLK(clk_sys),
	.RESET(~init_reset),
	//.DACin(SOUND_R),
	.DACin({~SOUND_R[15], SOUND_R[14:0]}),
	.DACout(DAC_R)
);

`ifdef I2S_AUDIO
i2s i2s (
	.reset(init_reset),
	.clk(clk_sys),
	.clk_rate(32'd84_000_000),

	.sclk(I2S_BCK),
	.lrclk(I2S_LRCK),
	.sdata(I2S_DATA),

	.left_chan({{~SOUND_L[15]}, SOUND_L[14:0]}),
	//.left_chan(SOUND_L),
	.right_chan({{~SOUND_R[15]}, SOUND_R[14:0]})
	//.right_chan(SOUND_R)
);
`endif

`ifdef I2S_AUDIO_HDMI
assign HDMI_MCLK = 0;
always @(posedge clk_sys) begin
	HDMI_BCK <= I2S_BCK;
	HDMI_LRCK <= I2S_LRCK;
	HDMI_SDATA <= I2S_DATA;
end
`endif

`ifdef SPDIF_AUDIO
spdif spdif (
	.clk_i(clk_sys),
	.rst_i(init_reset),
	.clk_rate_i(32'd84_000_000),
	.spdif_o(SPDIF),
	.sample_i({{~SOUND_L[15]}, SOUND_L[14:0], {~SOUND_R[15]}, SOUND_R[14:0]})
);
`endif

endmodule
