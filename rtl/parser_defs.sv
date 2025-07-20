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
    `define ORDER_SIDE_LENGTH 1 // length of order_side in bytes
    `define PRICE_LENGTH 4 // length of price in bytes
    `define QUANTITY_LENGTH 4 // length of quantity in bytes
    `define PADDING_LENGTH 1 // length of padding in bytes
    //use define instead of localparam for constants to allow them to be used in other files

  // FSM states
  //is this mealy or moore?
    //this is a Moore machine because the outputs depend only on the current state
  typedef enum logic [3:0] { //Enough states to cover all message fields?
    IDLE,
    MSG_TYPE,
    STOCK_ID,
    ORDER_ID,
    ORDER_SIDE,
    PRICE,
    QUANTITY,
    PADDING,
    DONE
  } parser_state_t;

  //typedef enum logic[1:0] {
  typedef enum logic[7:0] {
    MSG_ADD = 8'h41, // 'A'
    MSG_DELETE = 8'h44, // 'D'
    MSG_UPDATE = 8'h55, // 'U'
    MSG_NULL = 8'hFF // for unrecognized order types
  } msg_type_t;

  // Order sides
  typedef enum logic[7:0] {
    ORDER_SIDE_BID = 8'h42,
    ORDER_SIDE_ASK = 8'h41,
    ORDER_SIDE_UNKNOWN = 8'hFF // for unrecognized order sides
  } order_side_t;

    typedef struct packed { //packed means no padding between fields
        msg_type_t msg_type; // 1 byte
        logic [7:0] stock_id; // 1 byte
        logic [31:0] order_id; // 4 bytes
        order_side_t order_side; // 1 byte
        logic [31:0] price; // 4 bytes
        logic [31:0] quantity; // 4 bytes
        logic [7:0] padding; // 1 bytes. do I need this?
    } parsed_msg_t;

typedef struct packed {
    logic [7:0]  stock_id; // 1 byte
    logic [31:0] order_id;
    logic [31:0] price;
    logic [31:0] quantity;
    logic        valid; // indicate whether index is full
} bid_order_t;

typedef struct packed {
    logic [7:0]  stock_id; // 1 byte
    logic [31:0] order_id;
    logic [31:0] price;
    logic [31:0] quantity;
    logic        valid; // indicate whether index is full
} ask_order_t;

`endif // PARSER_DEFS_SV