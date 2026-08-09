/*

@foez-bhai, write the purpose of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

@foez-bhai, describe the use case of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

REVISION	DATE	AUTHOR	DESCRIPTION

0.1	YYYY-MM-DD	Md. Sakib Hasan Shawon	Initial version
1.0	YYYY-MM-DD	Md. Sakib Hasan Shawon	Stable release


Author : Md. Sakib Hasan Shawon (mdsakibhasanshawon20@gmail.com)
This file is part of ADN-VLSI/adn_axi
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/
`include "axil/typedef.svh"

ifndef ADDR_WIDTH   define ADDR_WIDTH 32
`endif

ifndef DATA_WIDTH   define DATA_WIDTH 32
`endif

AXIL_T(axil, ADDR_WIDTH, `DATA_WIDTH)

typedef axil_req_t axil_req_port_t;
typedef axil_resp_t axil_resp_port_t;

// @foez-bhai, add comments to the parameters, ports
module adn_common_axil_to_pmi #(

parameter int ADDR_WIDTH = `ADDR_WIDTH,  
parameter int DATA_WIDTH = `DATA_WIDTH,  
parameter int FIFO_DEPTH = 8

) (
//////////////////////////////////////////////////////////////////////////////////////////////
// GLOBAL
//////////////////////////////////////////////////////////////////////////////////////////////

// Clock input  
input logic clk,  

// Active-low asynchronous reset  
input logic arst_n,  


//////////////////////////////////////////////////////////////////////////////////////////////  
// AXI-LITE SLAVE INTERFACE  
//////////////////////////////////////////////////////////////////////////////////////////////  

// AXI-Lite slave request interface  
input axil_req_t s_axil_req,  

// AXI-Lite slave response interface  
output axil_resp_t s_axil_resp,  


//////////////////////////////////////////////////////////////////////////////////////////////  
// PMI MASTER INTERFACE  
//////////////////////////////////////////////////////////////////////////////////////////////  

// PMI request address  
output logic [ADDR_WIDTH-1:0] maddr,  

// PMI write enable  
output logic mwe,  

// PMI write data  
output logic [DATA_WIDTH-1:0] mwdata,  

// PMI byte write strobe  
output logic [DATA_WIDTH/8-1:0] mstrb,  

// PMI request valid  
output logic mreq,  

// PMI request grant  
input logic mgnt,  

// PMI transaction acknowledge  
input logic mack,  

// PMI read response data  
input logic [DATA_WIDTH-1:0] mrdata,  

// PMI response error indicator  
input logic mresp

);

// @foez-bhai, add comments to the functional blocks, signals, and submodules

//////////////////////////////////////////////////////////////////////////////////////////////////
// LOCALPARAMS GENERATED
//////////////////////////////////////////////////////////////////////////////////////////////////

// Byte strobe width
localparam int STRB_WIDTH = DATA_WIDTH / 8;

// FIFO pointer width
localparam int PTR_WIDTH = (FIFO_DEPTH <= 1) ? 1 : $clog2(FIFO_DEPTH);

// FIFO count width
localparam int COUNT_WIDTH = (FIFO_DEPTH <= 1) ? 1 : $clog2(FIFO_DEPTH + 1);

//////////////////////////////////////////////////////////////////////////////////////////////////
// TYPEDEFS
//////////////////////////////////////////////////////////////////////////////////////////////////

// PMI transaction descriptor
typedef struct packed {

// Transaction direction  
logic write;  

// Transaction address  
logic [ADDR_WIDTH-1:0] addr;  

// Write data  
logic [DATA_WIDTH-1:0] data;  

// Byte enable mask  
logic [STRB_WIDTH-1:0] strb;

} txn_t;

// Outstanding transaction descriptor
typedef struct packed {

// Transaction direction  
// 1 = write response  
// 0 = read response  
logic write;

} outstanding_t;

// AXI response storage descriptor
typedef struct packed {

// Response transaction type  
logic write;  

// Read response data  
logic [DATA_WIDTH-1:0] data;  

// AXI response code  
logic [1:0] resp;

} response_t;

//////////////////////////////////////////////////////////////////////////////////////////////////
// SIGNALS
//////////////////////////////////////////////////////////////////////////////////////////////////

// Request FIFO storage
txn_t txn_fifo[FIFO_DEPTH];

// Request FIFO pointers and counter
logic [PTR_WIDTH-1:0] txn_wr_ptr;
logic [PTR_WIDTH-1:0] txn_rd_ptr;
logic [COUNT_WIDTH-1:0] txn_count;

// Request FIFO status
logic txn_full;
logic txn_empty;

// AXI-Lite write address holding register
logic aw_valid_hold;
logic [ADDR_WIDTH-1:0] aw_addr_hold;

// AXI-Lite write data holding register
logic w_valid_hold;
logic [DATA_WIDTH-1:0] w_data_hold;
logic [STRB_WIDTH-1:0] w_strb_hold;

// AXI handshake signals
logic aw_accept;
logic w_accept;
logic ar_accept;

// Transaction push controls
logic write_push;
logic read_push;

logic [1:0] request_push_count;

// PMI transaction controls
logic txn_pop;

logic pmi_can_issue;
logic pmi_accept;

// Outstanding PMI transaction FIFO
outstanding_t outstanding_fifo[FIFO_DEPTH];

logic [PTR_WIDTH-1:0] out_wr_ptr;
logic [PTR_WIDTH-1:0] out_rd_ptr;

logic [COUNT_WIDTH-1:0] out_count;

logic out_push;
logic out_pop;

// PMI response FIFO
response_t response_fifo[FIFO_DEPTH];

logic [PTR_WIDTH-1:0] rsp_wr_ptr;
logic [PTR_WIDTH-1:0] rsp_rd_ptr;

logic [COUNT_WIDTH-1:0] rsp_count;

logic rsp_full;
logic rsp_empty;

logic response_push;
logic response_pop;

logic response_write;

logic response_do_push;

// Number of accepted PMI transactions without consumed AXI response
logic [COUNT_WIDTH:0] unconsumed_count;

logic response_from_new_request;

//////////////////////////////////////////////////////////////////////////////////////////////////
// ASSIGNMENTS
//////////////////////////////////////////////////////////////////////////////////////////////////

// Request FIFO empty/full status
assign txn_full = (txn_count == COUNT_WIDTH'(FIFO_DEPTH));

assign txn_empty = (txn_count == 0);

// Response FIFO empty/full status
assign rsp_full = (rsp_count == COUNT_WIDTH'(FIFO_DEPTH));

assign rsp_empty = (rsp_count == 0);

// Track accepted PMI transactions which have not yet generated
// AXI-consumed responses
assign unconsumed_count = {1'b0, out_count} + {1'b0, rsp_count};

// AXI-Lite handshake generation
assign aw_accept = arst_n && s_axil_req.aw_valid && s_axil_resp.aw_ready;

assign w_accept = arst_n && s_axil_req.w_valid && s_axil_resp.w_ready;

assign ar_accept = arst_n && s_axil_req.ar_valid && s_axil_resp.ar_ready;

// Generate write transaction insertion into request FIFO
assign write_push = aw_valid_hold && w_valid_hold && !txn_full;

// Generate read transaction insertion into request FIFO
assign read_push = ar_accept;

// Number of transactions inserted into request FIFO
assign request_push_count = {1'b0, write_push} + {1'b0, read_push};

// PMI resource availability
assign pmi_can_issue = (unconsumed_count < FIFO_DEPTH) || response_pop;

// PMI request generation
assign mreq = arst_n && !txn_empty && pmi_can_issue;

// PMI request acceptance
assign pmi_accept = arst_n && mreq && mgnt;

// Request FIFO pop occurs only after PMI grant
assign txn_pop = pmi_accept;

// Outstanding transaction FIFO control
assign out_push = pmi_accept && !response_from_new_request;

assign out_pop = mack && (out_count != 0);

// PMI response is stored whenever PMI acknowledges
assign response_push = arst_n && mack && ((out_count != 0) || pmi_accept);

assign response_do_push = response_push && (!rsp_full || response_pop);

assign response_from_new_request = mack && pmi_accept && (out_count == 0);

// AXI response FIFO consumption
assign response_pop =
!rsp_empty &&
(
(
response_fifo[rsp_rd_ptr].write &&
s_axil_resp.b_valid &&
s_axil_req.b_ready
)
||
(
!response_fifo[rsp_rd_ptr].write &&
s_axil_resp.r_valid &&
s_axil_req.r_ready
)
);

//////////////////////////////////////////////////////////////////////////////////////////////////
// METHODS
//////////////////////////////////////////////////////////////////////////////////////////////////

// FIFO pointer increment function
//
// Supports non power-of-two FIFO depths by explicitly wrapping
// the pointer at FIFO_DEPTH-1.
function automatic logic [PTR_WIDTH-1:0] ptr_inc(input logic [PTR_WIDTH-1:0] ptr);

if (ptr == PTR_WIDTH'(FIFO_DEPTH - 1)) ptr_inc = '0;  
else ptr_inc = ptr + 1'b1;

endfunction

//////////////////////////////////////////////////////////////////////////////////////////////////
// COMBINATIONAL LOGIC
//////////////////////////////////////////////////////////////////////////////////////////////////

// AXI-Lite ready and response generation
always_comb begin

s_axil_resp = '0;  


if (arst_n) begin  


  // Accept AXI write address when no address is buffered  
  s_axil_resp.aw_ready = !aw_valid_hold;  



  // Accept AXI write data when no data is buffered  
  s_axil_resp.w_ready  = !w_valid_hold;  



  // AXI read acceptance  
  //  
  // Reserve the final request FIFO slot for a completed  
  // write transaction if required.  
  if (txn_full) begin  

    s_axil_resp.ar_ready = 1'b0;  

  end else if (write_push && (txn_count == COUNT_WIDTH'(FIFO_DEPTH - 1))) begin  

    s_axil_resp.ar_ready = 1'b0;  

  end else begin  

    s_axil_resp.ar_ready = 1'b1;  

  end  



  // Generate AXI responses from response FIFO head  
  if (!rsp_empty) begin  


    if (response_fifo[rsp_rd_ptr].write) begin  


      // PMI write completion -> AXI B response  
      s_axil_resp.b_valid = 1'b1;  


      s_axil_resp.b.resp  = response_fifo[rsp_rd_ptr].resp;  


    end else begin  


      // PMI read completion -> AXI R response  
      s_axil_resp.r_valid = 1'b1;  


      s_axil_resp.r.data  = response_fifo[rsp_rd_ptr].data;  


      s_axil_resp.r.resp  = response_fifo[rsp_rd_ptr].resp;  


    end  

  end  

end

end

// PMI request payload generation
//
// Request FIFO head directly drives PMI.
// The FIFO pointer changes only after grant,
// therefore payload remains stable during stalls.
always_comb begin

maddr  = '0;  
mwe    = 1'b0;  
mwdata = '0;  
mstrb  = '0;  


if (arst_n && !txn_empty) begin  


  maddr = txn_fifo[txn_rd_ptr].addr;  


  mwe = txn_fifo[txn_rd_ptr].write;  


  mwdata = txn_fifo[txn_rd_ptr].data;  


  mstrb = txn_fifo[txn_rd_ptr].strb;  


end

end

// Determine response transaction type
always_comb begin

response_write = 1'b0;  


if (response_from_new_request) begin  

  // Zero latency PMI response.  
  // The accepted request completes immediately.  
  response_write = txn_fifo[txn_rd_ptr].write;  

end else if (out_count != 0) begin  

  // Response belongs to an older outstanding transaction.  
  response_write = outstanding_fifo[out_rd_ptr].write;  

end

end

//////////////////////////////////////////////////////////////////////////////////////////////////
// SEQUENTIALS
//////////////////////////////////////////////////////////////////////////////////////////////////

//================================================================================================
// AXI REQUEST CAPTURE AND REQUEST FIFO WRITE
//================================================================================================

always_ff @(posedge clk or negedge arst_n) begin

if (!arst_n) begin  


  aw_valid_hold <= 1'b0;  
  aw_addr_hold <= '0;  


  w_valid_hold <= 1'b0;  
  w_data_hold <= '0;  
  w_strb_hold <= '0;  


  txn_wr_ptr <= '0;  
  txn_count <= '0;  


end else begin  


  // Capture AXI write address  
  if (aw_accept) begin  

    aw_valid_hold <= 1'b1;  

    aw_addr_hold  <= s_axil_req.aw.addr;  

  end  



  // Capture AXI write data  
  if (w_accept) begin  

    w_valid_hold <= 1'b1;  

    w_data_hold  <= s_axil_req.w.data;  


    w_strb_hold  <= s_axil_req.w.strb;  

  end  



  // Store completed AXI write transaction  
  if (write_push) begin  


    txn_fifo[txn_wr_ptr].write <= 1'b1;  


    txn_fifo[txn_wr_ptr].addr <= aw_addr_hold;  


    txn_fifo[txn_wr_ptr].data <= w_data_hold;  


    txn_fifo[txn_wr_ptr].strb <= w_strb_hold;  



    aw_valid_hold <= 1'b0;  


    w_valid_hold <= 1'b0;  

  end  



  // Store AXI read transaction  
  if (read_push) begin  


    if (write_push) begin  


      txn_fifo[ptr_inc(txn_wr_ptr)].write <= 1'b0;  


      txn_fifo[ptr_inc(txn_wr_ptr)].addr  <= s_axil_req.ar.addr;  


      txn_fifo[ptr_inc(txn_wr_ptr)].data  <= '0;  


      txn_fifo[ptr_inc(txn_wr_ptr)].strb  <= '0;  


    end else begin  


      txn_fifo[txn_wr_ptr].write <= 1'b0;  


      txn_fifo[txn_wr_ptr].addr  <= s_axil_req.ar.addr;  


      txn_fifo[txn_wr_ptr].data  <= '0;  


      txn_fifo[txn_wr_ptr].strb  <= '0;  


    end  

  end  



  // Update request FIFO write pointer  
  case (request_push_count)  

    2'd1: txn_wr_ptr <= ptr_inc(txn_wr_ptr);  


    2'd2: txn_wr_ptr <= ptr_inc(ptr_inc(txn_wr_ptr));  


    default: txn_wr_ptr <= txn_wr_ptr;  

  endcase  



  // Request FIFO count update  
  case ({  
    request_push_count, txn_pop  
  })  

    3'b001: txn_count <= txn_count - 1;  

    3'b010: txn_count <= txn_count + 1;  

    3'b011: txn_count <= txn_count;  

    3'b100: txn_count <= txn_count + 2;  

    3'b101: txn_count <= txn_count + 1;  

    default: txn_count <= txn_count;  

  endcase  

end

end

//================================================================================================
// REQUEST FIFO POP AND OUTSTANDING TRANSACTION FIFO
//================================================================================================

always_ff @(posedge clk or negedge arst_n) begin

if (!arst_n) begin  


  txn_rd_ptr <= '0;  


  out_wr_ptr <= '0;  
  out_rd_ptr <= '0;  
  out_count  <= '0;  


end else begin  


  // Remove granted PMI request  
  if (txn_pop) begin  

    txn_rd_ptr <= ptr_inc(txn_rd_ptr);  

  end  



  // Store outstanding transaction  
  if (out_push) begin  


    outstanding_fifo[out_wr_ptr].write <= txn_fifo[txn_rd_ptr].write;  


    out_wr_ptr <= ptr_inc(out_wr_ptr);  

  end  



  // Remove completed outstanding transaction  
  if (out_pop) begin  

    out_rd_ptr <= ptr_inc(out_rd_ptr);  

  end  



  // Outstanding transaction count  
  case ({  
    out_push, out_pop  
  })  


    2'b10: out_count <= out_count + 1'b1;  


    2'b01: out_count <= out_count - 1'b1;  


    default: out_count <= out_count;  


  endcase  

end

end

//================================================================================================
// RESPONSE FIFO
//================================================================================================

always_ff @(posedge clk or negedge arst_n) begin

if (!arst_n) begin  


  rsp_wr_ptr <= '0;  
  rsp_rd_ptr <= '0;  
  rsp_count  <= '0;  


end else begin  


  // Store PMI completion response  
  if (response_do_push) begin  

    response_fifo[rsp_wr_ptr].write <= response_write;  
    response_fifo[rsp_wr_ptr].data <= mrdata;  
    response_fifo[rsp_wr_ptr].resp <= mresp ? 2'b10 : 2'b00;  

    rsp_wr_ptr <= ptr_inc(rsp_wr_ptr);  

  end  



  // Remove AXI consumed response  
  if (response_pop) begin  


    rsp_rd_ptr <= ptr_inc(rsp_rd_ptr);  


  end  



  // Response FIFO count  
  case ({  
    response_do_push, response_pop  
  })  


    2'b10: rsp_count <= rsp_count + 1'b1;  


    2'b01: rsp_count <= rsp_count - 1'b1;  


    default: rsp_count <= rsp_count;  


  endcase  

end

end

//////////////////////////////////////////////////////////////////////////////////////////////////
// INITIAL CHECKS
//////////////////////////////////////////////////////////////////////////////////////////////////

initial begin

if ((ADDR_WIDTH < 1) || (ADDR_WIDTH > 32)) begin  

  $error("ADDR_WIDTH must be between 1 and 32");  

end  



if ((DATA_WIDTH != 8) && (DATA_WIDTH != 16) && (DATA_WIDTH != 32) && (DATA_WIDTH != 64)) begin  

  $error("DATA_WIDTH must be 8,16,32,64");  

end  



if ((DATA_WIDTH % 8) != 0) begin  

  $error("DATA_WIDTH must be byte aligned");  

end  



if (FIFO_DEPTH < 1) begin  

  $error("FIFO_DEPTH must be >= 1");  

end

end

endmodule
