`timescale 1ns / 1ps

module rng_algo_processor (
    input  wire        clk,
    input  wire        reset,
    input  wire        ap_valid,
    input  wire        seed_load,        // Checks if transformed signal created
    input  wire [11:0] de_corrbias_sig, // your VN/Markov output
    output reg  [31:0] rng_num_out
);

    // MCG parameters
    localparam [31:0] MCG_A = 32'h41C64E6D; // common good multiplier
    
    // LCG parameters
    localparam [31:0] LCG_A = 32'h343FD;
    localparam [31:0] LCG_C = 32'h269EC3;
    
    reg [31:0] mcg_state;
    reg [31:0] lcg_state;
    wire[31:0] transformed_seed;
    
    assign transformed_seed = (de_corrbias_sig * 32'h9E3779B1)^(de_corrbias_sig << 16)^(de_corrbias_sig << 4);

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            mcg_state <= 32'h1;
            lcg_state <= 32'h1;
            rng_num_out   <= 32'h0;

        end else if (seed_load) begin
            // seed from your transformed signal
            mcg_state <= transformed_seed ^ 32'hA5A5A5A5;
            lcg_state <= transformed_seed ^ 32'h5A5A5A5A;

        end else begin

            // MCG update
            mcg_state <= MCG_A * mcg_state;

           // MCG to LCG 
            lcg_state <= (LCG_A * mcg_state) + LCG_C;

            // RNG num output
            if (ap_valid) begin
                rng_num_out <= lcg_state;
            end 
        end
    end

endmodule