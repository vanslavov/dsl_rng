// ==========================================
// 1. LFSR ALGORITHM (12-BIT)
// ==========================================
module simple_lfsr_12bit (
    input wire clk,
    input wire reset,
    input wire [11:0] seed,      // Your 12-bit input seed
    output reg [11:0] rand_out   // Your 12-bit random output
);
    // The math that creates the randomness (XOR taps for 12-bit: 11, 5, 3, 0)
    wire feedback = rand_out[11] ^ rand_out[5] ^ rand_out[3] ^ rand_out[0];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Safety catch: LFSR locks up and crashes if the state is exactly 0.
            rand_out <= (seed == 0) ? 12'h001 : seed;
        end 
        else begin
            // Shift left and append the XOR feedback to the LSB
            rand_out <= {rand_out[10:0], feedback};
        end
    end
endmodule

// ==========================================
// 2. TESTBENCH
// ==========================================
module tb_simple_lfsr_12bit;

    reg [11:0] MY_SEED = 12'h36b; // can declare seed here

    reg clk;
    reg reset;
    wire [11:0] rand_out;

    simple_lfsr_12bit uut (
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
        reset = 0; // Starts the LFSR algorithm
        #400;      // Runs for 40 clock cycles
        $display("Final Random Output: %0d", rand_out);
        
        $finish; 
    end

// If you want to see all outputs from the LFSR cycles
    //always @(posedge clk) begin
        //if (!reset) $display("LFSR Random Output: %0d", rand_out);
    //end
endmodule