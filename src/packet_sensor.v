//=============================================================================
//                        ------->  Revision History  <------
//=============================================================================
//
//   Date     Who   Ver  Changes
//=============================================================================
// 20-May-25  DWW     1  Initial creation
//=============================================================================

/*
    This module reads a packetized input stream and outputs a stream of 
    packet lengths.   On the last cycle of every input packet, it writes
    a data-cycle (containing the packet-length) to the output stream.
*/


module packet_sensor # (parameter DW=512)
(
    input clk, resetn,

    // The AXI stream that we're monitoring
    input[DW-1:0]   monitor_tdata,
    input[DW/8-1:0] monitor_tkeep,
    input           monitor_tlast,
    input           monitor_tvalid,
    input           monitor_tuser,
    output          monitor_tready,

    // A data-cycle containing the packet length clocks out every time
    // we see the last data-cycle of an incoming packet
    output reg[23:0]  axis_out_tdata,
    output reg        axis_out_tuser,
    output reg        axis_out_tvalid

);

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

// The port number associated with the packet, as determine by examining
// the packet header
reg[7:0] port_number;

// Total length of the packet except for the cycle with TLAST asserted
reg[15:0] partial_length;

// This tracks the length of the packet as we see each data-cycle
wire[15:0] packet_length = partial_length + reg_tkeep_count;

always @(posedge clk) begin

    axis_out_tvalid <= 0;

    if (resetn == 0) begin
        partial_length <= 0;
    end

    // If a data-handshake is occuring...
    else if (reg_tvalid & reg_tready) begin
       
        // Accumulate the partial length of the packet
        partial_length <= packet_length;

        // On the last data-cycle of the packet, output the packet length
        if (reg_tlast) begin
            axis_out_tdata  <= {port_number, packet_length};
            axis_out_tuser  <= reg_tuser;
            axis_out_tvalid <= 1;
            partial_length  <= 0;
        end
    
    end
end

assign monitor_tready = (resetn == 1);

endmodule