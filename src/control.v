//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 21-May-25  DWW     1  Initial creation
//====================================================================================

/*

    AXI registers for status and control

*/


module control # (parameter AW=8, SW=24)
(
    input clk, resetn,

    input[SW-1:0] axis_in0_tdata,
    input         axis_in0_tuser,
    input         axis_in0_tvalid,

    input[SW-1:0] axis_in1_tdata,
    input         axis_in1_tuser,
    input         axis_in1_tvalid,

    //================== This is an AXI4-Lite slave interface ==================
        
    // "Specify write address"              -- Master --    -- Slave --
    input[AW-1:0]                           S_AXI_AWADDR,   
    input                                   S_AXI_AWVALID,  
    output                                                  S_AXI_AWREADY,
    input[2:0]                              S_AXI_AWPROT,

    // "Write Data"                         -- Master --    -- Slave --
    input[31:0]                             S_AXI_WDATA, 
    input[ 3:0]                             S_AXI_WSTRB,     
    input                                   S_AXI_WVALID,
    output                                                  S_AXI_WREADY,

    // "Send Write Response"                -- Master --    -- Slave --
    output[1:0]                                             S_AXI_BRESP,
    output                                                  S_AXI_BVALID,
    input                                   S_AXI_BREADY,

    // "Specify read address"               -- Master --    -- Slave --
    input[AW-1:0]                           S_AXI_ARADDR,     
    input                                   S_AXI_ARVALID,
    input[2:0]                              S_AXI_ARPROT,     
    output                                                  S_AXI_ARREADY,

    // "Read data back to master"           -- Master --    -- Slave --
    output[31:0]                                            S_AXI_RDATA,
    output                                                  S_AXI_RVALID,
    output[1:0]                                             S_AXI_RRESP,
    input                                   S_AXI_RREADY
    //==========================================================================
);  

genvar i;

//=========================  AXI Register Map  =============================
localparam REG_RESET       = 0;

localparam REG_PORT_0       = 16;
localparam REG_UNUSED_0     = 17;
localparam REG_FD_COUNT_0   = 18;
localparam REG_FD_COUNT_0L  = 19;
localparam REG_MD_COUNT_0   = 20;
localparam REG_MD_COUNT_0L  = 21;
localparam REG_FC_COUNT_0   = 22;
localparam REG_FC_COUNT_0L  = 23;
localparam REG_OTH_COUNT_0  = 24;
localparam REG_OTH_COUNT_0L = 25;
localparam REG_BAD_COUNT_0  = 26;
localparam REG_BAD_COUNT_0L = 27;


localparam REG_PORT_1       = 32;
localparam REG_UNUSED_1     = 33;
localparam REG_FD_COUNT_1   = 34;
localparam REG_FD_COUNT_1L  = 35;
localparam REG_MD_COUNT_1   = 36;
localparam REG_MD_COUNT_1L  = 37;
localparam REG_FC_COUNT_1   = 38;
localparam REG_FC_COUNT_1L  = 39;
localparam REG_OTH_COUNT_1  = 40;
localparam REG_OTH_COUNT_1L = 41;
localparam REG_BAD_COUNT_1  = 42;
localparam REG_BAD_COUNT_1L = 43;
//==========================================================================


//==========================================================================
// We'll communicate with the AXI4-Lite Slave core with these signals.
//==========================================================================
// AXI Slave Handler Interface for write requests
wire[31:0]  ashi_windx;     // Input   Write register-index
wire[31:0]  ashi_waddr;     // Input:  Write-address
wire[31:0]  ashi_wdata;     // Input:  Write-data
wire        ashi_write;     // Input:  1 = Handle a write request
reg[1:0]    ashi_wresp;     // Output: Write-response (OKAY, DECERR, SLVERR)
wire        ashi_widle;     // Output: 1 = Write state machine is idle

// AXI Slave Handler Interface for read requests
wire[31:0]  ashi_rindx;     // Input   Read register-index
wire[31:0]  ashi_raddr;     // Input:  Read-address
wire        ashi_read;      // Input:  1 = Handle a read request
reg[31:0]   ashi_rdata;     // Output: Read data
reg[1:0]    ashi_rresp;     // Output: Read-response (OKAY, DECERR, SLVERR);
wire        ashi_ridle;     // Output: 1 = Read state machine is idle
//==========================================================================

// The state of the state-machines that handle AXI4-Lite read and AXI4-Lite write
reg ashi_write_state, ashi_read_state;

// The AXI4 slave state machines are idle when in state 0 and their "start" signals are low
assign ashi_widle = (ashi_write == 0) && (ashi_write_state == 0);
assign ashi_ridle = (ashi_read  == 0) && (ashi_read_state  == 0);
   
// These are the valid values for ashi_rresp and ashi_wresp
localparam OKAY   = 0;
localparam SLVERR = 2;
localparam DECERR = 3;

// The address mask is 'AW' 1-bits in a row
localparam ADDR_MASK = (1 << AW) - 1;

// Arrays that represent the two input streams
wire[15:0] axis_in_length[0:1];
wire[ 7:0] axis_in_port  [0:1];
wire       axis_in_bad  [0:1];
wire       axis_in_tvalid[0:1];

// Map the input streams into arrays
assign axis_in_length[0] = axis_in0_tdata[15:0];
assign axis_in_port  [0] = axis_in0_tdata[23:16];
assign axis_in_bad   [0] = axis_in0_tuser;
assign axis_in_tvalid[0] = axis_in0_tvalid;
assign axis_in_length[1] = axis_in1_tdata[15:0];
assign axis_in_port  [1] = axis_in1_tdata[23:16];
assign axis_in_bad   [1] = axis_in1_tuser;
assign axis_in_tvalid[1] = axis_in1_tvalid;


// Counters (etc) for packets
reg[ 7:0] port_number[0:1];
reg[63:0] fd_packets [0:1];
reg[63:0] md_packets [0:1];
reg[63:0] fc_packets [0:1];
reg[63:0] oth_packets[0:1];
reg[63:0] bad_packets[0:1];

// Define the sizes of some important packet types
localparam FD_LENGTH = 64 + 4096;
localparam MD_LENGTH = 64 + 128;
localparam FC_LENGTH = 64 + 4;

// When this is a '1', the packet counters are all reset to 0
reg reset_counters;


//==========================================================================
// Every time a data-cycle arrives on one of the input streams, increment
// the appropriate counter
//==========================================================================
for (i=0; i<2; i=i+1) begin
    always @(posedge clk) begin
        
        if (resetn == 0 || reset_counters) begin
            bad_packets[i] <= 0;
            fd_packets [i] <= 0;
            md_packets [i] <= 0;
            fc_packets [i] <= 0;
            oth_packets[i] <= 0;
            port_number[i] <= 8'hFF;
        end

        else if (axis_in_tvalid[i]) begin
            
            if (axis_in_bad[i])
                bad_packets[i] <= bad_packets[i] + 1;
            
            else if (axis_in_length[i] == FD_LENGTH)
                fd_packets[i]  <= fd_packets[i] + 1;

            else if (axis_in_length[i] == MD_LENGTH)
                md_packets[i]  <= md_packets[i] + 1;

            else if (axis_in_length[i] == FC_LENGTH)
                fc_packets[i]  <= fc_packets[i] + 1;

            else
                oth_packets[i] <= oth_packets[i] + 1;

            if (axis_in_bad[i] == 0)
                port_number[i] <= axis_in_port[i];

        end
    end
end
//==========================================================================



//==========================================================================
// This state machine handles AXI4-Lite write requests
//==========================================================================
always @(posedge clk) begin

    // This will strobe high for a single cycle at a time
    reset_counters <= 0;

    // If we're in reset, initialize important registers
    if (resetn == 0) begin
        ashi_write_state  <= 0;

    // Otherwise, we're not in reset...
    end else case (ashi_write_state)
        
        // If an AXI write-request has occured...
        0:  if (ashi_write) begin
       
                // Assume for the moment that the result will be OKAY
                ashi_wresp <= OKAY;              
            
                // ashi_windex = index of register to be written
                case (ashi_windx)
               
                    REG_RESET: reset_counters <= 1;

                    // Writes to any other register are a decode-error
                    default: ashi_wresp <= DECERR;
                endcase
            end

        // Dummy state, doesn't do anything
        1: ashi_write_state <= 0;

    endcase
end
//==========================================================================





//==========================================================================
// World's simplest state machine for handling AXI4-Lite read requests
//==========================================================================
always @(posedge clk) begin

    // If we're in reset, initialize important registers
    if (resetn == 0) begin
        ashi_read_state <= 0;
    
    // If we're not in reset, and a read-request has occured...        
    end else if (ashi_read) begin
   
        // Assume for the moment that the result will be OKAY
        ashi_rresp <= OKAY;              
        
        // ashi_rindex = index of register to be read
        case (ashi_rindx)
            
            // Allow a read from any valid register                
            REG_PORT_0:         ashi_rdata <= port_number[0];
            REG_FD_COUNT_0:     ashi_rdata <= fd_packets [0][63:32];
            REG_FD_COUNT_0L:    ashi_rdata <= fd_packets [0][31:00];
            REG_MD_COUNT_0:     ashi_rdata <= md_packets [0][63:32];
            REG_MD_COUNT_0L:    ashi_rdata <= md_packets [0][31:00];
            REG_FC_COUNT_0:     ashi_rdata <= fc_packets [0][63:32];
            REG_FC_COUNT_0L:    ashi_rdata <= fc_packets [0][31:00];
            REG_OTH_COUNT_0:    ashi_rdata <= oth_packets[0][63:32];
            REG_OTH_COUNT_0L:   ashi_rdata <= oth_packets[0][31:00];
            REG_BAD_COUNT_0:    ashi_rdata <= bad_packets[0][63:32];
            REG_BAD_COUNT_0L:   ashi_rdata <= bad_packets[0][31:00];


            // Reads of any other register are a decode-error
            default: ashi_rresp <= DECERR;

        endcase
    end
end
//==========================================================================



//==========================================================================
// This connects us to an AXI4-Lite slave core
//==========================================================================
axi4_lite_slave#(ADDR_MASK) i_axi4lite_slave
(
    .clk            (clk),
    .resetn         (resetn),
    
    // AXI AW channel
    .AXI_AWADDR     (S_AXI_AWADDR),
    .AXI_AWVALID    (S_AXI_AWVALID),   
    .AXI_AWREADY    (S_AXI_AWREADY),
    
    // AXI W channel
    .AXI_WDATA      (S_AXI_WDATA),
    .AXI_WVALID     (S_AXI_WVALID),
    .AXI_WREADY     (S_AXI_WREADY),

    // AXI B channel
    .AXI_BRESP      (S_AXI_BRESP),
    .AXI_BVALID     (S_AXI_BVALID),
    .AXI_BREADY     (S_AXI_BREADY),

    // AXI AR channel
    .AXI_ARADDR     (S_AXI_ARADDR), 
    .AXI_ARVALID    (S_AXI_ARVALID),
    .AXI_ARREADY    (S_AXI_ARREADY),

    // AXI R channel
    .AXI_RDATA      (S_AXI_RDATA),
    .AXI_RVALID     (S_AXI_RVALID),
    .AXI_RRESP      (S_AXI_RRESP),
    .AXI_RREADY     (S_AXI_RREADY),

    // ASHI write-request registers
    .ASHI_WADDR     (ashi_waddr),
    .ASHI_WINDX     (ashi_windx),
    .ASHI_WDATA     (ashi_wdata),
    .ASHI_WRITE     (ashi_write),
    .ASHI_WRESP     (ashi_wresp),
    .ASHI_WIDLE     (ashi_widle),

    // ASHI read registers
    .ASHI_RADDR     (ashi_raddr),
    .ASHI_RINDX     (ashi_rindx),
    .ASHI_RDATA     (ashi_rdata),
    .ASHI_READ      (ashi_read ),
    .ASHI_RRESP     (ashi_rresp),
    .ASHI_RIDLE     (ashi_ridle)
);
//==========================================================================



endmodule
