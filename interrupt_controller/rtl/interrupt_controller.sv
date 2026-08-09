module interrupt_controller #(
    parameter int ADDR_WIDTH = 3,
    parameter int DATA_WIDTH = 8
) (
    input  logic clk_i,
    input  logic arst_ni,
    input  logic [ADDR_WIDTH-1:0] addr_i,
    input  logic [DATA_WIDTH-1:0] wdata_i,
    input  logic we_i,
    output logic [DATA_WIDTH-1:0] rdata_o,
    input  logic [7:0]              ci,
    output logic [2:0]              core0_id,
    output logic                    core0_valid,
    output logic [2:0]              core1_id,
    output logic                    core1_valid

);
    
    logic [7:0] core_0_src_en;
    logic [7:0] core_1_src_en;
    logic [7:0] masked_i_core0;
    logic [7:0] masked_i_core1;


    //Write Operation

    always_ff @(posedge clk_i or negedge arst_ni) begin
        if (!arst_ni) begin
            core_0_src_en <= 8'b0;
            core_1_src_en <= 8'b0;
        end else if (we_i) begin
            if (addr_i == 'h0)      core_0_src_en <= wdata_i[7:0];
            else if (addr_i == 'h4) core_1_src_en <= wdata_i[7:0];
        end
    end

    //Read Operation

    always_comb
    rdata_o =  (addr_i == 'h0) ? core_0_src_en :
              ((addr_i == 'h4) ? core_1_src_en :
              '0);
              
    //Checking for valid interrupts
    assign masked_i_core0 = ci & core_0_src_en;
    assign masked_i_core1 = ci & core_1_src_en;

    //Core 0
    assign core0_valid = (masked_i_core0 != 8'b0);
    always_comb begin
        core0_id = 3'd0;
        if      (masked_i_core0[0]) core0_id = 3'd0;
        else if (masked_i_core0[1]) core0_id = 3'd1;
        else if (masked_i_core0[2]) core0_id = 3'd2;
        else if (masked_i_core0[3]) core0_id = 3'd3;
        else if (masked_i_core0[4]) core0_id = 3'd4;
        else if (masked_i_core0[5]) core0_id = 3'd5;
        else if (masked_i_core0[6]) core0_id = 3'd6;
        else if (masked_i_core0[7]) core0_id = 3'd7;
    end

    //Core 1
    assign core1_valid = (masked_i_core1 != 8'b0);
    always_comb begin
        core1_id = 3'd0;
        if      (masked_i_core1[0]) core1_id = 3'd0;
        else if (masked_i_core1[1]) core1_id = 3'd1;
        else if (masked_i_core1[2]) core1_id = 3'd2;
        else if (masked_i_core1[3]) core1_id = 3'd3;
        else if (masked_i_core1[4]) core1_id = 3'd4;
        else if (masked_i_core1[5]) core1_id = 3'd5;
        else if (masked_i_core1[6]) core1_id = 3'd6;
        else if (masked_i_core1[7]) core1_id = 3'd7;
    end

endmodule