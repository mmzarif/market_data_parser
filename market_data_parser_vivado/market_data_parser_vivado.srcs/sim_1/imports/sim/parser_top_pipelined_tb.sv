`timescale 1ns/1ps
`include "parser_defs.sv"

module parser_top_pipelined_tb;
  parameter FIFO_DEPTH = 16;
  parameter CLK_PERIOD = 10;

  // Clock & reset
  logic clk = 0;
  logic reset;

  // Stage-1 inputs
  logic [7:0] byte_in;
  logic       byte_valid;

  // FIFO/read interface
  logic       read_en;
  logic       full, empty;
  parsed_msg_t msg_out;

  // DUT
  parser_top #(.FIFO_DEPTH(FIFO_DEPTH)) dut (
    .clk        (clk),
    .reset      (reset),
    .byte_in    (byte_in),
    .byte_valid (byte_valid),
    .read_en    (read_en),
    .full       (full),
    .empty      (empty),
    .msg_out    (msg_out)
  );

  // Clock generator
  always #(CLK_PERIOD/2) clk = ~clk;

  // Two test messages
  byte msg1 [0:15], msg2 [0:15];
  initial begin
    // Populate msg1 (ADD)
    msg1[0] = 8'h41; msg1[1] = 8'hA1;
    msg1[2] = 8'h11; msg1[3] = 8'h22; msg1[4] = 8'h33; msg1[5] = 8'h44;
    msg1[6] = 8'h55; msg1[7] = 8'h66; msg1[8] = 8'h77; msg1[9] = 8'h88;
    msg1[10]= 8'h99; msg1[11]= 8'hAA; msg1[12]= 8'hBB; msg1[13]= 8'hCC;
    msg1[14]= 8'h00; msg1[15]= 8'h00;

    // Populate msg2 (DELETE) — only 2+4 bytes matter
    msg2[0] = 8'h44; msg2[1] = 8'hB2;
    msg2[2] = 8'hDE; msg2[3] = 8'hAD; msg2[4] = 8'hBE; msg2[5] = 8'hEF;
    // rest can be junk
    foreach (msg2[i]) if (i>=6) msg2[i] = 8'hFF;
  end

  // Drive pipeline: send two messages back-to-back
  task send_two_messages();
    int i;
    // First message
    for (i = 0; i < 16; i++) begin
      @(posedge clk);
      byte_in    <= msg1[i];
      byte_valid <= 1;
    end
    // Immediately start second message
    for (i = 0; i < 16; i++) begin
      @(posedge clk);
      byte_in    <= msg2[i];
      byte_valid <= 1;
    end
    // Deassert
    @(posedge clk) byte_valid <= 0;
  endtask

  // Read two messages
  task read_two();
    // Wait until FIFO has two entries
    wait (!empty);
    @(posedge clk); read_en <= 1;
    @(posedge clk); read_en <= 0;
    $display("[TB] Got msg1: type=0x%0h, stock=0x%0h, order=0x%0h",
             msg_out.msg_type, msg_out.stock_id, msg_out.order_id);
    // Wait again for second
    wait (!empty);
    @(posedge clk); read_en <= 1;
    @(posedge clk); read_en <= 0;
    $display("[TB] Got msg2: type=0x%0h, stock=0x%0h, order=0x%0h",
             msg_out.msg_type, msg_out.stock_id, msg_out.order_id);
  endtask

  initial begin
    // Init
    read_en    = 0;
    byte_valid = 0;
    byte_in    = 0;
    reset      = 1;
    repeat (2) @(posedge clk);
    reset = 0;

    // Send and read
    send_two_messages();
    read_two();

    #100 $finish;
  end

endmodule