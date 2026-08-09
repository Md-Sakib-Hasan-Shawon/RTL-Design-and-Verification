class generator;

    mailbox #(transaction) gen2drv;

    int num_transactions = 20;

    function new(mailbox #(transaction) gen2drv);
        this.gen2drv = gen2drv;
    endfunction

    task run();

        transaction tr;

        repeat(num_transactions) begin

            tr = new();

            assert(tr.randomize());

            gen2drv.put(tr);

            tr.display("GENERATOR");

        end

    endtask

endclass