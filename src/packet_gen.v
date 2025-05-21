//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 15-Aug-24  DWW     1  Initial creation
//====================================================================================

/*

    This module generates an arbitrary number of AXI4-Stream packets of arbitrary
    size and arbitrary spacing.

*/


module packet_gen # (parameter DW=512)
(
    input   clk, resetn,

    input[31:0] packet_count, 
    input[15:0] packet_length, idle_cycles, initial_value,

    // We start generating packets when this is asserted
    input   start,

    // This is asserted when we're not generating packets
    output  busy,

    // This is our output stream
    output     [DW-1:0]    axis_out_tdata,
    output reg [DW/8-1:0]  axis_out_tkeep,
    output                 axis_out_tlast,
    output                 axis_out_tvalid,
    input                  axis_out_tready
);

// This is the number of bytes in axis_out_tdata
localparam DB = (DW/8);

// How many bits does it take to represent "DB-1" ?
localparam LOG2_DB = $clog2(DB);

// This is 'LOG2_DB' '1' bits in a row
localparam DB_MASK = (1 << LOG2_DB) - 1;

// Current data-cycle, numbered 1 thru N
reg[15:0] cycle;

// The number of "packed full" cycles in the packet
reg [15:0] whole_data_cycles;

// The number of bytes in the (potentially) partially full last cycle
reg [15:0] partial_bytes;

// The total number of data-cycles in the packet
reg [15:0] total_data_cycles;

always @* begin

    // How many 'packed full' data cycles will there be?
    whole_data_cycles = (packet_length >> LOG2_DB);

    // If there's a "partial" cycle in the packet, how many bytes will it contain?
    partial_bytes = (packet_length & DB_MASK);

    // This is the total number of data-cycle required for this packet
    total_data_cycles = whole_data_cycles + (partial_bytes != 0);

    // Fill in 'axis_out_tkeep' with either "all bits set" or the final partial value
    axis_out_tkeep = (axis_out_tlast && partial_bytes) ? (1 << partial_bytes)-1 : -1;

end

// The state of our state machine
reg[1:0] fsm_state;

// This is a rolling counter that will be replicated across axis_out_tdata
reg[15:0] data;

// axis_out_tlast is asserted on the last cycle of the packet
assign axis_out_tlast = (cycle == total_data_cycles);

// Repeat 'data' across the width of axis_out_tdata
assign axis_out_tdata = {(DW/16){data}};

// This is the number of the packet currently being emitted
reg[31:0] packet_number;

// The number of clock cycles to pause for
reg[15:0] delay_count;

// We're emitting valid data any time we're in state 1
assign axis_out_tvalid = (resetn == 1) && (fsm_state == 1);

// Tell the outside world when we are busy generating packets
assign busy = start | (fsm_state !=0);

always @(posedge clk) begin

    if (resetn == 0) begin
        fsm_state <= 0;
    end

    else case(fsm_state)

        // Are we being told to start generating packets?
        0:  if (start) begin
                data          <= initial_value;
                cycle         <= 1;
                packet_number <= 1;
                fsm_state     <= 1;
            end


        1:  if (axis_out_tready & axis_out_tvalid) begin       // If this data-cycle has a handshake...
                data  <= data  + 1;                            //  Next data-cycle has new data
                cycle <= cycle + 1;                            //  Keep track of the data-cycle number
                if (axis_out_tlast) begin                      //  If this was the last cycle of the packet...
                    cycle <= 1;                                //   Reset the cycle number
                    if (packet_number == packet_count)         //   If this was the last packet...
                        fsm_state <= 0;                        //    Go back to idle mode
                    else begin                                 //   This wasn't the last packet
                        packet_number <= packet_number + 1;    //    Keep track of how many packets we emit
                        if (idle_cycles) begin                 //    Do we need to generate idle cycles?
                            delay_count <= idle_cycles - 1;    //     Determine how many idle cycles we need
                            fsm_state   <= 2;                  //     And go be idle for that many clock cycles
                        end
                    end
                end
            end

        2:  if (delay_count == 0)                              // If we've delayed long enough...
                fsm_state <= 1;                                //   Go back to outputting data-cycles
            else                                               // Otherwise...
                delay_count <= delay_count - 1;                //   Do nothing for this clock cycle

    endcase

end


endmodule

