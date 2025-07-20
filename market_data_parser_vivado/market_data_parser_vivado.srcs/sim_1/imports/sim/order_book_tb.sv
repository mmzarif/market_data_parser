`include "parser_defs.sv"

module order_book_tb;

  parameter MAX_ORDERS = 16;

  logic clk = 0;
  always #1 clk = ~clk; // 2ns clock period
  logic reset = 1;
  logic read_en = 0;
  logic empty = 0;
  parsed_msg_t msg;

  // Instantiate the order book
  order_book #(.MAX_ORDERS(MAX_ORDERS)) dut (
    .clk(clk),
    .reset(reset),
    .read_en(read_en),
    .parsed_message(msg),
    .empty(empty)
  );

  // Clock-free simulation stepper
// Clock-free simulation stepper
  task apply_msg(input parsed_msg_t new_msg);
    msg = new_msg;
    empty = 0;
    @(posedge clk); // Wait for clock edge
    read_en = 1;
    @(posedge clk); // Wait for clock edge
    read_en = 0;
  endtask

  // Dump contents of order book
  task print_order_book();
    $display("------ BID SIDE ------");
    for (int i = 0; i < MAX_ORDERS; i++) begin
      if (dut.bid_orders[i].valid) begin
        $display("BID[%0d] ID:%0h P:%0d Q:%0d", i, dut.bid_orders[i].order_id,
                  dut.bid_orders[i].price, dut.bid_orders[i].quantity);
      end
    end
    $display("------ ASK SIDE ------");
    for (int i = 0; i < MAX_ORDERS; i++) begin
      if (dut.ask_orders[i].valid) begin
        $display("ASK[%0d] ID:%0h P:%0d Q:%0d", i, dut.ask_orders[i].order_id,
                  dut.ask_orders[i].price, dut.ask_orders[i].quantity);
      end
    end
    $display("----------------------\n");
  endtask

  initial begin
    #2;
    reset = 0;

    // Add BID orders (sorted descending)
    apply_msg('{MSG_ADD, 8'h01, 32'h1111_1111, ORDER_SIDE_BID, 32'd1000, 32'd10, 8'hFF}); // $10.00
    print_order_book();

    apply_msg('{MSG_ADD, 8'h01, 32'h2222_2222, ORDER_SIDE_BID, 32'd1050, 32'd5, 8'hFF}); // $10.50
    print_order_book();

    apply_msg('{MSG_ADD, 8'h01, 32'h3333_3333, ORDER_SIDE_BID, 32'd990, 32'd20, 8'hFF}); // $9.90
    print_order_book();

    // Add ASK orders (sorted ascending)
    apply_msg('{MSG_ADD, 8'h01, 32'hAAAA_AAAA, ORDER_SIDE_ASK, 32'd1100, 32'd15, 8'hFF}); // $11.00
    print_order_book();

    apply_msg('{MSG_ADD, 8'h01, 32'hBBBB_BBBB, ORDER_SIDE_ASK, 32'd1080, 32'd10, 8'hFF}); // $10.80
    print_order_book();

    apply_msg('{MSG_ADD, 8'h01, 32'hCCCC_CCCC, ORDER_SIDE_ASK, 32'd1150, 32'd5, 8'hFF});  // $11.50
    print_order_book();

    $display("Testbench complete.");
    $finish;
  end

endmodule