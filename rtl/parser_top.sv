`include "parser_defs.sv"

module parser_top #(
    parameter FIFO_DEPTH = 16
)
(
    input logic clk,
    input logic reset,
    input logic [7:0] byte_in, // input byte to be parsed
    input logic byte_valid, // signal to indicate that byte_in is valid
    
    input logic read_en, // signal to read a message
    output logic full, // indicates if FIFO is full
    output logic empty, // indicates if FIFO is empty
    output parsed_msg_t msg_out // message read from FIFO
);

logic done; // signal to indicate that parsing is complete
logic write_en; // signal to write a message to FIFO
parsed_msg_t parsed_msg; // struct to hold the parsed message

assign write_en = done && !full; // write to FIFO when parsing is done

    parser_fsm fsm_inst (
        .clk(clk),
        .reset(reset),
        .byte_valid(byte_valid),
        .byte_in(byte_in),
        .parsed_msg(parsed_msg), // struct to hold the parsed message
        .done(done) // done signal to indicate that parsing is complete
    );

  msg_fifo #(.FIFO_DEPTH(FIFO_DEPTH)) fifo_inst (
      .clk(clk),
      .reset(reset),
      .write_en(write_en),
      .read_en(read_en),
      .msg_in(parsed_msg),
      .full(full),
      .empty(empty),
      .msg_out(msg_out)
  );

endmodule