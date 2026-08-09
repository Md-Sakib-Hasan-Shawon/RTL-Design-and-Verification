class environment;

    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;

    mailbox #(transaction) gen2drv;
    mailbox #(transaction) mon2scb;

    virtual intr_if vif;

    function new(virtual intr_if vif);

        this.vif = vif;

        gen2drv = new();
        mon2scb = new();

        gen = new(gen2drv);
        drv = new(vif, gen2drv);
        mon = new(vif, mon2scb);
        scb = new(mon2scb);

    endfunction


    task run();

        drv.reset();

        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
        join_any

    endtask

endclass