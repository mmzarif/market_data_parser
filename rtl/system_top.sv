`include "parser_defs.sv"

module system_top #(
    parameter FIFO_DEPTH = 16,
    parameter MAX_ORDERS = 16
)(
    input  logic        clk,
    input  logic        reset,
    input  logic [7:0]  byte_in,
    input  logic        byte_valid,
    input  logic        orderbook_read_en, // External trigger to process one message

    output logic [31:0] best_bid_price,
    output logic [31:0] best_ask_price,
    output logic [31:0] best_bid_quantity,
    output logic [31:0] best_ask_quantity
);

    // Internal signals
    logic        fifo_read_en;
    logic       fifo_full;
    logic       fifo_empty;
    parsed_msg_t fifo_msg;

    // Hook up parser_top (FSM + FIFO)
    parser_top #(.FIFO_DEPTH(FIFO_DEPTH)) parser (
        .clk(clk),
        .reset(reset),
        .byte_in(byte_in),
        .byte_valid(byte_valid),
        .read_en(fifo_read_en),
        .full(fifo_full),
        .empty(fifo_empty),
        .msg_out(fifo_msg)
    );

    // Hook up order_book
    order_book #(.MAX_ORDERS(MAX_ORDERS)) book (
        .clk(clk),
        .reset(reset),
        .read_en(fifo_read_en),
        .parsed_message(fifo_msg),
        .empty(fifo_empty),
        .best_bid_price(best_bid_price),
        .best_ask_price(best_ask_price),
        .best_bid_quantity(best_bid_quantity),
        .best_ask_quantity(best_ask_quantity)
    );

    // Use external trigger for now
    assign fifo_read_en = orderbook_read_en && !fifo_empty;

endmodule