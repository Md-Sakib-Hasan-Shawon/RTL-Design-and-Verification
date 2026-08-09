class scoreboard;

    mailbox #(transaction) mon2scb;

    bit [7:0] core0_src_en;
    bit [7:0] core1_src_en;

    bit [7:0] masked0;
    bit [7:0] masked1;

    function new(mailbox #(transaction) mon2scb);
        this.mon2scb = mon2scb;
    endfunction


    function automatic bit [2:0] priority_encoder(bit [7:0] value);

        priority_encoder = 3'd0;

        if      (value[0]) priority_encoder = 3'd0;
        else if (value[1]) priority_encoder = 3'd1;
        else if (value[2]) priority_encoder = 3'd2;
        else if (value[3]) priority_encoder = 3'd3;
        else if (value[4]) priority_encoder = 3'd4;
        else if (value[5]) priority_encoder = 3'd5;
        else if (value[6]) priority_encoder = 3'd6;
        else if (value[7]) priority_encoder = 3'd7;

    endfunction


    task run();

        transaction tr;

        forever begin

            mon2scb.get(tr);

            //------------------------------------
            // Update Register Model
            //------------------------------------
            if (tr.we) begin

                if (tr.addr == 3'h0)
                    core0_src_en = tr.wdata;

                else if (tr.addr == 3'h4)
                    core1_src_en = tr.wdata;

            end

            //------------------------------------
            // Core 0
            //------------------------------------
            masked0 = tr.ci & core0_src_en;

            if ((masked0 != 0) != tr.core0_valid)
                $error("CORE0 VALID MISMATCH");

            if (priority_encoder(masked0) != tr.core0_id)
                $error("CORE0 ID MISMATCH");

            //------------------------------------
            // Core 1
            //------------------------------------
            masked1 = tr.ci & core1_src_en;

            if ((masked1 != 0) != tr.core1_valid)
                $error("CORE1 VALID MISMATCH");

            if (priority_encoder(masked1) != tr.core1_id)
                $error("CORE1 ID MISMATCH");

        end

    endtask

endclass