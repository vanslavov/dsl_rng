module random_sampler #(
    parameter DATA_WIDTH = 12,    // Fit this to the bit size of the processed data
    parameter COUNTER_WIDTH = 17   // 2^17 = 131072 > 100000
)(
    input wire clk,                 // 12 MHz
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] processed_signal,
    output reg [DATA_WIDTH-1:0] seed,    // this is the seed captured by this module, it starts at 0, but once it captures the first seed it is stable, meaning it would not change the value until the next output pulse for one cycle
    output reg seed_valid                // this is normally 0, it will pulse 1 for 1 cycle if the module captures a seed.
);

    reg [COUNTER_WIDTH-1:0] counter;
    reg [COUNTER_WIDTH-1:0] lfsr;
    wire sample_trigger;

    // LFSR polynomial: x^17 + x^14 + 1 (maximal length)
    wire feedback = lfsr[16] ^ lfsr[13]; 

    // Free-running counter (0 to 100000, then wraps). This our free-running counter, it increase ever cyclye until 100000 cycles. Basically, 
    //This is the 'window of time' that the data will be sampled. 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            counter <= 0;
        else if (counter == 100000)
            counter <= 0;
        else
            counter <= counter + 1;
    end

    // Free-running LFSR. This will determine the point at which in the counter counter. psudo rng
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lfsr <= {COUNTER_WIDTH{1'b1}};  // avoid all-zeros lockup It shall initialise as 1....11111 and reduce, and step down by 1 each clock cycle
        else
            lfsr <= {lfsr[COUNTER_WIDTH-2:0], feedback};
    end

    // the sample trigger will go high when the counter matches the LSFR value
    assign sample_trigger = (lfsr <= 100000) && (counter == lfsr);


    // this is the part which capture the seed
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            seed       <= 0;        // initializing the seed and seed_valid to 0
            seed_valid <= 0;
        end else begin
            if (sample_trigger) begin    //if the sample_trigger is activated, it will capture the processed signal as 'seed' for the next step. and change the 'seed_valid' as high to let us know it has captured a seed.
                seed       <= processed_signal;
                seed_valid <= 1'b1;
            end else begin
                seed_valid <= 1'b0;
            end
        end
    end

endmodule
