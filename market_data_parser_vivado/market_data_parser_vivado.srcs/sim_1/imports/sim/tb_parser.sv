`timescale 1ns/1ps
`include "parser_defs.sv"

module parser_fsm_tb;

  // DUT inputs
  logic clk;
  logic reset;
  logic byte_valid;
  logic [7:0] byte_in;

  // DUT outputs
  parsed_msg_t parsed_msg;
  logic done;

  // Instantiate the DUT
  parser_fsm dut (
    .clk(clk),
    .reset(reset),
    .byte_valid(byte_valid),
    .byte_in(byte_in),
    .parsed_msg(parsed_msg),
    .done(done)
  );

  // Clock generation: 10ns period
  always #5 clk = ~clk;

  // Test vector memory
  logic [7:0] test_data [0:47]; // 3 messages × 16 bytes = 48

  // Index for feeding bytes
  int i;

  initial begin
    // Initialize signals
    clk = 0;
    reset = 1;
    byte_valid = 0;
    byte_in = 8'h00;
    i = 0;

    // Load test vector
    $readmemh("test_vectors.hex", test_data);

    // Hold reset for a few cycles
    #20;
    reset = 0;

    // Feed bytes one by one
    for (i = 0; i < 48; i++) begin
      @(negedge clk);
      byte_in = test_data[i];
      byte_valid = 1;

      @(negedge clk);
      byte_valid = 0; // De-assert to simulate 1-cycle pulse
    end

    // Wait for final message to complete
    #100;

    $finish;
  end

  // Monitor output
  always_ff @(posedge clk) begin
    if (done) begin
      $display("---- Message Parsed ----");
      $display("Type     : %s", parsed_msg.msg_type);
      $display("Stock ID : %0d", parsed_msg.stock_id);
      $display("Order ID : %0d", parsed_msg.order_id);
      $display("Price    : %0d", parsed_msg.price);
      $display("Quantity : %0d", parsed_msg.quantity);
      $display("Padding  : 0x%h", parsed_msg.padding);
      $display("------------------------");
    end
  end

endmodule
