interface intr_if();

    logic clk;
    logic arst_n;

    logic [2:0] addr;
    logic [7:0] wdata;
    logic       we;

    logic [7:0] rdata;

    logic [7:0] ci;

    logic [2:0] core0_id;
    logic       core0_valid;

    logic [2:0] core1_id;
    logic       core1_valid;

endinterface