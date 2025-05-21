
//=============================================================================
//                        ------->  Revision History  <------
//=============================================================================
//
//   Date     Who   Ver  Changes
//=============================================================================
// 20-May-25  DWW     1  Initial creation
//=============================================================================



module rx_packet_ctr # (parameter DW=512)
(
    input clk, resetn,
   
    output reg[ 7:0] port_number,
    output reg[63:0] bad_packets,
    output reg[63:0] fd_packets,
    output reg[63:0] md_packets,
    output reg[63:0] fc_packets,
    output reg[63:0] oth_packets,

    // The AXI stream that we're monitoring
    input[DW-1:0]   monitor_tdata,
    input[DW/8-1:0] monitor_tkeep,
    input           monitor_tlast,
    input           monitor_tvalid,
    input           monitor_tuser,
    output          monitor_tready
);

localparam FD_LEN = 4096 + 64;
localparam MD_LEN =  128 + 64;
localparam FC_LEN =    4 + 64;

// The inputs are registered
reg[DW-1:0]   reg_tdata;
reg           reg_tlast;
reg           reg_tvalid;
reg           reg_tready;
reg           reg_tuser;

// We also register the number of 1 bits in tkeep
reg[15:0]     reg_tkeep_count;

//=============================================================================
// one_bits() - This function counts the '1' bits in a field
//=============================================================================
integer i;
function[15:0] one_bits(input[(DW/8)-1:0] field);
begin
    one_bits = 0;
    for (i=0; i<(DW/8); i=i+1) one_bits = one_bits + field[i];
end
endfunction
//=============================================================================


//=============================================================================
// Register the input stream
//=============================================================================
always @(posedge clk) begin

    if (resetn == 0) begin
        reg_tdata       <= 0;
        reg_tlast       <= 0;
        reg_tvalid      <= 0;
        reg_tready      <= 0;
        reg_tuser       <= 0;
        reg_tkeep_count <= 0;
    end

    else begin
        reg_tdata       <= monitor_tdata;
        reg_tlast       <= monitor_tlast;
        reg_tuser       <= monitor_tuser;
        reg_tvalid      <= monitor_tvalid;
        reg_tready      <= monitor_tready;
        reg_tkeep_count <= one_bits(monitor_tkeep);
    end

end
//=============================================================================

// Total length of the packet except for the cycle with TLAST asserted
reg[15:0] partial_length;

// This tracks the length of the packet as we see each data-cycle
wire[15:0] packet_length = partial_length + reg_tkeep_count;

always @(posedge clk) begin

    if (resetn == 0) begin
        partial_length <= 0;
        bad_packets    <= 0;
        fd_packets     <= 0;
        md_packets     <= 0;
        fc_packets     <= 0;
        oth_packets    <= 0;
    end


    // If a data-handshake is occuring...
    else if (reg_tvalid & reg_tready) begin
       
        // Accumulate the partial length of the packet
        partial_length <= packet_length;

        // On the last data-cycle of the packet, update the counters
        if (reg_tlast) begin

            if (reg_tuser)
                bad_packets <= bad_packets + 1;
            
            else if (packet_length == FD_LEN)
                fd_packets <= fd_packets + 1;

            else if (packet_length == MD_LEN)
                md_packets <= md_packets + 1;

            else if (packet_length == FC_LEN)
                fc_packets <= fc_packets + 1;
            
            else
                oth_packets <= oth_packets + 1;

            partial_length <= 0;
        end
    end
end

assign monitor_tready = (resetn == 1);

endmodule