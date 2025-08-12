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
output [39:0] point_location_,
output [6:0] point_amount_,
output [39:0] max_point_location_,
output [39:0] previous_circle_location_,
output [3:0] c_x,
output [3:0] c_y,
output [1:0] next_s,
output [1:0] current_s,
output [7:0] counter_counter,
output [7:0] t_max_
);

// define state
`define ENTER_INPUT 2'b0
`define CIRCLE_SEARCH 2'b01
`define COMPARE 2'b10

integer i;

reg [3:0] input_x [0:39];
reg [3:0] input_y [0:39];

reg [1:0] current_state;
reg [1:0] next_state;
reg [7:0] counter;
reg circle_select;  // 0 is circle 1, 1 is circle 2
reg first_swap;

reg [3:0] current_x;
reg [3:0] current_y;
reg [3:0] best_x;
reg [3:0] best_y;
reg [7:0] t_max;

reg match_circle_1;
reg match_circle_2;

wire first_enter_state;

reg [39:0] point_location;
reg [6:0] point_amount;
reg [39:0] max_point_location;
reg [39:0] previous_circle_location;

assign point_location_ = point_location;
assign point_amount_ = point_amount;
assign max_point_location_ = max_point_location;
assign previous_circle_location_ = previous_circle_location;

assign c_x = current_x;
assign c_y = current_y;
assign next_s = next_state;
assign current_s = current_state;
assign counter_counter = counter;
assign t_max_ = t_max;

///////////////////////// enter input /////////////////////////

// input_x
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        for (i=0;i<40;i=i+1) begin
            input_x[i] <= 4'b0;
        end
    end
    else if (current_state == `ENTER_INPUT) begin
        input_x[counter] <= X;
    end
end

// input_y
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        for (i=0;i<40;i=i+1) begin
            input_y[i] <= 4'b0;
        end
    end
    else if (current_state == `ENTER_INPUT) begin
        input_y[counter] <= Y;
    end
end

///////////////////////// circle search /////////////////////////

reg signed [4:0] dx, dy;

// point_amount & point_location
always @(*) begin
    if (current_state == `CIRCLE_SEARCH) begin
        point_amount = 7'b0;
        for (i=0;i<40;i=i+1) begin
            dx = current_x-input_x[i];
            dy = current_y-input_y[i];
            if ((dx * dx) + (dy * dy) <= 16) begin
                point_location[39-i] = 1'b1;
                point_amount = point_amount + 1'b1;
            end
            else if (previous_circle_location[39-i]) begin
                point_amount = point_amount + 1'b1;
                point_location[39-i] = 1'b0;
            end
            else begin
                point_location[39-i] = 1'b0;
            end
        end
    end
end

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

// best_x
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        best_x <= 4'b0;
    end
    else if (next_state == `CIRCLE_SEARCH && current_state == `ENTER_INPUT) begin
        best_x <= 4'b0;
    end
    else if (current_state == `CIRCLE_SEARCH && (point_amount > t_max)) begin
        best_x <= current_x;
    end
end

// best_y
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        best_y <= 4'b0;
    end
    else if (next_state == `CIRCLE_SEARCH && current_state == `ENTER_INPUT) begin
        best_y <= 4'b0;
    end
    else if (current_state == `CIRCLE_SEARCH && (point_amount > t_max)) begin
        best_y <= current_y;
    end
end

// t_max 
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        t_max <= 8'b0;
    end
    else if (current_state == `CIRCLE_SEARCH) begin
        if (point_amount > t_max) begin
            t_max <= point_amount;
        end
    end
    else if (current_state == `COMPARE && ~counter[0]) begin
        t_max <= 8'b0;
    end
end

// max_point_location
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        max_point_location <= 40'b0;
    end
    else if (current_state == `CIRCLE_SEARCH) begin
        if (point_amount > t_max) begin
            max_point_location <= point_location;
        end
    end
    else if (current_state == `COMPARE && counter[0]) begin
        max_point_location <= 40'b0;
    end
end

// previous_circle_location
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        previous_circle_location <= 40'b0;
    end
    else if (current_state == `COMPARE && ~counter[0]) begin
        previous_circle_location <= 40'b0;
    end
    else if (current_state == `COMPARE && counter[0]) begin
        previous_circle_location <= max_point_location;
    end
end

///////////////////////// compare /////////////////////////

// C1X 
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        C1X <= 4'b0;
    end
    else if (current_state == `ENTER_INPUT) begin
        C1X <= 4'b0;
    end
    else if (current_state == `COMPARE && (~circle_select) && ~counter[0]) begin
        C1X <= best_x;
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
        C1Y <= best_y;
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
        C2X <= best_x;
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
        C2Y <= best_y;
    end
end

// match_circle_1
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        match_circle_1 <= 1'b0;
    end
    else if (next_state == `COMPARE && (~circle_select)) begin
        if ((C1X == best_x) && (C1Y == best_y)) begin
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
        if ((C2X == best_x) && (C2Y == best_y)) begin
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
        end
    endcase
end

endmodule


