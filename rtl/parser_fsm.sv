//each message is 16 bytes long, which is 128 bits
// byte 0 is the msg_type              (1 byte)
// byte 1 is the stock_id              (1 byte)
//bytes 2-5 are the order_id           (4 bytes) //there are 255 stocks, but each stock can have many orders
//bytes 6-9 are the price              (4 bytes)
//bytes 10-13 are the quantity         (4 bytes)
//bytes 14-15 are reserved for padding (2 bytes)

//after starting, I read the first byte in the msg_type FSM and store it into msg_type register
//then I read the second byte in the stock_id FSM and store it into stock_id register
//then I read the next 4 bytes in the order_id FSM and store it into order
//then I read the next 4 bytes in the price FSM and store it into price
//then I read the next 4 bytes in the quantity FSM and store it into quantity
//then I read the next 2 bytes in the padding FSM and store it into padding
//I know to move to the next FSM because I have a counter that counts the number of bytes read
//when I reach 16 bytes, I reset the counter and start over
//do I use a 2D array counter or a 1D array counter?
//I think a 1D array counter is sufficient because I only need to keep track of the current byte position within the message
//I have a parser_defs.sv file that defines the FSM states and other constants
//remember to include that file in this parser_fsm.sv file
`include "parser_defs.sv"
//remember that state updates are done with always_ccomb, and state transitions are done with always_ff
//is ITCH a synchronous or asynchronous protocol?
//ITCH is a synchronous protocol, so we will use synchronous state updates and transitions
//what is the ITCH protocol?
//ITCH (Institutional Trade Capture) is a protocol used for transmitting financial market data, such as stock trades and quotes.
//it is used by exchanges such as NASDAQ and NYSE to send real-time market data to traders and other market participants.
//it is a binary protocol that is designed to be efficient and low-latency, allowing for high-speed trading and data processing.
//it differs from other protocols like FIX (Financial Information eXchange) in that it is more compact and optimized for speed.
//is it msb or lsb first?
//ITCH uses little-endian byte order, meaning the least significant byte is transmitted first.

//I need an always_ff block for state transitions and an always_comb block for next state logic
//I will also need registers to hold the parsed values for msg_type, stock_id, order_id, price, quantity, and padding
//I will also need a done signal to indicate when the parsing is complete
//I need an always_ff block for data flow - reset everything to 0 or update registers based on state
//in data flow sequential logic, I need to incrememnt byte_count, update register values

module parser_fsm ( //do I need a start signal?
  input logic clk,
  input logic reset,
  //input logic start, // signal to start parsing
  input logic byte_valid,
  input logic [7:0] byte_in, // incoming byte data
  
  // output logic [7:0] msg_type,
  // output logic [7:0] stock_id,
  // output logic [31:0] order_id,
  // output logic [31:0] price,
  // output logic [31:0] quantity,
  // output logic [15:0] padding,
  parsed_msg_t parsed_msg, // struct to hold the parsed message
  output logic done
);

  parser_state_t current_state, next_state; //enumerations
  //parsed_msg_t parsed_msg; // struct to hold the parsed message
  //msg_type_t msg_type; //enumeration

  logic [3:0] byte_count; // to count the number of bytes read

  logic [31:0] order_id_reg, price_reg, quantity_reg;
  logic [15:0] padding_reg;

  // State transition logic
  always_ff @(posedge clk or posedge reset) begin
  if (reset) begin
    //current_state <= IDLE;
    current_state <= MSG_TYPE;
    byte_count <= 0;
  end else if (byte_valid || current_state == DONE) begin
    current_state <= next_state;
    // Use current_state, not next_state, to determine how many bytes we've processed
    //if (current_state != IDLE && current_state != DONE) begin
    if (current_state != DONE) begin
      byte_count <= byte_count + 1;
    end else if (next_state == DONE) begin //in the next clock cycle, byte count will go to zero as state goes to done
      byte_count <= 0;
    end
  end
end


  // Next state and output logic
  always_comb begin
    next_state = current_state; // default to stay in the same state

    case (current_state)
//      IDLE: begin
//        if (byte_valid) begin
//          next_state = MSG_TYPE;
//        end
//      end

      MSG_TYPE: begin
        if (byte_valid && byte_count == `MSG_TYPE_LENGTH - 1) begin
          next_state = STOCK_ID;
      end
      end

      STOCK_ID: begin
        if (byte_count == `MSG_TYPE_LENGTH + `STOCK_ID_LENGTH - 1) begin
            next_state = ORDER_ID;
      end
      end

      ORDER_ID: begin
        if (byte_count == `MSG_TYPE_LENGTH + `STOCK_ID_LENGTH + `ORDER_ID_LENGTH - 1) begin
          if (parsed_msg.msg_type == MSG_DELETE) begin
            next_state = DONE; // go to DONE state if msg_type is delete
          end else begin
            next_state = PRICE; // otherwise, go to PRICE state
          end
        end
      end

      PRICE: begin
        if (byte_count == `MSG_TYPE_LENGTH + `STOCK_ID_LENGTH + `ORDER_ID_LENGTH + `PRICE_LENGTH - 1) begin
          next_state = QUANTITY;
        end
      end

      QUANTITY: begin
        if (byte_count == `MSG_TYPE_LENGTH + `STOCK_ID_LENGTH + `ORDER_ID_LENGTH + `PRICE_LENGTH + `QUANTITY_LENGTH - 1) begin
          next_state = PADDING;
        end
      end

      PADDING: begin
        if (byte_count == `MSG_LENGTH - 1) begin
          next_state = DONE;
        end
      end

      DONE: begin
        next_state = MSG_TYPE; // reset to MSG_TYPE after done
      end

      default: begin
        next_state = MSG_TYPE; // fallback to IDLE state
      end
    endcase
  end      

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            parsed_msg.msg_type <= 0;
            parsed_msg.stock_id <= 0;
//            parsed_msg.order_id <= 0;
//            parsed_msg.price <= 0;
//            parsed_msg.quantity <= 0;
//            parsed_msg.padding <= 0;
            byte_count <= 0;
            //done <= 0; assign is already driving done so no need to reset it here. causes conflict otherwise
            order_id_reg <= 0;
            price_reg    <= 0;
            quantity_reg <= 0;
            padding_reg  <= 0;
        end 
        else if (byte_valid) begin
            case (current_state)
                MSG_TYPE: begin
                    parsed_msg.msg_type <= byte_in;
                    //byte_count <= byte_count + 1;
                end

                STOCK_ID: begin
                    parsed_msg.stock_id <= byte_in;
                    //byte_count <= byte_count + 1;
                end

                ORDER_ID: begin
                    order_id_reg <= {order_id_reg[23:0], byte_in}; // shift in the new byte
                    //byte_count <= byte_count + 1;
                    //order_id <= {order_id[23:0], byte_in};

                end

                PRICE: begin
                    price_reg <= {price_reg[23:0], byte_in}; // shift in the new byte
                    //byte_count <= byte_count + 1;
                    //price <= {price[23:0], byte_in};
                end

                QUANTITY: begin
                    quantity_reg <= {quantity_reg[23:0], byte_in}; // shift in the new byte
                    //byte_count <= byte_count + 1;
                    //quantity <= {quantity[23:0], byte_in};
                end

                PADDING: begin
                    padding_reg <= {padding_reg[7:0], byte_in}; // shift in the new byte
                    //byte_count <= byte_count + 1;
                    //padding <= {padding[7:0], byte_in}; 
                end

                DONE: begin
//                   order_id_reg <= 0;
//                   price_reg    <= 0;
//                   quantity_reg <= 0;
//                   padding_reg  <= 0;
                end

                default: begin
                // Reset all registers on unexpected state
                //IDLE state also resets the registers so combine the two
                    parsed_msg.msg_type <= MSG_NULL;
                    parsed_msg.stock_id <= 0;
//                    order_id <= 0;
//                    price <= 0;
//                    quantity <= 0;
//                    padding <= 0;
                    //byte_count <= 0;
                end
            endcase
        end
    end

    assign done = (current_state == DONE);

  assign parsed_msg.order_id = (current_state == DONE) ? order_id_reg : 32'd0;
  assign parsed_msg.price    = (current_state == DONE && parsed_msg.msg_type != MSG_DELETE) ? price_reg    : 32'd0;
  assign parsed_msg.quantity = (current_state == DONE && parsed_msg.msg_type != MSG_DELETE) ? quantity_reg : 32'd0;
  assign parsed_msg.padding  = (current_state == DONE && parsed_msg.msg_type != MSG_DELETE) ? padding_reg  : 16'd0;
  //we should try to use assign statements to drive outputs of the module
  //cannot drive signals in both always_ff block and assignment statements
  //can use assign for msg_type and stock_id by using temp registers for those as well, but maybe next time. it works for now
  //** if I do not use assignment operators for these 4 when using temp registers, they reflect on the output 1 cycle later.

endmodule