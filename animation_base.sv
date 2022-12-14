/* 
 * Animation
 *
 * Top level module for line_drawer.sv and clear_screen.sv,
 * creates an animation using the two modules.
 * 
 */
module animation_base(input  logic clk, reset,
                 input  logic [27:0] new_clock,
                 output logic color,
                 output logic [10:0] x, y);

    // 26'd50000000 represents 1 second of delay
    logic [27:0] delay_counter;
    logic frame_counter; // tracks which frame to draw out
    logic [11:0] lines_counter; // edit if needed
    logic frame_complete, reset_start;
    // inputs to submodules, manipulate these values
    logic [10:0] x0, y0, x1, y1;
    logic [10:0] x0_pre, y0_pre, x1_pre, y1_pre, y_offset, x_offset;
    logic lines_start, clear_start;
    // outputs from submodules, no need to manipulate
    logic [10:0] lines_x, lines_y, clear_x, clear_y;
    logic lines_done, clear_done, flip_x, flip_y;

    // instantiate modules
    line_drawer lines(.x(lines_x), .y(lines_y), .reset(lines_start), .done(lines_done), .*);
    clear_screen clear(.x(clear_x), .y(clear_y), .reset(clear_start), .done(clear_done), .*);
    trigger_fsm r_trigger(.in(reset), .out(reset_start), .*);

    // x & y outputs depends on pixel color
    assign x = (color == 1'd1) ? lines_x : clear_x;
    assign y = (color == 1'd1) ? lines_y : clear_y;
    assign x0 = (x0_pre + x_offset) % 640;
    assign y0 = (y0_pre + y_offset) % 480;
    assign x1 = (x1_pre + x_offset) % 640;
    assign y1 = (y1_pre + y_offset) % 480;
    
    always_ff @(posedge clk) begin
        // reset registers
        if (reset) begin
            frame_complete <= 1'd0;
            delay_counter <= 0;
            frame_counter <= 1'd0;
            lines_counter <= 0; // edit this to include more lines
            color <= 1'd0; // black
            x0_pre <= 11'd0;
            y0_pre <= 11'd0;
            x1_pre <= 11'd0;
            y1_pre <= 11'd0;
            x_offset <= 0;
            y_offset <= 0;
        end
        
        if (reset_start) begin
            lines_start <= 1'd1;
            clear_start <= 1'd1;
        end

        // ensures the start signals are only on for one cycle
        if (lines_start == 1'b1)
            lines_start <= 1'b0;
        if (clear_start == 1'b1)
            clear_start <= 1'b0;

        
        /* === FRAMES PER SECOND CONTROL === */
        if (~reset) begin
            // frame delay logic
            if (delay_counter == new_clock) begin
                // increment counters after delay
                // frame_counter <= frame_counter + 1'd1;
                frame_complete <= 0;
                delay_counter <= 0;
                // clear drawing every 1 second
                clear_start <= 1;
                color <= 0; // black
            end else
                // increment delay counter
                delay_counter <= delay_counter + 26'd1;
        end

        /* === ANIMATION === */
        if (frame_counter == 1'd0 && ~frame_complete && clear_done && ~reset && ~clear_start) begin
            color <= 1; // white
            /* === RECTANGLE === */
            // line 1: (100, 100) -> (100, 300)
            if (~lines_start && lines_counter == 3'd0 && lines_done) begin
                x0 <= (11'd200 + x_offset) % 640;
                y0 <= (11'd200 + y_offset) % 480;
                x1 <= (11'd200 + x_offset) % 640;
                y1 <= (11'd400 + y_offset) % 480;
                lines_start <= 1'd1;
                lines_counter <= lines_counter + 1'd1;
            end 
            // line 2: (100, 300) -> (300, 300)
            if (~lines_start && lines_counter == 3'd1 && lines_done) begin
                x0 <= (11'd200 + x_offset) % 640;
                y0 <= (11'd400 + y_offset) % 480;
                x1 <= (11'd400 + x_offset) % 640;
                y1 <= (11'd400 + y_offset) % 480;
                lines_start <= 1'd1;
                lines_counter <= lines_counter + 1'd1;
            end
            // line 3: (300, 300) -> (300, 100)
            if (~lines_start && lines_counter == 3'd2 && lines_done) begin
                x0 <= (11'd400 + x_offset) % 640;
                y0 <= (11'd400 + y_offset) % 480;
                x1 <= (11'd400 + x_offset) % 640;
                y1 <= (11'd200 + y_offset) % 480;
                lines_start <= 1'd1;
                lines_counter <= lines_counter + 1'd1;
            end
            // line 4: (300, 100) -> (100, 100)
            if (~lines_start && lines_counter == 3'd3 && lines_done) begin
                x0 <= (11'd400 + x_offset) % 640;
                y0 <= (11'd200 + y_offset) % 480;
                x1 <= (11'd200 + x_offset) % 640;
                y1 <= (11'd200 + y_offset) % 480;
                lines_start <= 1'd1;
                // frame is complete
                lines_counter <= 0; // edit this later to change repeat behavior
                frame_complete <= 1'd1;
                x_offset <= x_offset + 20;
                y_offset <= y_offset + 10;
            end
        end
    end
endmodule // animation