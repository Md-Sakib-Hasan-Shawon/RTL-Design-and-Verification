// Synchronous FIFO (First In First Out -> Buffer)
module fifo_sync
  
    // Parameters section
    #( parameter FIFO_DEPTH = 8, // Number of elements in FIFO
       parameter DATA_WIDTH = 32) // Number of bits capacity in each element
  
    // Ports section   
	(input clk, 
     input rst_n,
     input cs,     // chip select	 
     input wr_en, 
     input rd_en, 
     input [DATA_WIDTH-1:0] data_in, 
     output reg [DATA_WIDTH-1:0] data_out, 
	 output empty,
	 output full); 

    // Memory Declaration  
  reg [DATA_WIDTH-1:0] fifo [0:FIFO_DEPTH-1];// Syntax: reg [WORD_WIDTH-1:0] memory_name [0:DEPTH-1];
  
  // Pointer Logic
  
  localparam FIFO_DEPTH_LOG = $clog2(FIFO_DEPTH);
	
	// For empty/full detection 1 extra bits at MSB for pointer
  reg [FIFO_DEPTH_LOG:0] write_pointer;//3:0
  reg [FIFO_DEPTH_LOG:0] read_pointer;//3:0

  //write operation
    always @(posedge clk or negedge rst_n) 
      begin
      if(!rst_n)//rst =0 system reset happens
		    write_pointer <= 0;
      else if (cs && wr_en && !full) begin
          fifo[write_pointer[FIFO_DEPTH_LOG-1:0]] <= data_in; //fifo[index] <= data_in
	       write_pointer <= write_pointer + 1'b1;
      end
      end
  
	//read operation
	always @(posedge clk or negedge rst_n) 
      begin
	    if(!rst_n)
		    read_pointer <= 0;
      else if (cs && rd_en && !empty) begin
        data_out <= fifo[read_pointer[FIFO_DEPTH_LOG-1:0]];       //data_out <=fifo[index]
	        read_pointer <= read_pointer + 1'b1;
      end
	end
	
	// Declare the empty/full logic
    assign empty = (read_pointer == write_pointer);
	assign full  = (read_pointer == {~write_pointer[FIFO_DEPTH_LOG], write_pointer[FIFO_DEPTH_LOG-1:0]});
  

endmodule
