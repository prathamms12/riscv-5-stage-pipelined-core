//-----------------------------------------------------------------------------
// File    : riscv_writeback.v
// Author  : Pratham
// Project : 5-Stage RISC-V (RV32IM) core
// Desc    : WB stage result mux
//-----------------------------------------------------------------------------
`include "riscv_defs.v"

module riscv_writeback
(
    input  wire [`RISCV_XLEN-1:0]       alu_result_i,
    input  wire [`RISCV_XLEN-1:0]       mem_data_i,
    input  wire [`RISCV_XLEN-1:0]       csr_data_i,
    input  wire [`RISCV_XLEN-1:0]       muldiv_data_i,
    input  wire [`RISCV_XLEN-1:0]       pc_plus4_i,

    input  wire [`WB_SEL_W-1:0]         wb_sel_i,
    input  wire                         reg_write_i,
    input  wire [`RISCV_REG_ADDR_W-1:0] rd_addr_i,

    output wire                         reg_write_o,
    output wire [`RISCV_REG_ADDR_W-1:0] rd_addr_o,
    output wire [`RISCV_XLEN-1:0]       rd_data_o
);

    reg [`RISCV_XLEN-1:0] rd_data_r;

    always @(*)
    begin
        case (wb_sel_i)
            `WB_SEL_ALU    : rd_data_r = alu_result_i;
            `WB_SEL_MEM    : rd_data_r = mem_data_i;
            `WB_SEL_CSR    : rd_data_r = csr_data_i;
            `WB_SEL_MULDIV : rd_data_r = muldiv_data_i;
            `WB_SEL_PC4    : rd_data_r = pc_plus4_i;
            default        : rd_data_r = alu_result_i;
        endcase
    end

    assign rd_data_o   = rd_data_r;
    assign reg_write_o = reg_write_i;
    assign rd_addr_o   = rd_addr_i;

endmodule
