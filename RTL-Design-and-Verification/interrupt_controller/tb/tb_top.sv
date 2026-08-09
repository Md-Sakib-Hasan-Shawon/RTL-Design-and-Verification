import tb_pkg::*;

module tb_top;

    intr_if intf();

    //----------------------------------------
    // Clock Generation
    //----------------------------------------
    initial begin
        intf.clk = 0;
        forever #5 intf.clk = ~intf.clk;
    end

    //----------------------------------------
    // Reset Generation
    //----------------------------------------
    initial begin
        intf.arst_n = 0;
        #20;
        intf.arst_n = 1;
    end

    //----------------------------------------
    // DUT
    //----------------------------------------
    interrupt_controller dut (

        .clk_i(intf.clk),
        .arst_ni(intf.arst_n),

        .addr_i(intf.addr),
        .wdata_i(intf.wdata),
        .we_i(intf.we),

        .rdata_o(intf.rdata),

        .ci(intf.ci),

        .core0_id(intf.core0_id),
        .core0_valid(intf.core0_valid),

        .core1_id(intf.core1_id),
        .core1_valid(intf.core1_valid)

    );

    //----------------------------------------
    // Test
    //----------------------------------------
    initial begin

        test t;

        t = new(intf);

        t.run();

    end

    //----------------------------------------
    // Simulation End
    //----------------------------------------
    initial begin

        #500;

        $display("================================");
        $display("      SIMULATION FINISHED");
        $display("================================");

        $finish;

    end

endmodule