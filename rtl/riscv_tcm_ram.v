//-----------------------------------------------------------------------------
// File    : riscv_tcm_ram.v
// Author  : Pratham
// Project : 5-Stage RISC-V (RV32IM) core
// Desc    : Dual-port byte-write TCM RAM (A: instruction fetch, B: data/LSU), 1-cycle read
//-----------------------------------------------------------------------------
// 2^ADDR_WIDTH words x 4 bytes (default 16384 words = 64 KB)

module riscv_tcm_ram
#(
    parameter ADDR_WIDTH = 14
)
(
    input  wire                    clk_i,

    // Port A: instruction fetch / loader
    input  wire [ADDR_WIDTH-1:0]   addr_a_i,
    input  wire [31:0]             wdata_a_i,
    input  wire [3:0]              wstrb_a_i,
    output reg  [31:0]             rdata_a_o,

    // Port B: data (LSU)
    input  wire [ADDR_WIDTH-1:0]   addr_b_i,
    input  wire [31:0]             wdata_b_i,
    input  wire [3:0]              wstrb_b_i,
    output reg  [31:0]             rdata_b_o
);

    localparam DEPTH = (1 << ADDR_WIDTH);

    reg [31:0] mem [0:DEPTH-1];

    // Zero at time 0 so simulation never reads X
    integer i;
    initial
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'h0000_0000;

    // Port A
    always @(posedge clk_i)
    begin
        if (wstrb_a_i[0]) mem[addr_a_i][7:0]   <= wdata_a_i[7:0];
        if (wstrb_a_i[1]) mem[addr_a_i][15:8]  <= wdata_a_i[15:8];
        if (wstrb_a_i[2]) mem[addr_a_i][23:16] <= wdata_a_i[23:16];
        if (wstrb_a_i[3]) mem[addr_a_i][31:24] <= wdata_a_i[31:24];
        rdata_a_o <= mem[addr_a_i];
    end

    // Port B (each byte lane takes its own slice of wdata_b_i)
    always @(posedge clk_i)
    begin
        if (wstrb_b_i[0]) mem[addr_b_i][7:0]   <= wdata_b_i[7:0];
        if (wstrb_b_i[1]) mem[addr_b_i][15:8]  <= wdata_b_i[15:8];
        if (wstrb_b_i[2]) mem[addr_b_i][23:16] <= wdata_b_i[23:16];
        if (wstrb_b_i[3]) mem[addr_b_i][31:24] <= wdata_b_i[31:24];
        rdata_b_o <= mem[addr_b_i];
    end

endmodule
