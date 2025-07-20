`timescale 1ns/1ps
`include "parser_defs.sv"
`define PARSER_ASSERTIONS

module parser_top_tb;

  parameter FIFO_DEPTH = 16;
  parameter CLK_PERIOD = 10;

  logic clk;
  logic reset;
  logic [7:0] byte_in;
  logic byte_valid;
  logic read_en;
  logic full;
  logic empty;
  parsed_msg_t msg_out;

  // Instantiate DUT
  parser_top #(.FIFO_DEPTH(FIFO_DEPTH)) dut (
    .clk(clk),
    .reset(reset),
    .byte_in(byte_in),
    .byte_valid(byte_valid),
    .read_en(read_en),
    .full(full),
    .empty(empty),
    .msg_out(msg_out)
  );

  // Clock generation
  initial clk = 0;
  always #(CLK_PERIOD/2) clk = ~clk;

  // Test message
  byte message[0:15];

  task load_test_message();
    // MSG_TYPE = 0x41 (ADD)
    // STOCK_ID = 0xA1
    // ORDER_ID = 0x11223344
    // PRICE    = 0x55667788
    // QUANTITY = 0x99AABBCC
    // PADDING  = 0xDDEE
    message[0]  = 8'h41; // msg_type
    message[1]  = 8'hA1; // stock_id
    message[2]  = 8'h11; // order_id
    message[3]  = 8'h22;
    message[4]  = 8'h33;
    message[5]  = 8'h44;
    message[6]  = 8'h55; // price
    message[7]  = 8'h66;
    message[8]  = 8'h77;
    message[9]  = 8'h88;
    message[10] = 8'h99; // quantity
    message[11] = 8'hAA;
    message[12] = 8'hBB;
    message[13] = 8'hCC;
    message[14] = 8'hDE; // padding
    message[15] = 8'hAD;
  endtask

  // Feed a message byte-by-byte
  task send_message();
    int i;
    for (i = 0; i < 16; i++) begin
      @(posedge clk);
      byte_in <= message[i];
      byte_valid <= 1;
      @(posedge clk);
      byte_valid <= 0;
    end
  endtask

  // Read parsed message from FIFO
  task read_message();
    @(posedge clk);
    read_en <= 1;
    @(posedge clk);
    read_en <= 0;
  endtask

  initial begin
    // Initialize
    byte_in = 0;
    byte_valid = 0;
    read_en = 0;

    load_test_message();

    reset = 1;
    repeat (2) @(posedge clk);
    reset = 0;

    // Send one full message
    send_message();

    // Wait for parser to finish and message to be written
    wait (!empty);
    $display("\n[TB] FIFO is NOT empty. Reading message...\n");

    read_en <= 1;
    @(posedge clk);
    read_en <= 0;
    
    // Print immediately after data is read from FIFO
    $display("Parsed Message:");
    $display("  msg_type  = 0x%0h", msg_out.msg_type);
    $display("  stock_id  = 0x%0h", msg_out.stock_id);
    $display("  order_id  = 0x%0h", msg_out.order_id);
    $display("  price     = 0x%0h", msg_out.price);
    $display("  quantity  = 0x%0h", msg_out.quantity);
    $display("  padding   = 0x%0h", msg_out.padding);
    
    @(posedge clk); // allow msg_out to go back to X if desired

    #100;
  `ifdef PERF
    dut.print_perf_stats();
  `endif
    $display("[TB] Simulation completed. Dumping performance stats...\n");
    $finish;
  end

endmodule