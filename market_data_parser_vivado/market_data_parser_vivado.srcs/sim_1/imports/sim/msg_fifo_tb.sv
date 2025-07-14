`timescale 1ns/1ps
`include "parser_defs.sv"

module msg_fifo_tb;

  // Constants
  localparam CLK_PERIOD = 10;
  localparam FIFO_DEPTH = 4; // Keep small for test

  // Testbench signals
  logic clk = 0;
  logic reset;
  logic write_en;
  logic read_en;
  parsed_msg_t msg_in;
  parsed_msg_t msg_out;
  logic full, empty, msg_valid;

  // Instantiate FIFO
  msg_fifo #(.FIFO_DEPTH(FIFO_DEPTH)) dut (
    .clk(clk),
    .reset(reset),
    .write_en(write_en),
    .read_en(read_en),
    .msg_in(msg_in),
    .msg_out(msg_out),
    .full(full),
    .empty(empty),
    .msg_valid(msg_valid)
  );

  // Clock generation
  always #(CLK_PERIOD / 2) clk = ~clk;

  // Helper task: generate a message
  task automatic gen_msg(input int id);
    msg_in.msg_type = 8'h41 + id;           // 'A', 'B', ...
    msg_in.stock_id = 8'h10 + id;
    msg_in.order_id = 32'h1000 + id;
    msg_in.price    = 32'h2000 + id;
    msg_in.quantity = 32'h3000 + id;
    msg_in.padding  = 16'hDEAD;
  endtask

  // Main test sequence
  initial begin
    $display("Starting FIFO simulation...");
    reset = 1;
    write_en = 0;
    read_en = 0;
    msg_in = '0;

    // Reset the FIFO
    #(2 * CLK_PERIOD);
    reset = 0;
    #(CLK_PERIOD);

    // Write 3 messages
    for (int i = 0; i < 3; i++) begin
      @(posedge clk);
      gen_msg(i);
      write_en = 1;
    end

    @(posedge clk);
    write_en = 0;

    $display("Waiting a few cycles before reading...");
    #(3 * CLK_PERIOD);

    // Read 3 messages
    for (int i = 0; i < 3; i++) begin
      @(posedge clk);
      if (msg_valid) begin
        read_en = 1;
        $display("Cycle %0t: Reading msg_out → type: %s, order_id: %h",
                 $time, msg_out.msg_type, msg_out.order_id);
      end else begin
        read_en = 0;
        $display("Cycle %0t: msg_valid LOW. Nothing to read.", $time);
      end
    end

    @(posedge clk);
    read_en = 0;

    $display("Test complete.");
    $finish;
  end

endmodule
