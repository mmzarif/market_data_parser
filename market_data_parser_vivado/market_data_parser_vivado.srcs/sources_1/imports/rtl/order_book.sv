//make an order book for bids and asks
//create one array to store bids in descending order
//create one array to store asks in ascending order
//this means I need to modify message structure to include order type (bid or ask)
//ASSUME ALL ORDERS ARE FOR THE SAME STOCK

`include "parser_defs.sv"

module order_book #(
    parameter MAX_ORDERS = 16
)
(
    input logic clk, //parsed message read in one go, and we want to update orderbook immediately, so no clock needed
    input logic reset,
    input logic read_en, // signal to read a message from FIFO
    input parsed_msg_t parsed_message, // message read from FIFO
    input logic empty,

    //do I need an output?
    output logic [31:0] best_bid_price,
    output logic [31:0] best_ask_price,
    output logic [31:0] best_bid_quantity,
    output logic [31:0] best_ask_quantity
);

// logic [31:0] bid_order_id   [0:MAX_ORDERS-1];
// logic [31:0] bid_price      [0:MAX_ORDERS-1];
// logic [31:0] bid_quantity   [0:MAX_ORDERS-1];
// logic        bid_valid      [0:MAX_ORDERS-1]; //indicate whether index is full
//should I make this a packed struct?
//packed struct would be better for memory usage

bid_order_t bid_orders   [0:MAX_ORDERS-1];
ask_order_t ask_orders   [0:MAX_ORDERS-1];

//if message type is delete, find order id in the respective array and mark it as invalid
//if message type is add, find the first invalid index and write the order id, price, quantity and valid flag
//if message type is update, find order id in the respective array and update price and quantity

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        //reset all orders
        for (int i = 0; i < MAX_ORDERS; i++) begin //no generate needed since this is runtime loop, notgenerate-time loops
            bid_orders[i].valid <= 0;
            ask_orders[i].valid <= 0;
        end

        best_bid_price <= 0;
        best_ask_price <= 0;
        best_bid_quantity <= 0;
        best_ask_quantity <= 0;

    end else if (read_en && !empty) begin
        //process parsed_message based on msg_type
        case (parsed_message.msg_type)
            MSG_ADD: begin
                //add order to the respective array based on order_side
                if (parsed_message.order_side == ORDER_SIDE_BID) begin
                    int insert_idx = MAX_ORDERS;

                    for (int i = 0; i < MAX_ORDERS; i++) begin
                        if (!bid_orders[i].valid || parsed_message.price > bid_orders[i].price) begin
                            insert_idx = i; // find first invalid index
                            break;
                        end
                    end
                        if (insert_idx < MAX_ORDERS) begin
                            // shift existing orders down to make space for new order
                            for (int j = MAX_ORDERS-2; j >= insert_idx; j--) begin //-2 so dont overflow when copying to j+1
                                bid_orders[j+1] <= bid_orders[j];
                            end
                            bid_orders[insert_idx].stock_id <= parsed_message.stock_id;
                            bid_orders[insert_idx].order_id <= parsed_message.order_id;
                            bid_orders[insert_idx].price <= parsed_message.price;
                            bid_orders[insert_idx].quantity <= parsed_message.quantity;
                            bid_orders[insert_idx].valid <= 1;
                        end
                    end
                else if (parsed_message.order_side == ORDER_SIDE_ASK) begin
                    int insert_idx = MAX_ORDERS;

                    for (int i = 0; i < MAX_ORDERS; i++) begin
                        if (!ask_orders[i].valid || parsed_message.price < ask_orders[i].price) begin
                            insert_idx = i; // find first invalid index
                            break;
                        end
                    end
                        if (insert_idx < MAX_ORDERS) begin
                            // shift existing orders down to make space for new order
                            for (int j = MAX_ORDERS-2; j >= insert_idx; j--) begin //-2 so dont overflow when copying to j+1
                                ask_orders[j+1] <= ask_orders[j];
                            end
                            ask_orders[insert_idx].stock_id <= parsed_message.stock_id;
                            ask_orders[insert_idx].order_id <= parsed_message.order_id;
                            ask_orders[insert_idx].price <= parsed_message.price;
                            ask_orders[insert_idx].quantity <= parsed_message.quantity;
                            ask_orders[insert_idx].valid <= 1;
                        end
                end
                //add_order(parsed_message); // wont work
            end

            MSG_UPDATE: begin
                //update order in the respective array based on order_side
                if (parsed_message.order_side == ORDER_SIDE_BID) begin
                    for (int i = 0; i < MAX_ORDERS; i++) begin
                        if (bid_orders[i].valid && bid_orders[i].stock_id == parsed_message.stock_id && bid_orders[i].order_id == parsed_message.order_id) begin
                            bid_orders[i].price <= parsed_message.price;
                            bid_orders[i].quantity <= parsed_message.quantity;
                            break; // exit loop after updating order
                        end
                    end
                end else if (parsed_message.order_side == ORDER_SIDE_ASK) begin
                    for (int i = 0; i < MAX_ORDERS; i++) begin
                        if (ask_orders[i].valid && ask_orders[i].stock_id == parsed_message.stock_id && ask_orders[i].order_id == parsed_message.order_id) begin
                            ask_orders[i].price <= parsed_message.price;
                            ask_orders[i].quantity <= parsed_message.quantity;
                            break; // exit loop after updating order
                        end
                    end
                end
            end

            MSG_DELETE: begin
                //delete order from the respective array based on order_side
                if (parsed_message.order_side == ORDER_SIDE_BID) begin
                    for (int i = 0; i < MAX_ORDERS; i++) begin
                        if (bid_orders[i].valid && bid_orders[i].order_id == parsed_message.order_id) begin
                            bid_orders[i].valid <= 0; // mark as invalid
                            for (int j = i; j < MAX_ORDERS-1; j++) begin
                                if (bid_orders[j+1].valid) // only shift if next order is valid
                                    bid_orders[j] <= bid_orders[j+1]; // shift down
                                else begin
                                    bid_orders[j].valid <= 0; // mark as invalid if next order is not valid
                                    break;
                                end
                            end
                            break; // exit loop after deleting order
                        end
                    end
                end else if (parsed_message.order_side == ORDER_SIDE_ASK) begin
                    for (int i = 0; i < MAX_ORDERS; i++) begin
                        if (ask_orders[i].valid && ask_orders[i].order_id == parsed_message.order_id) begin
                            ask_orders[i].valid <= 0; // mark as invalid
                            for (int j = i; j < MAX_ORDERS-1; j++) begin
                                if (ask_orders[j+1].valid) // only shift if next order is valid
                                    ask_orders[j] <= ask_orders[j+1]; // shift down
                                else begin
                                    ask_orders[j].valid <= 0; // mark as invalid if next order is not valid
                                    break;
                                end
                            end
                            break; // exit loop after deleting order
                        end
                    end
                end
            end

        endcase
    end

    if (bid_orders[0].valid) begin
        best_bid_price <= bid_orders[0].price;
        best_bid_quantity <= bid_orders[0].quantity;
    end else begin
        best_bid_price <= 0;
        best_bid_quantity <= 0;
    end

    if (ask_orders[0].valid) begin
        best_ask_price <= ask_orders[0].price;
        best_ask_quantity <= ask_orders[0].quantity;
    end else begin
        best_ask_price <= 0;
        best_ask_quantity <= 0;
    end
end

// task add_order(input parsed_msg_t msg);
//     if (msg.order_side == ORDER_SIDE_BID) begin
//         for (int i = 0; i < MAX_ORDERS; i++) begin
//             if (!bid_orders[i].valid) begin
//                 bid_orders[i].stock_id <= msg.stock_id;
//                 bid_orders[i].order_id <= msg.order_id;
//                 bid_orders[i].price <= msg.price;
//                 bid_orders[i].quantity <= msg.quantity;
//                 bid_orders[i].valid <= 1;
//                 break; // exit loop after adding order
//             end
//         end
//     end else if (msg.order_side == ORDER_SIDE_ASK) begin
//         for (int i = 0; i < MAX_ORDERS; i++) begin
//             if (!ask_orders[i].valid) begin
//                 ask_orders[i].stock_id <= msg.stock_id;
//                 ask_orders[i].order_id <= msg.order_id;
//                 ask_orders[i].price <= msg.price;
//                 ask_orders[i].quantity <= msg.quantity;
//                 ask_orders[i].valid <= 1;
//                 break; // exit loop after adding order
//             end
//         end
//     end
// endtask
/*************ILLEGAL TASK BECAUSE IT DOESNT SHARE TIME STEP OF ALWAYS_FF************/

endmodule