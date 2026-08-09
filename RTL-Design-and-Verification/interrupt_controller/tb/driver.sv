class driver;

    virtual intr_if vif;

    mailbox #(transaction) gen2drv;

    function new(
        virtual intr_if vif,
        mailbox #(transaction) gen2drv
    );
        this.vif = vif;
        this.gen2drv = gen2drv;
    endfunction


    task reset();

        vif.addr  <= 0;
        vif.wdata <= 0;
        vif.we    <= 0;
        vif.ci    <= 0;

        wait(vif.arst_n);

    endtask


    task run();

        transaction tr;

        forever begin

            gen2drv.get(tr);

            @(posedge vif.clk);

            vif.addr  <= tr.addr;
            vif.wdata <= tr.wdata;
            vif.we    <= tr.we;
            vif.ci    <= tr.ci;

            @(posedge vif.clk);

            vif.we <= 0;

        end

    endtask

endclass