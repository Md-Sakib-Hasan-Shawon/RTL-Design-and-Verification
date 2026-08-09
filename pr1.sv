module edge_detector #(
    parameter int EDGE_TYPE = 0
)(
    input  logic clk,
    input  logic rst_n,
    input  logic signal_in,

    output logic edge_pulse
);

    // Previous sampled value
    logic signal_prev;

    //----------------------------------------------------------
    // Register previous input value
    //----------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n)
            signal_prev <= 1'b0;
        else
            signal_prev <= signal_in;
    end

    //----------------------------------------------------------
    // Edge detection logic
    //----------------------------------------------------------
    always_comb begin

        case (EDGE_TYPE)

            // Rising edge
            0:
                edge_pulse = (~signal_prev) & signal_in;

            // Falling edge
            1:
                edge_pulse = signal_prev & (~signal_in);

            // Both edges
            2:
                edge_pulse = signal_prev ^ signal_in;

            default:
                edge_pulse = 1'b0;

        endcase

    end

endmodule



module ring_converter #(
    parameter int BIN_WIDTH  = 3,
    parameter int RING_WIDTH = (1 << BIN_WIDTH),
    parameter bit MODE = 1'b0
    // MODE = 0 : Binary to Ring
    // MODE = 1 : Ring to Binary
)(
    input  logic [BIN_WIDTH-1:0]  bin_in,
    input  logic [RING_WIDTH-1:0] ring_in,

    output logic [BIN_WIDTH-1:0]  bin_out,
    output logic [RING_WIDTH-1:0] ring_out
);


generate

    //====================================
    // Binary to Ring Converter
    //====================================
    if (MODE == 1'b0) begin : BIN_TO_RING

        always_comb begin

            ring_out = '0;

            ring_out[bin_in] = 1'b1;

            bin_out = '0;

        end

    end


    //====================================
    // Ring to Binary Converter
    //====================================
    else begin : RING_TO_BIN

        integer i;

        always_comb begin

            bin_out = '0;

            for(i = 0; i < RING_WIDTH; i++) begin

                if(ring_in[i])
                    bin_out = i[BIN_WIDTH-1:0];

            end

            ring_out = '0;

        end

    end


endgenerate


endmodule