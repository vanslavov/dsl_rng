// ==========================================
// 1. LCG ALGORITHM (12-BIT)
// ==========================================
module simple_lcg_12bit (
    input wire clk,
    input wire reset,
    input wire [11:0] seed,      // Your 12-bit input seed
    output wire [11:0] rand_out  // Your 12-bit random output (Note: wire, not reg)
);
    // LCG needs a 32-bit internal state to generate good randomness
    reg [31:0] state;

    // Constants from "Numerical Recipes"
    localparam [31:0] MULTIPLIER = 32'd1664525;
    localparam [31:0] INCREMENT  = 32'd1013904223;

    // Combinational math for the next state
    wire [31:0] next_state = (state * MULTIPLIER) + INCREMENT;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Load your 12-bit seed into the top bits, pad the rest with 0s
            // LCG does not crash on 0, so no safety catch is needed.
            state <= {seed, 20'd0};
        end 
        else begin
            // Update the state
            state <= next_state;
        end
    end

    // Instantly extract the highest-quality 12 top bits for your output
    assign rand_out = state[31:20];

endmodule

// ==========================================
// 2. TESTBENCH
// ==========================================
module tb_simple_lcg_12bit;

    reg [11:0] MY_SEED = 12'h331; // can declare seed here

    reg clk;
    reg reset;
    wire [11:0] rand_out;

    simple_lcg_12bit uut (
        .clk(clk), 
        .reset(reset), 
        .seed(MY_SEED), 
        .rand_out(rand_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1; // Instantly loads your seed
        #10;
        reset = 0; // Starts the LCG algorithm
        #400;      // Runs for 40 clock cycles
        $display("Final Random Output: %0d", rand_out);
        
        $finish; 
    end

// If you want to see all outputs from the LCG cycles
    //always @(posedge clk) begin
        //if (!reset) $display("LCG Random Output: %0d", rand_out);
    //end
endmodule