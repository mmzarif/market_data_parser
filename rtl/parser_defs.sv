//this file defines the FSM states and other constants for the parser
//for the ITCH protocol parser

`ifndef PARSER_DEFS_SV
`define PARSER_DEFS_SV
//include guard to prevent multiple inclusions of this file

// Message constants
    `define MSG_LENGTH 16 // total length of the message in bytes
    `define MSG_TYPE_LENGTH 1 // length of msg_type in bytes
    `define STOCK_ID_LENGTH 1 // length of stock_id in bytes
    `define ORDER_ID_LENGTH 4 // length of order_id in bytes
    `define PRICE_LENGTH 4 // length of price in bytes
    `define QUANTITY_LENGTH 4 // length of quantity in bytes
    `define PADDING_LENGTH 2 // length of padding in bytes
    //use define instead of localparam for constants to allow them to be used in other files

  // FSM states
  //is this mealy or moore?
    //this is a Moore machine because the outputs depend only on the current state
  typedef enum logic [2:0] {
    IDLE,
    MSG_TYPE,
    STOCK_ID,
    ORDER_ID,
    PRICE,
    QUANTITY,
    PADDING,
    DONE
  } parser_state_t;

  //typedef enum logic[1:0] {
  typedef enum logic[7:0] {
    MSG_ADD = 0x41, // 'A'
    MSG_DELETE = 0x44, // 'D'
    MSG_UPDATE = 0x55, // 'U'
    MSG_NULL = 0x4E // 'N'
  } msg_type_t;
 
    typedef struct packed { //packed means no padding between fields
        msg_type_t msg_type; // 1 byte
        logic [7:0] stock_id; // 1 byte
        logic [31:0] order_id; // 4 bytes
        logic [31:0] price; // 4 bytes
        logic [31:0] quantity; // 4 bytes
        logic [15:0] padding; // 2 bytes. do I need this? 
    } parsed_msg_t;

`endif // PARSER_DEFS_SV