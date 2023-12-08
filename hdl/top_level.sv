`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
 
module top_level(
  input wire clk_100mhz, //crystal reference clock
  input wire [15:0] sw, //all 16 input slide switches
  input wire [3:0] btn, //all four momentary button switches
  inout wire [7:0] pmodb, //pmodb input (8 bit)
  output logic uart_txd,
  input wire uart_rxd,
  output logic [15:0] led, //16 green output LEDs (located right above switches)
  output logic [2:0] rgb0, //rgb led
  output logic [2:0] rgb1, //rgb led
  output logic [2:0] hdmi_tx_p, //hdmi output signals (positives) (blue, green, red)
  output logic [2:0] hdmi_tx_n, //hdmi output signals (negatives) (blue, green, red)
  output logic hdmi_clk_p, hdmi_clk_n //differential hdmi clock
  );

  logic clk_100mhz_buffed;
  BUFG mbf (.I(clk_100mhz), .O(clk_100mhz_buffed));
  // manta manta_inst (
  //   .clk(clk_100mhz_buffed),

  //   .rx(uart_rxd),
  //   .tx(uart_txd),
    
  //   .gx(camera_forward_x), 
  //   .gy(camera_forward_y), 
  //   .gz(camera_forward_z));
 
  assign led = sw; //to verify the switch values
  //shut up those rgb LEDs (active high):
  assign rgb1= 0;
  assign rgb0 = 0;
  /* have btnd control system reset */
  logic sys_rst;
  assign sys_rst = btn[0];
 
  logic clk_pixel, clk_5x; //clock lines
  logic locked; //locked signal (we'll leave unused but still hook it up)

  //clock manager...creates 74.25 Hz and 5 times 74.25 MHz for pixel and TMDS
  hdmi_clk_wiz_720p mhdmicw (
      .reset(0),
      .locked(locked),
      .clk_ref(clk_100mhz_buffed),
      .clk_pixel(clk_pixel),
      .clk_tmds(clk_5x));

  logic [10:0] hcount; //hcount of system!
  logic [9:0] vcount; //vcount of system!
  logic hor_sync; //horizontal sync signal
  logic vert_sync; //vertical sync signal
  logic active_draw; //ative draw! 1 when in drawing region.0 in blanking/sync
  logic new_frame; //one cycle active indicator of new frame of info!
  logic [5:0] frame_count; //0 to 59 then rollover frame counter

  //written by you! (make sure you include in your hdl)
  //default instantiation so making signals for 720p
  video_sig_gen mvg(
      .clk_pixel_in(clk_pixel),
      .rst_in(sys_rst),
      .hcount_out(hcount),
      .vcount_out(vcount),
      .vs_out(vert_sync),
      .hs_out(hor_sync),
      .ad_out(active_draw),
      .nf_out(new_frame),
      .fc_out(frame_count));

  logic [7:0] red, green, blue; //red green and blue pixel values for output

  logic clk_pixel_divided_buffed, clk_pixel_divided;
  BUFG mbf_clk_pixel_divided (.I(clk_pixel_divided), .O(clk_pixel_divided_buffed));

  // Clock divider to generate a clock that is half as fast as clk_pixel
  always_ff @(posedge clk_pixel) begin
    if (sys_rst) begin
      clk_pixel_divided <= 1'b0;
    end else begin
      clk_pixel_divided <= ~clk_pixel_divided;
    end
  end

  logic signed [32-1:0] camera_up_x;
  logic signed [32-1:0] camera_up_y;
  logic signed [32-1:0] camera_up_z;
  logic signed [32-1:0] camera_right_x;
  logic signed [32-1:0] camera_right_y;
  logic signed [32-1:0] camera_right_z;
  logic signed [32-1:0] camera_forward_x;
  logic signed [32-1:0] camera_forward_y;
  logic signed [32-1:0] camera_forward_z;
  renderer #(
    .WIDTH(320),
    .HEIGHT(180)
  ) mrender (
    .clk_in(clk_pixel_divided_buffed),
    .rst_in(sys_rst),
    .hcount_in(hcount >> 2),
    .vcount_in(vcount >> 2),
    .red_out(red),
    .green_out(green),
    .blue_out(blue),
    .camera_u_x_raw(camera_right_x),
    .camera_u_y_raw(camera_right_y),
    .camera_u_z_raw(camera_right_z),
    .camera_v_x_raw(camera_up_x),
    .camera_v_y_raw(camera_up_y),
    .camera_v_z_raw(camera_up_z),
    .camera_forward_x_raw((~camera_forward_x + 1) <<< 7),
    .camera_forward_y_raw((~camera_forward_y + 1) <<< 7),
    .camera_forward_z_raw((~camera_forward_z + 1) <<< 7) // *128 scaling here is how far the projection plane 
  );

  logic [9:0] tmds_10b [0:2]; //output of each TMDS encoder!
  logic tmds_signal [2:0]; //output of each TMDS serializer!
  tmds_encoder tmds_red(
      .clk_in(clk_pixel),
      .rst_in(sys_rst),
      .data_in(red),
      .control_in(2'b0),
      .ve_in(active_draw),
      .tmds_out(tmds_10b[2]));
  tmds_encoder tmds_green(
      .clk_in(clk_pixel),
      .rst_in(sys_rst),
      .data_in(green),
      .control_in(2'b0),
      .ve_in(active_draw),
      .tmds_out(tmds_10b[1]));
  tmds_encoder tmds_blue(
      .clk_in(clk_pixel),
      .rst_in(sys_rst),
      .data_in(blue),
      .control_in({vert_sync, hor_sync}),
      .ve_in(active_draw),
      .tmds_out(tmds_10b[0]));
  tmds_serializer red_ser(
      .clk_pixel_in(clk_pixel),
      .clk_5x_in(clk_5x),
      .rst_in(sys_rst),
      .tmds_in(tmds_10b[2]),
      .tmds_out(tmds_signal[2]));
  tmds_serializer green_ser(
      .clk_pixel_in(clk_pixel),
      .clk_5x_in(clk_5x),
      .rst_in(sys_rst),
      .tmds_in(tmds_10b[1]),
      .tmds_out(tmds_signal[1]));
  tmds_serializer blue_ser(
      .clk_pixel_in(clk_pixel),
      .clk_5x_in(clk_5x),
      .rst_in(sys_rst),
      .tmds_in(tmds_10b[0]),
      .tmds_out(tmds_signal[0]));
  OBUFDS OBUFDS_blue (.I(tmds_signal[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
  OBUFDS OBUFDS_green(.I(tmds_signal[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
  OBUFDS OBUFDS_red  (.I(tmds_signal[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
  OBUFDS OBUFDS_clock(.I(clk_pixel), .O(hdmi_clk_p), .OB(hdmi_clk_n));

  // Generates a 50mhz clk
  logic clk_50MHz;
  always @(posedge clk_100mhz_buffed) begin
      clk_50MHz <= ~clk_50MHz;
  end
  // Gyroscope interface
  logic [15:0] gx, gy, gz;
  mpu_rg mpu6050(
      .CLOCK_50(clk_50MHz),
      .en(1'b1),
      .reset_n(~sys_rst),
      .I2C_SDAT(pmodb[1]),
      .I2C_SCLK(pmodb[2]),
      .gx(gx),
      .gy(gy),
      .gz(gz)
  );

  logic normalizeGyro;
  assign normalizeGyro = sw[0];

  logic [8:0] counter;
  logic [64:0] gx_norm, gy_norm, gz_norm;
  typedef enum { IDLE, CALCULATING, NORMALIZED } normalization_state;
  normalization_state state;
  always @(posedge clk_100mhz_buffed) begin 
    case(state)  
        IDLE: begin 
            if (normalizeGyro) begin 
                state <= CALCULATING;
                counter <= 9'd0;
            end else begin 
                state <= IDLE;
                gx_norm <= 0;
                gy_norm <= 0;
                gz_norm <= 0;
            end 
        end
        CALCULATING: begin 
            if (counter < 1048576) begin
                counter <= counter + 1;
                gx_norm <= gx_norm + gx;
                gy_norm <= gy_norm + gy;
                gz_norm <= gz_norm + gz;
            end else begin 
                state <= NORMALIZED;
                gx_norm <= gx_norm >> 20;
                gy_norm <= gy_norm >> 20;
                gz_norm <= gz_norm >> 20;
            end 
        end
        NORMALIZED: begin 
            if (normalizeGyro) begin 
                state <= CALCULATING;
                counter <= 9'd0;
            end else begin 
                state <= NORMALIZED;
            end
        end
    endcase     
  end 

  logic activateGyro;
  assign activateGyro = btn[1];

  logic [8:0] pitch_holder, roll_holder, yaw_holder;
  logic [8:0] pitch, roll, yaw;
  // // Processing output from gyroscope
  process_gyro_simple gyro_process(
      .clk_100mhz(clk_100mhz_buffed),
      .rst_in(sys_rst),
      .gx(gx),
      .gy(gy),
      .gz(gz),
      .pitch(pitch_holder),
      .roll(roll_holder),
      .yaw(yaw_holder)
  );

  always_ff @(posedge clk_100mhz_buffed) begin
    if (activateGyro) begin
        pitch <= pitch_holder;
        roll <= roll_holder;
        yaw <= yaw_holder;
    end 
  end 

  view_output_simple vi(
      .clk_100mhz(clk_100mhz_buffed),
      .start(1'b1),
      .rst_in(sys_rst),
      .pitch(pitch),
      .roll(roll),
      .yaw(yaw),
      .x_forward(camera_forward_x),
      .y_forward(camera_forward_y),
      .z_forward(camera_forward_z),
      .x_up(camera_up_x),
      .y_up(camera_up_y),
      .z_up(camera_up_z),
      .x_right(camera_right_x),
      .y_right(camera_right_y),
      .z_right(camera_right_z)
  ); 
endmodule // top_level

`default_nettype wire