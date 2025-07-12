//this file defines the FSM states and other constants for the parser
//for the ITCH protocol parser

`ifndef PARSER_DEFS_SV
`define PARSER_DEFS_SV
//include guard to prevent multiple inclusions of this file

  // FSM states
  //is this mealy or moore?
    //this is a Moore machine because the outputs depend only on the current state
  typedef enum logic [2:0] {
    //IDLE,
    MSG_TYPE,
    STOCK_ID,
    ORDER_ID,
    PRICE,
    QUANTITY,
    PADDING,
    DONE
  } parser_state_t;

    // Message constants
    `define MSG_LENGTH 16 // total length of the message in bytes
    `define MSG_TYPE_LENGTH 1 // length of msg_type in bytes
    `define STOCK_ID_LENGTH 1 // length of stock_id in bytes
    `define ORDER_ID_LENGTH 4 // length of order_id in bytes
    `define PRICE_LENGTH 4 // length of price in bytes
    `define QUANTITY_LENGTH 4 // length of quantity in bytes
    `define PADDING_LENGTH 2 // length of padding in bytes
    //use define instead of localparam for constants to allow them to be used in other files

`endif // PARSER_DEFS_SV