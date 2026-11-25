//-----------------------------------------------------------------------------
// File    : riscv_reg.v
// Author  : Pratham
// Project : 5-Stage RISC-V (RV32IM) core
// Desc    : 32x32 register file, x0 hard-wired to 0, same-cycle write bypass
//-----------------------------------------------------------------------------
`include "riscv_defs.v"

module riscv_regfile
(
    input  wire                         clk_i,
    input  wire                         rst_i,

    input  wire [`RISCV_REG_ADDR_W-1:0] rs1_addr_i,
    output wire [`RISCV_XLEN-1:0]       rs1_data_o,

    input  wire [`RISCV_REG_ADDR_W-1:0] rs2_addr_i,
    output wire [`RISCV_XLEN-1:0]       rs2_data_o,

    input  wire [`RISCV_REG_ADDR_W-1:0] rd_addr_i,
    input  wire [`RISCV_XLEN-1:0]       rd_data_i,
    input  wire                         rd_wren_i
);

    localparam [`RISCV_REG_ADDR_W-1:0] REG_X0 = {`RISCV_REG_ADDR_W{1'b0}};

    reg [`RISCV_XLEN-1:0] regs [0:`RISCV_NUM_REGS-1];
    integer i;

    always @(posedge clk_i)
    begin
        if (rst_i)
        begin
            for (i = 0; i < `RISCV_NUM_REGS; i = i + 1)
                regs[i] <= {`RISCV_XLEN{1'b0}};
        end
        else if (rd_wren_i && (rd_addr_i != REG_X0))
            regs[rd_addr_i] <= rd_data_i;
    end

    // x0 = 0; write-to-read bypass for WB -> ID
    assign rs1_data_o = (rs1_addr_i == REG_X0)                    ? {`RISCV_XLEN{1'b0}} :
                        (rd_wren_i && (rd_addr_i == rs1_addr_i))  ? rd_data_i :
                                                                    regs[rs1_addr_i];

    assign rs2_data_o = (rs2_addr_i == REG_X0)                    ? {`RISCV_XLEN{1'b0}} :
                        (rd_wren_i && (rd_addr_i == rs2_addr_i))  ? rd_data_i :
                                                                    regs[rs2_addr_i];

endmodule
