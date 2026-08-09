class transaction;

    // Inputs to DUT
    rand bit [2:0] addr;
    rand bit [7:0] wdata;
    rand bit       we;
    rand bit [7:0] ci;

    // Outputs captured by monitor
    bit [7:0] rdata;

    bit [2:0] core0_id;
    bit       core0_valid;

    bit [2:0] core1_id;
    bit       core1_valid;

    function void display(string name="TRANSACTION");
        $display("----------------------------------------");
        $display("%s", name);
        $display("addr         = %0h", addr);
        $display("wdata        = %0h", wdata);
        $display("we           = %0b", we);
        $display("ci           = %0b", ci);
        $display("rdata        = %0h", rdata);
        $display("core0_valid  = %0b", core0_valid);
        $display("core0_id     = %0d", core0_id);
        $display("core1_valid  = %0b", core1_valid);
        $display("core1_id     = %0d", core1_id);
        $display("----------------------------------------");
    endfunction

endclass