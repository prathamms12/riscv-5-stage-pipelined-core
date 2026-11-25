//-----------------------------------------------------------------------------
// File    : riscv_fetch.v
// Author  : Pratham
// Project : 5-Stage RISC-V (RV32IM) core
// Desc    : IF stage: PC register, 1-cycle RAM latency alignment, stall hold, flush
//-----------------------------------------------------------------------------
`include "riscv_defs.v"

module riscv_fetch
#(
    parameter ADDR_WIDTH = 14          // word-address bits of the TCM
)
(
    input  wire                     clk_i,
    input  wire                     rst_i,          // active-high, async
    input  wire [`RISCV_XLEN-1:0]   boot_addr_i,
    input  wire                     stall_i,
    input  wire                     flush_i,
    input  wire                     redirect_i,
    input  wire [`RISCV_XLEN-1:0]   redirect_pc_i,

    output wire [ADDR_WIDTH-1:0]    imem_addr_o,    // word address
    input  wire [31:0]              imem_rdata_i,

    output wire [`RISCV_XLEN-1:0]   pc_o,           // PC of the instruction on instr_o
    output wire [31:0]              instr_o
);

    // ADDI x0, x0, 0
    localparam [31:0] NOP_INSTR = 32'h0000_0013;

    reg [`RISCV_XLEN-1:0] pc_q;          // PC being sent to the RAM
    reg [`RISCV_XLEN-1:0] pc_d_q;        // PC delayed one cycle (matches RAM output)
    reg [31:0]            instr_hold_q;  // instruction held across a stall
    reg                   stall_d_q;     // stall delayed one cycle

    wire [31:0] live_instr;

    always @(posedge clk_i or posedge rst_i)
    begin
        if (rst_i)
            pc_q <= boot_addr_i;
        else if (redirect_i)
            pc_q <= redirect_pc_i;
        else if (!stall_i)
            pc_q <= pc_q + 32'd4;
    end

    always @(posedge clk_i or posedge rst_i)
    begin
        if (rst_i)
            pc_d_q <= boot_addr_i;
        else if (!stall_i)
            pc_d_q <= pc_q;
    end

    // Single driver for instr_hold_q / stall_d_q
    always @(posedge clk_i or posedge rst_i)
    begin
        if (rst_i)
        begin
            stall_d_q    <= 1'b0;
            instr_hold_q <= NOP_INSTR;
        end
        else
        begin
            stall_d_q    <= stall_i;
            instr_hold_q <= instr_o;
        end
    end

    assign live_instr  = flush_i ? NOP_INSTR : imem_rdata_i;
    assign instr_o     = stall_d_q ? instr_hold_q : live_instr;

    // Byte PC -> word address
    assign imem_addr_o = pc_q[ADDR_WIDTH+1:2];
    assign pc_o        = pc_d_q;

endmodule
