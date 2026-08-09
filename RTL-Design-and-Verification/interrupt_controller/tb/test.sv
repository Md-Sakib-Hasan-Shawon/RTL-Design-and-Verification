class test;

    environment env;

    virtual intr_if vif;

    function new(virtual intr_if vif);

        this.vif = vif;

        env = new(vif);

    endfunction


    task run();

        env.run();

    endtask

endclass