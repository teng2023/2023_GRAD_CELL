module LASER (
input CLK,
input RST,
input [3:0] X,
input [3:0] Y,
output reg [3:0] C1X,
output reg [3:0] C1Y,
output reg [3:0] C2X,
output reg [3:0] C2Y,
output reg DONE,
output [8:0] counter_counter,
output [1:0] current_s,
output [1:0] next_s,
output [7:0] t_max_t,
output [3:0] tx_t,
output [3:0] ty_t,
output match_circle_1_,
output match_circle_2_,
output [3:0] c_x,
output [3:0] c_y,
output [48:0] temp_c1,
output [48:0] temp_c2,
output [48:0] load_circle,
output [255:0] input_data,
output [3:0] load_xx,
output [3:0] load_yy,
output circle_selection);

// define state
`define ENTER_INPUT 2'b0
`define CIRCLE_SEARCH 2'b01
`define COMPARE 2'b10

reg [255:0] input_map;

reg [1:0] current_state;
reg [1:0] next_state;
reg [7:0] counter;
reg circle_select;  // 0 is circle 1, 1 is circle 2
reg first_swap;

reg [3:0] current_x;
reg [3:0] current_y;
reg [3:0] tx;
reg [3:0] ty;
reg [7:0] t_max;
reg [3:0] load_x;
reg [3:0] load_y;

// reg [48:0] circle_save;
// reg [48:0] circle_load;
reg [48:0] temp_circle_1;
reg [48:0] temp_circle_2;
reg [49:0] circle_load;

reg match_circle_1;
reg match_circle_2;

wire calculate_valid;   // if current_x or current_y >12 or < 4, don't calculate
wire first_enter_state;

assign counter_counter = counter;
assign current_s = current_state;
assign next_s = next_state;
assign t_max_t = t_max;
assign tx_t = tx;
assign ty_t = ty;
assign match_circle_1_ = match_circle_1;
assign match_circle_2_ = match_circle_2;
assign c_x = current_x;
assign c_y = current_y;
assign temp_c1 = temp_circle_1;
assign temp_c2 = temp_circle_2;
assign load_circle = circle_load;
assign input_data = input_map;
assign load_xx = load_x;
assign load_yy = load_y;
assign circle_selection = circle_select;
///////////////////////// enter input /////////////////////////

always @(posedge CLK or posedge RST) begin
    if (RST || DONE) begin
        input_map <= 256'b0;
    end
    else if (current_state == `ENTER_INPUT) begin
        input_map[(255 - (X + 16 * Y))] <= 1'b1;
    end
    else if (current_state == `COMPARE && ~counter[0]) begin
        input_map[255-(tx+16*(ty-4))] <= 1'b0;
        input_map[255-((tx-2)+16*(ty-3))-:5] <= 5'b0;
        input_map[255-((tx-3)+16*(ty-2))-:7] <= 7'b0;
        input_map[255-((tx-3)+16*(ty-1))-:7] <= 7'b0;
        input_map[255-((tx-4)+16*ty)-:9] <= 9'b0;
        input_map[255-((tx-3)+16*(ty+1))-:7] <= 7'b0;
        input_map[255-((tx-3)+16*(ty+2))-:7] <= 7'b0;
        input_map[255-((tx-2)+16*(ty+3))-:5] <= 5'b0;
        input_map[255-(tx+16*(ty+4))] <= 1'b0;
    end
    else if (current_state == `COMPARE && counter[0]) begin
        input_map[255-(load_x+16*(load_y-4))] <= circle_load[48];
        input_map[255-((load_x-2)+16*(load_y-3))-:5] <= circle_load[47:43];
        input_map[255-((load_x-3)+16*(load_y-2))-:7] <= circle_load[42:36];
        input_map[255-((load_x-3)+16*(load_y-1))-:7] <= circle_load[35:29];
        input_map[255-((load_x-4)+16*load_y)-:9] <= circle_load[28:20];
        input_map[255-((load_x-3)+16*(load_y+1))-:7] <= circle_load[19:13];
        input_map[255-((load_x-3)+16*(load_y+2))-:7] <= circle_load[12:6];
        input_map[255-((load_x-2)+16*(load_y+3))-:5] <= circle_load[5:1];
        input_map[255-(load_x+16*(load_y+4))] <= circle_load[0];
    end
end

///////////////////////// circle search /////////////////////////

// convolution 1
wire [24:0] feature_map1;
assign feature_map1[24:20] = (calculate_valid) ? input_map[(255-((current_x-2)+16*(current_y-2))) -: 5] : 5'b0;
assign feature_map1[19:15] = (calculate_valid) ? input_map[(255-((current_x-2)+16*(current_y-1))) -: 5] : 5'b0;
assign feature_map1[14:10] = (calculate_valid) ? input_map[(255-((current_x-2)+16*(current_y))) -: 5] : 5'b0;
assign feature_map1[9:5] = (calculate_valid) ? input_map[(255-((current_x-2)+16*(current_y+1))) -: 5] : 5'b0;
assign feature_map1[4:0] = (calculate_valid) ? input_map[(255-((current_x-2)+16*(current_y+2))) -: 5] : 5'b0;

// convolution 2
wire [5:0] feature_map2;
assign feature_map2[5] = (calculate_valid) ? input_map[255-(current_x+16*(current_y-4))] : 1'b0;
assign feature_map2[4:0] = (calculate_valid) ? input_map[(255-((current_x-2)+16*(current_y-3))) -: 5] : 5'b0;

// convolution 3
wire [5:0] feature_map3;
assign feature_map3[5] = (calculate_valid) ? input_map[255-((current_x-4)+16*current_y)] : 1'b0;
assign feature_map3[4:0] = (calculate_valid) ? {input_map[255-((current_x-3)+16*(current_y-2))], 
                            input_map[255-((current_x-3)+16*(current_y-1))], 
                            input_map[255-((current_x-3)+16*(current_y))], 
                            input_map[255-((current_x-3)+16*(current_y+1))], 
                            input_map[255-((current_x-3)+16*(current_y+2))]} : 5'b0;

// convolution 4
wire [5:0] feature_map4;
assign feature_map4[5:1] = (calculate_valid) ? {input_map[255-((current_x+3)+16*(current_y-2))], 
                            input_map[255-((current_x+3)+16*(current_y-1))], 
                            input_map[255-((current_x+3)+16*(current_y))], 
                            input_map[255-((current_x+3)+16*(current_y+1))], 
                            input_map[255-((current_x+3)+16*(current_y+2))]} : 5'b0;
assign feature_map4[0] = (calculate_valid) ? input_map[255-((current_x+4)+16*current_y)] : 1'b0;

// convolution 5
wire [5:0] feature_map5;
assign feature_map5[5:1] = (calculate_valid) ? input_map[(255-((current_x-2)+16*(current_y+3))) -: 5] : 5'b0;
assign feature_map5[0] = (calculate_valid) ? input_map[255-(current_x+16*(current_y+4))] : 1'b0;

// adder tree
wire [5:0] conv1_result;
wire [3:0] conv2_result;
wire [3:0] conv3_result;
wire [3:0] conv4_result;
wire [3:0] conv5_result;
wire [7:0] conv_result;

assign conv1_result = ((((feature_map1[0] + feature_map1[1]) + (feature_map1[2] + feature_map1[3])) 
                        + ((feature_map1[4] + feature_map1[5]) + (feature_map1[6] + feature_map1[7])))
                        + (((feature_map1[8] + feature_map1[9]) + (feature_map1[10] + feature_map1[11])) 
                        + ((feature_map1[12] + feature_map1[13]) + (feature_map1[14] + feature_map1[15]))))
                        + ((((feature_map1[16] + feature_map1[17]) + (feature_map1[18] + feature_map1[19])) 
                        + ((feature_map1[20] + feature_map1[21]) + (feature_map1[22] + feature_map1[23])))
                        + feature_map1[24]);
assign conv2_result = ((feature_map2[0] + feature_map2[1]) + (feature_map2[2] + feature_map2[3])) + (feature_map2[4] + feature_map2[5]);
assign conv3_result = ((feature_map3[0] + feature_map3[1]) + (feature_map3[2] + feature_map3[3])) + (feature_map3[4] + feature_map3[5]);
assign conv4_result = ((feature_map4[0] + feature_map4[1]) + (feature_map4[2] + feature_map4[3])) + (feature_map4[4] + feature_map4[5]);
assign conv5_result = ((feature_map5[0] + feature_map5[1]) + (feature_map5[2] + feature_map5[3])) + (feature_map5[4] + feature_map5[5]);

assign conv_result = ((conv1_result + conv2_result) + (conv3_result + conv4_result)) + conv5_result;

// calculate_valid 
// assign calculate_valid = ((current_x[3] ^ current_x[2]) & (current_y[3] ^ current_y[2])) ? 1'b1 : 1'b0;
assign calculate_valid = 1'b1;

// current_x
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        current_x <= 4'b0;
    end
    else if (current_state == `CIRCLE_SEARCH) begin
        current_x <= (counter + 1) % 5'b10000;
    end
    else begin
        current_x <= 4'b0;
    end
end

// current_y
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        current_y <= 4'b0;
    end
    else if (current_state == `CIRCLE_SEARCH) begin
        current_y <= (counter + 1) / 5'b10000;
    end
    else begin
        current_y <= 4'b0;
    end
end

// tx
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        tx <= 4'b0;
    end
    else if (next_state == `CIRCLE_SEARCH && current_state == `ENTER_INPUT) begin
        tx <= 4'b0;
    end
    else if (current_state == `CIRCLE_SEARCH && (conv_result > t_max)) begin
        tx <= current_x;
    end
end

// ty
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        ty <= 4'b0;
    end
    else if (next_state == `CIRCLE_SEARCH && current_state == `ENTER_INPUT) begin
        ty <= 4'b0;
    end
    else if (current_state == `CIRCLE_SEARCH && (conv_result > t_max)) begin
        ty <= current_y;
    end
end

// load_x
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        load_x <= 4'b0;
    end
    else if (current_state == `COMPARE) begin
        if (first_swap & ~counter[0]) begin
            load_x <= tx;
        end
        else if (~circle_select & counter[0]) begin
            load_x <= C1X;
        end
        else if (circle_select & counter[0]) begin
            load_x <= C2X;
        end
    end
end

// load_y
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        load_y <= 4'b0;
    end
    else if (current_state == `COMPARE) begin
        if (first_swap & ~counter[0]) begin
            load_y <= ty;
        end
        else if (~circle_select & counter[0]) begin
            load_y <= C1Y;
        end
        else if (circle_select & counter[0]) begin
            load_y <= C2Y;
        end
    end
end

// t_max 
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        t_max <= 8'b0;
    end
    else if (current_state == `CIRCLE_SEARCH) begin
        if (conv_result > t_max) begin
            t_max <= conv_result;
        end
    end
    else begin
        t_max <= 8'b0;
    end
end

///////////////////////// `compare /////////////////////////

// temp_circle_1
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        temp_circle_1 <= 49'b0;
    end
    else if (current_state == `COMPARE && (~circle_select & ~counter[0])) begin
        temp_circle_1[48] <= input_map[255-(tx+16*(ty-4))];
        temp_circle_1[47:43] <= input_map[255-((tx-2)+16*(ty-3))-:5];
        temp_circle_1[42:36] <= input_map[255-((tx-3)+16*(ty-2))-:7];
        temp_circle_1[35:29] <= input_map[255-((tx-3)+16*(ty-1))-:7];
        temp_circle_1[28:20] <= input_map[255-((tx-4)+16*ty)-:9];
        temp_circle_1[19:13] <= input_map[255-((tx-3)+16*(ty+1))-:7];
        temp_circle_1[12:6] <= input_map[255-((tx-3)+16*(ty+2))-:7];
        temp_circle_1[5:1] <= input_map[255-((tx-2)+16*(ty+3))-:5];
        temp_circle_1[0] <= input_map[255-(tx+16*(ty+4))];
    end
    else if (current_state == `ENTER_INPUT) begin
        temp_circle_1 <= 49'b0;
    end
end

// temp_circle_2
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        temp_circle_2 <= 49'b0;
    end
    else if (current_state == `COMPARE && (circle_select & ~counter[0])) begin
        temp_circle_2[48] <= input_map[255-(tx+16*(ty-4))];
        temp_circle_2[47:43] <= input_map[255-((tx-2)+16*(ty-3))-:5];
        temp_circle_2[42:36] <= input_map[255-((tx-3)+16*(ty-2))-:7];
        temp_circle_2[35:29] <= input_map[255-((tx-3)+16*(ty-1))-:7];
        temp_circle_2[28:20] <= input_map[255-((tx-4)+16*ty)-:9];
        temp_circle_2[19:13] <= input_map[255-((tx-3)+16*(ty+1))-:7];
        temp_circle_2[12:6] <= input_map[255-((tx-3)+16*(ty+2))-:7];
        temp_circle_2[5:1] <= input_map[255-((tx-2)+16*(ty+3))-:5];
        temp_circle_2[0] <= input_map[255-(tx+16*(ty+4))];
    end
    else if (current_state == `ENTER_INPUT) begin
        temp_circle_2 <= 49'b0;
    end
end

// circle_load
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        circle_load <= 49'b0;
    end
    else if (current_state == `COMPARE && ~counter[0]) begin
        if (circle_select) begin
            circle_load <= temp_circle_1;
        end
        else begin
            circle_load <= temp_circle_2;
        end
    end
    else if (current_state == `ENTER_INPUT) begin
        circle_load <= 49'b0;
    end
end

// C1X 
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        C1X <= 4'b0;
    end
    else if (current_state == `ENTER_INPUT) begin
        C1X <= 4'b0;
    end
    else if (current_state == `COMPARE && (~circle_select) && ~counter[0]) begin
        C1X <= tx;
    end
end

// C1Y 
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        C1Y <= 4'b0;
    end
    else if (current_state == `ENTER_INPUT) begin
        C1Y <= 4'b0;
    end
    else if (current_state == `COMPARE && (~circle_select) && ~counter[0]) begin
        C1Y <= ty;
    end
end

// C2X 
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        C2X <= 4'b0;
    end
    else if (current_state == `ENTER_INPUT) begin
        C2X <= 4'b0;
    end
    else if (current_state == `COMPARE && circle_select && ~counter[0]) begin
        C2X <= tx;
    end
end

// C2Y 
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        C2Y <= 4'b0;
    end
    else if (current_state == `ENTER_INPUT) begin
        C2Y <= 4'b0;
    end
    else if (current_state == `COMPARE && circle_select && ~counter[0]) begin
        C2Y <= ty;
    end
end

// match_circle_1
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        match_circle_1 <= 1'b0;
    end
    else if (next_state == `COMPARE && (~circle_select)) begin
        if ((C1X == tx) && (C1Y == ty)) begin
            match_circle_1 <= 1'b1;
        end
        else begin
            match_circle_1 <= 1'b0;
        end
    end
    else if (current_state == `ENTER_INPUT) begin
        match_circle_1 <= 1'b0;
    end
end

// match_circle_2
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        match_circle_2 <= 1'b0;
    end
    else if (next_state == `COMPARE && circle_select) begin
        if ((C2X == tx) && (C2Y == ty)) begin
            match_circle_2 <= 1'b1;
        end
        else begin
            match_circle_2 <= 1'b0;
        end
    end
    else if (current_state == `ENTER_INPUT) begin
        match_circle_2 <= 1'b0;
    end
end

// DONE
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        DONE <= 1'b0;
    end
    else if (current_state == `COMPARE && (~counter[0] & match_circle_1 & match_circle_2)) begin
        DONE <= 1'b1;
    end
    else begin
        DONE <= 1'b0;
    end
end

///////////////////////// finite state machine /////////////////////////

assign first_enter_state = (current_state ^ next_state) ? 1'b1 : 1'b0;

// counter (start from 0)
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        counter <= 9'b0;
    end
    else if (first_enter_state && (|counter)) begin   // reset to zero before enter to new state
        counter <= 9'b0;
    end
    else begin
        counter <= counter + 1;
    end
end

// first_swap
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        first_swap <= 1'b0;
    end
    else if (current_state == `ENTER_INPUT) begin
        first_swap <= 1'b1;
    end
    else if (current_state == `COMPARE && counter[0]) begin
        first_swap <= 1'b0;
    end
end

// circle_select
always @(posedge CLK or posedge RST) begin 
    if (RST) begin
        circle_select <= 1'b0;
    end
    else if (current_state == `ENTER_INPUT) begin
        circle_select <= 1'b0;
    end
    else if ((next_state == `CIRCLE_SEARCH) && (current_state == `COMPARE)) begin // switch circle and state simultaneously
        circle_select <= ~circle_select;
    end
end

// current_state
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        current_state <= 2'b0;
    end
    else begin
        current_state <= next_state;
    end  
end

always @(*) begin
    case (current_state)
        `ENTER_INPUT:begin // after 40 cycles
            next_state = (&{counter[5], counter[2], counter[1], counter[0]}) ? `CIRCLE_SEARCH : `ENTER_INPUT;
        end
        `CIRCLE_SEARCH:begin // after 256 cycles
            next_state = (&counter) ? `COMPARE : `CIRCLE_SEARCH;
        end
        `COMPARE:begin // after 2 cycles
            next_state = (counter[0]) ? ((DONE) ? `ENTER_INPUT : `CIRCLE_SEARCH) :`COMPARE;
            // next_state = (counter[0] & DONE) ? `ENTER_INPUT : `CIRCLE_SEARCH;
        end
    endcase
end

endmodule


