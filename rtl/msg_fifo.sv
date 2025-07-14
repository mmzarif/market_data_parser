//first in first out buffer so that multiple messages can be parsed and stored while whatever needs the data takes it out at its own pace
//lets say our fifo has a depth of 16, so we can store 16 messages at a time
//I want to use circular buffer logic to implement the FIFO
//but let's keep it simple for now
//I need a write pointer to know where to write the next message. this increments every time a message is written
//write when a write_en signal is asserted and the FIFO is not full
//I need a read pointer to know where to read the next message. this increments every time a message is read
//read when a read_en signal is asserted and the FIFO is not empty
//I need a full signal to indicate when the FIFO is full
//I need an empty signal to indicate when the FIFO is empty
//I need a count to know how many messages are in the FIFO and if it is full or empty

`include "parser_defs.sv"

module msg_fifo #(
    parameter FIFO_DEPTH = 16
)
(
    input logic clk,
    input logic reset,
    input logic write_en, // signal to write a message
    input logic read_en, // signal to read a message
    input parsed_msg_t msg_in, // message to write into FIFO
    output logic full, // indicates if FIFO is full
    output logic empty, // indicates if FIFO is empty
    output parsed_msg_t msg_out, // message read from FIFO
    output logic msg_valid //we had byte_valid in parser_fsm, so we can use msg_valid here to tell downstream logic that the message is valid
);

  //logic [FIFO_DEPTH-1:0] fifo_mem; // this is bad
  //parsed_msg_t fifo_mem [FIFO_DEPTH-1:0]; // memory to hold the messages in FIFO
  parsed_msg_t fifo_mem [0:FIFO_DEPTH-1]; // memory to hold the messages in FIFO, using packed struct
  //use 0:FIFO_DEPTH-1 instead of 0:FIFO_DEPTH-1 to avoid issues with indexing in SystemVerilog
  logic [3:0] write_ptr; // pointer for writing messages. could use localparam MEM_WIDTH = $clog2(FIFO_DEPTH) to define the width   
  logic [3:0] read_ptr; // pointer for reading messages Could use localparam MEM_WIDTH = $clog2(FIFO_DEPTH) to define the width
  logic [3:0] count; // count of messages in the FIFO. 

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      write_ptr <= 0;
      read_ptr <= 0;
      count <= 0;
    end else begin
      if (write_en && !full) begin
        fifo_mem[write_ptr] <= msg_in; // write message to FIFO
        write_ptr <= (write_ptr == FIFO_DEPTH-1) ? 0 : write_ptr + 1; // increment write pointer circularly
        count <= count + 1;
      end

      if (read_en && !empty) begin
        //msg_out <= fifo_mem[read_ptr]; // read message from FIFO
        read_ptr <= (read_ptr == FIFO_DEPTH-1) ? 0 : read_ptr + 1; // increment read pointer circularly
        //non blocking assignment increments read_ptr AFTER the clock cycle, so it does not cause race condition with assigning msg_out
        count <= count - 1; 
      end

    end
  end

  assign full = (count == FIFO_DEPTH); 
  assign empty = (count == 0); 
  assign msg_out = fifo_mem[read_ptr]; // assign message output from FIFO
  assign msg_valid = !empty; // message is valid if FIFO is not empty
endmodule