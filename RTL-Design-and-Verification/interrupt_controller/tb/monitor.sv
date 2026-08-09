class monitor;

    virtual intr_if vif;

    mailbox #(transaction) mon2scb;

    function new(
        virtual intr_if vif,
        mailbox #(transaction) mon2scb
    );
        this.vif = vif;
        this.mon2scb = mon2scb;
    endfunction

    task run();

        transaction tr;

        forever begin

            @(posedge vif.clk);

            tr = new();

            tr.addr         = vif.addr;
            tr.wdata        = vif.wdata;
            tr.we           = vif.we;
            tr.ci           = vif.ci;

            tr.rdata        = vif.rdata;

            tr.core0_valid  = vif.core0_valid;
            tr.core0_id     = vif.core0_id;

            tr.core1_valid  = vif.core1_valid;
            tr.core1_id     = vif.core1_id;

            mon2scb.put(tr);

        end

    endtask

endclass