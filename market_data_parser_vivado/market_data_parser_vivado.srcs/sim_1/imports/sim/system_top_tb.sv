`include "parser_defs.sv"

module system_top_tb;

  parameter FIFO_DEPTH = 16;
  parameter MAX_ORDERS = 16;

  logic clk = 0;
  always #5 clk = ~clk; // 10ns clock period

  logic reset;
  logic [7:0] byte_in;
  logic byte_valid;
  logic orderbook_read_en;

  //logic fifo_full, fifo_empty;
  logic [31:0] best_bid_price, best_ask_price;
  logic [31:0] best_bid_quantity, best_ask_quantity;

  system_top #(
    .FIFO_DEPTH(FIFO_DEPTH),
    .MAX_ORDERS(MAX_ORDERS)
  ) dut (
    .clk(clk),
    .reset(reset),
    .byte_in(byte_in),
    .byte_valid(byte_valid),
    .orderbook_read_en(orderbook_read_en),
    //.fifo_full(fifo_full),
    //.fifo_empty(fifo_empty),
    .best_bid_price(best_bid_price),
    .best_ask_price(best_ask_price),
    .best_bid_quantity(best_bid_quantity),
    .best_ask_quantity(best_ask_quantity)
  );

  // Sample ADD message (msg_type = 'A', stock_id = 1, order_id = 0x12345678, side = 'B', price = 1000, qty = 10)
  byte msg1 [0:15] = {
    8'h41,         // 'A'
    8'h01,         // stock_id
    8'h12, 8'h34, 8'h56, 8'h78, // order_id
    8'h42,         // 'B' = bid
    8'h00, 8'h00, 8'h03, 8'hE8, // price = 1000
    8'h00, 8'h00, 8'h00, 8'h0A, // quantity = 10
    8'hFF          // padding
  };

  task send_message(input byte msg [0:15]);
    for (int i = 0; i < 16; i++) begin
      @(negedge clk);
      byte_in = msg[i];
      byte_valid = 1;
    end
    @(negedge clk);
    byte_valid = 0;
  endtask

  task trigger_orderbook_read();
    @(negedge clk);
    orderbook_read_en = 1;
    @(negedge clk);
    orderbook_read_en = 0;
  endtask

  initial begin
    $display("Starting system_top_tb...");
    byte_in = 0;
    byte_valid = 0;
    orderbook_read_en = 0;

    reset = 1;
    repeat (2) @(negedge clk);
    reset = 0;

    // Send first message
    send_message(msg1);
    repeat (3) @(negedge clk); // wait for FSM to parse
    trigger_orderbook_read();  // feed parsed_msg to order_book

    // Wait and observe
    repeat (20) @(negedge clk);
    $display("Best bid price: %0d", best_bid_price);
    $display("Best bid quantity: %0d", best_bid_quantity);
    $finish;
  end

endmodule