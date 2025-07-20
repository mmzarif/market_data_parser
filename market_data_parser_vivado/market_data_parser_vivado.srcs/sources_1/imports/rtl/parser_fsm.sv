`include "parser_defs.sv"

module parser_fsm (
  input logic clk,
  input logic reset,
  input logic msg_ready,
  input parsed_msg_t buffer_in,

  output parsed_msg_t parsed_msg,
  output logic done
);

  parser_state_t current_state, next_state;
  logic [3:0] byte_count;
  logic [31:0] price_reg, quantity_reg;
  logic [15:0] padding_reg;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      current_state <= MSG_TYPE;
    end else if (msg_ready) begin
      current_state <= next_state;
    end
  end

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      byte_count <= 0;
    end else if (msg_ready && current_state != DONE) begin
      byte_count <= byte_count + 1;
    end else if (next_state == DONE) begin
      byte_count <= 0;
    end
  end

  always_comb begin
    next_state = current_state;
    case (current_state)
      MSG_TYPE: next_state = STOCK_ID;
      STOCK_ID: next_state = ORDER_ID;
      ORDER_ID:
        if (buffer_in.msg_type == MSG_DELETE) next_state = DONE;
        else next_state = PRICE;
      PRICE: next_state = QUANTITY;
      QUANTITY: next_state = PADDING;
      PADDING: next_state = DONE;
      DONE: next_state = MSG_TYPE;
      default: next_state = MSG_TYPE;
    endcase
  end

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      parsed_msg.msg_type <= MSG_NULL;
      parsed_msg.stock_id <= 0;
      price_reg <= 0;
      quantity_reg <= 0;
      padding_reg <= 0;
    end else if (msg_ready) begin
      case (current_state)
        MSG_TYPE: parsed_msg.msg_type <= buffer_in.msg_type;
        STOCK_ID: parsed_msg.stock_id <= buffer_in.stock_id;
        ORDER_ID: parsed_msg.order_id <= buffer_in.order_id;
        PRICE: price_reg <= buffer_in.price;
        QUANTITY: quantity_reg <= buffer_in.quantity;
        PADDING: padding_reg <= buffer_in.padding;
        default: begin
          parsed_msg.msg_type <= MSG_NULL;
          parsed_msg.stock_id <= 0;
        end
      endcase
    end
  end

  assign done = (current_state == DONE);
  assign parsed_msg.price = (current_state == DONE && parsed_msg.msg_type != MSG_DELETE) ? price_reg : 32'd0;
  assign parsed_msg.quantity = (current_state == DONE && parsed_msg.msg_type != MSG_DELETE) ? quantity_reg : 32'd0;
  assign parsed_msg.padding = (current_state == DONE && parsed_msg.msg_type != MSG_DELETE) ? padding_reg : 16'd0;

endmodule