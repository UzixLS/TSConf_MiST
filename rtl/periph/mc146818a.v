module mc146818a
(
   input            RESET,
   input            CLK,
   input            ENA,
   input            CS,

   input     [64:0] RTC,
   input      [7:0] KEYSCANCODE,
   output  reg      KEYSCANCODE_ACK,
   output  reg      KEYSCANCODE_CLR,

   input            RD,
   input            WR,
   input      [7:0] A,
   input      [7:0] DI,
   output reg [7:0] DO,

   input            loader_WR,
   input      [7:0] loader_A,
   input      [7:0] loader_DI,
   output     [7:0] loader_DO
);

reg [18:0] pre_scaler =0;
reg  [1:0] leap_reg =0;
reg  [7:0] seconds_reg =0;        // 00
reg  [7:0] seconds_alarm_reg =0;  // 01
reg  [7:0] minutes_reg =0;        // 02
reg  [7:0] minutes_alarm_reg = 0; // 03
reg  [7:0] hours_reg =0;          // 04
reg  [7:0] hours_alarm_reg ='hff; // 05
reg  [7:0] weeks_reg = 1;         // 06
reg  [7:0] days_reg = 1;          // 07
reg  [7:0] month_reg = 1;         // 08
reg  [7:0] year_reg = 0;          // 09
reg  [7:0] a_reg;                 // 0A
reg  [7:0] b_reg = 8'b00000010;   // 0B
reg  [7:0] c_reg;                 // 0C


reg keyrd_enable = 0;
reg keyrd = 0;
always @(posedge CLK) begin
  KEYSCANCODE_ACK <= !RD && keyrd;
  keyrd <= keyrd_enable && RD && CS && A[7:4] == 4'hf;
end


wire [7:0] CMOS_Dout;
always @(posedge CLK) begin
  if (RD & CS) begin
    casez (A[7:0])
    8'h00 : DO <= seconds_reg;
    8'h01 : DO <= seconds_alarm_reg;
    8'h02 : DO <= minutes_reg;
    8'h03 : DO <= minutes_alarm_reg;
    8'h04 : DO <= hours_reg;
    8'h05 : DO <= hours_alarm_reg;
    8'h06 : DO <= weeks_reg;
    8'h07 : DO <= days_reg;
    8'h08 : DO <= month_reg;
    8'h09 : DO <= year_reg;
    8'h0a : DO <= a_reg;
    8'h0b : DO <= b_reg;
    8'h0c : DO <= c_reg;
    8'h0d : DO <= 8'b10000000;

    8'hf? : DO <= KEYSCANCODE;
    default: DO <= CMOS_Dout;
    endcase
  end
end


always @(posedge CLK) begin
  KEYSCANCODE_CLR <= 1'b0;

  if (RTC[62] && !b_reg[7]) begin
    seconds_reg <= RTC[7:0];
    minutes_reg <= RTC[15:8];
    hours_reg   <= RTC[23:16];
    days_reg    <= RTC[31:24];
    month_reg   <= RTC[39:32];
    year_reg    <= RTC[47:40];
    weeks_reg   <= RTC[55:48] + 1'b1;
    b_reg       <= 8'b00000010;
  end

  if (RESET) b_reg <= 8'b00000010;
  else if (WR & CS) begin
    casez (A[7:0])
      8'h00 : seconds_reg       <= DI;
      8'h01 : seconds_alarm_reg <= DI;
      8'h02 : minutes_reg       <= DI;
      8'h03 : minutes_alarm_reg <= DI;
      8'h04 : hours_reg         <= DI;
      8'h05 : hours_alarm_reg   <= DI;
      8'h06 : weeks_reg         <= DI;
      8'h07 : days_reg          <= DI;
      8'h08 : month_reg         <= DI;
      8'h09 : year_reg          <= DI;
      8'h0b : begin
        b_reg <= DI;
        if (b_reg[2] == 1'b0) begin  // BCD to BIN convertion
          if (DI[4] == 1'b0) leap_reg <= DI[1:0];
          else leap_reg <= {~DI[1], DI[0]};
        end
        else begin
          leap_reg <= DI[1:0];
        end
      end
      8'h0c : KEYSCANCODE_CLR <= DI[0];
      8'hf? : keyrd_enable <= (DI == 8'd2)? 1'b1 : 1'b0;
    endcase
  end

  if (RESET) begin
    a_reg <= 8'b00100110;
    c_reg <= 0;
  end
  else if (~b_reg[7] & ENA) begin
    if (pre_scaler) begin
      pre_scaler <= pre_scaler - 1'd1;
      a_reg[7] <= 0;
    end
    else begin
      pre_scaler <= 437500; //(0.4375MHz)
      a_reg[7] <= 1;
      c_reg[4] <= 1;
      // alarm
      if ((seconds_reg == seconds_alarm_reg) && (minutes_reg == minutes_alarm_reg) && (hours_reg == hours_alarm_reg)) c_reg[5] <= 1'b1;

      if (~b_reg[2]) begin
        // DM binary-coded-decimal (BCD) data mode
        if (seconds_reg[3:0] != 9) seconds_reg[3:0] <= seconds_reg[3:0] + 1'd1;
        else begin
          seconds_reg[3:0] <= 0;
          if (seconds_reg[6:4] != 5) seconds_reg[6:4] <= seconds_reg[6:4] + 1'd1;
          else begin
            seconds_reg[6:4] <= 0;
            if (minutes_reg[3:0] != 9) minutes_reg[3:0] <= minutes_reg[3:0] + 1'd1;
            else begin
              minutes_reg[3:0] <= 0;
              if (minutes_reg[6:4] != 5) minutes_reg[6:4] <= minutes_reg[6:4] + 1'd1;
              else begin
                minutes_reg[6:4] <= 0;
                if (hours_reg[3:0] == 9) begin
                  hours_reg[3:0] <= 0;
                  hours_reg[5:4] <= hours_reg[5:4] + 1'd1;
                end
                else if ({b_reg[1], hours_reg[7], hours_reg[4:0]} == 7'b0010010) begin
                  hours_reg[4:0] <= 1;
                  hours_reg[7] <= ~hours_reg[7];
                end
                else if (({b_reg[1], hours_reg[7], hours_reg[4:0]} != 7'b0110010) &&
                    ({b_reg[1], hours_reg[5:0]} != 7'b1100011)) hours_reg[3:0] <= hours_reg[3:0] + 1'd1;
                else begin
                  if (~b_reg[1]) hours_reg[7:0] <= 1;
                  else hours_reg[5:0] <= 0;

                  if (weeks_reg[2:0] != 7) weeks_reg[2:0] <= weeks_reg[2:0] + 1'd1;
                  else weeks_reg[2:0] <= 1;

                  if (({month_reg, days_reg, leap_reg} == {16'h0228, 2'b01}) ||
                    ({month_reg, days_reg, leap_reg} == {16'h0228, 2'b10}) ||
                    ({month_reg, days_reg, leap_reg} == {16'h0228, 2'b11}) ||
                    ({month_reg, days_reg, leap_reg} == {16'h0229, 2'b00}) ||
                    ({month_reg, days_reg} == 16'h0430) ||
                    ({month_reg, days_reg} == 16'h0630) ||
                    ({month_reg, days_reg} == 16'h0930) ||
                    ({month_reg, days_reg} == 16'h1130) ||
                    (days_reg == 8'h31)) begin

                    days_reg[5:0] <= 1;
                    if (month_reg[3:0] == 9) month_reg[4:0] <= 'h10;
                    else if (month_reg[4:0] != 'h12) month_reg[3:0] <= month_reg[3:0] + 1'd1;
                    else begin
                      month_reg[4:0] <= 1;
                      leap_reg[1:0] <= leap_reg[1:0] + 1'd1;
                      if (year_reg[3:0] != 9) year_reg[3:0] <= year_reg[3:0] + 1'd1;
                      else begin
                        year_reg[3:0] <= 0;
                        if (year_reg[7:4] != 9) year_reg[7:4] <= year_reg[7:4] + 1'd1;
                        else year_reg[7:4] <= 0;
                      end
                    end
                  end
                  else if (days_reg[3:0] != 9) days_reg[3:0] <= days_reg[3:0] + 1'd1;
                  else begin
                    days_reg[3:0] <= 0;
                    days_reg[5:4] <= days_reg[5:4] + 1'd1;
                  end
                end
              end
            end
          end
        end
      end
      else begin
        // DM binary data mode
        if (seconds_reg != 8'h3B) seconds_reg <= seconds_reg + 1'd1;
        else begin
          seconds_reg <= 0;
          if (minutes_reg != 8'h3B) minutes_reg <= minutes_reg + 1'd1;
          else begin
            minutes_reg <= 0;
            if ({b_reg[1], hours_reg[7], hours_reg[3:0]} == 6'b001100) hours_reg[7:0] <= 8'b10000001;
            else if (({b_reg[1], hours_reg[7], hours_reg[3:0]} != 6'b011100) & ({b_reg[1], hours_reg[4:0]} != 6'b110111)) hours_reg[4:0] <= hours_reg[4:0] + 1'd1;
            else begin
              if (b_reg[1] == 1'b0) hours_reg[7:0] <= 1;
              else hours_reg <= 0;

              if (weeks_reg != 7) weeks_reg <= weeks_reg + 1'd1;
              else weeks_reg <= 1;  // Sunday = 1

              if (({month_reg, days_reg, leap_reg} == {16'h021C, 2'b01}) | ({month_reg, days_reg, leap_reg} == {16'h021C, 2'b10}) | ({month_reg, days_reg, leap_reg} == {16'h021C, 2'b11}) | ({month_reg, days_reg, leap_reg} == {16'h021D, 2'b00}) | ({month_reg, days_reg} == 16'h041E) | ({month_reg, days_reg} == 16'h061E) | ({month_reg, days_reg} == 16'h091E) | ({month_reg, days_reg} == 16'h0B1E) | (days_reg == 8'h1F)) begin
                days_reg <= 1;
                if (month_reg != 8'h0C) month_reg <= month_reg + 1'd1;
                else begin
                  month_reg <= 1;
                  leap_reg[1:0] <= leap_reg[1:0] + 1'd1;
                  if (year_reg != 8'h63) year_reg <= year_reg + 1'd1;
                  else year_reg <= 0;
                end
              end else days_reg <= days_reg + 1'd1;
            end
          end
        end
      end
    end
  end
end

// 50 Bytes of General Purpose RAM
dpram #(.DATAWIDTH(8), .ADDRWIDTH(8), .MEM_INIT_FILE("rtl/periph/CMOS.mif")) CMOS
(
  .clock      (CLK),
  .address_a  (A),
  .data_a     (DI),
  .wren_a     (WR & CS),
  .q_a        (CMOS_Dout),
  .address_b  (loader_A),
  .data_b     (loader_DI),
  .wren_b     (loader_WR),
  .q_b        (loader_DO)
);

endmodule
