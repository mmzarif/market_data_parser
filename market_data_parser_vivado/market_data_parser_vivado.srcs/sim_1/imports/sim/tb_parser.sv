`timescale 1ns/1ps

module tb_parser;

  logic clk = 0;
  logic reset = 1;
  logic byte_valid = 0;
  logic [7:0] byte_in;

  logic [7:0] msg_type;
  logic [7:0] stock_id;
  logic [31:0] order_id;
  logic [31:0] price;
  logic [31:0] quantity;
  logic [15:0] padding;
  logic done;

  // Instantiate the DUT
  parser_fsm dut (
    .clk(clk),
    .reset(reset),
    .byte_valid(byte_valid),
    .byte_in(byte_in),
    .msg_type(msg_type),
    .stock_id(stock_id),
    .order_id(order_id),
    .price(price),
    .quantity(quantity),
    .padding(padding),
    .done(done)
  );

  // Clock generator
  always #5 clk = ~clk;

  // Memory to hold hex input
  logic [7:0] message [0:15];

  initial begin
    $display("Loading test vector from hex file...");
    $readmemh("F:/FPGA projects/market_data_parser/sim/test_vectors.hex", message);
    
    // Reset for 2 cycles
    #10 reset = 1;
    #10 reset = 0;

    // Feed 16 bytes from file
    for (int i = 0; i < 16; i++) begin
      @(posedge clk);
      byte_in    <= message[i];
      byte_valid <= 1;
    end

    // Clear byte_valid after all bytes sent
    @(posedge clk);
    byte_valid <= 0;

    // Wait for parser to enter DONE
    wait (done == 1);
    @(posedge clk); // one cycle delay for outputs to stabilize

    $display("Parsed Output:");
    $display("  msg_type  = %c", msg_type);
    $display("  stock_id  = %0d", stock_id);
    $display("  order_id  = 0x%08X", order_id);
    $display("  price     = %0d", price);
    $display("  quantity  = %0d", quantity);
    $display("  padding   = 0x%04X", padding);
    $display("  done      = %b", done);
    $display("  byte_in      = 0x%04X", byte_in);
    $display("  byte_valid      = %0d", byte_valid);

    #10 $finish;
  end

endmodule