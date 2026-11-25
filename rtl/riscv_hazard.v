//-----------------------------------------------------------------------------
// File    : riscv_hazard.v
// Author  : Pratham
// Project : 5-Stage RISC-V (RV32IM) core
// Desc    : Load-use stall detection and EX-stage forwarding select
//-----------------------------------------------------------------------------
`include "riscv_defs.v"

module riscv_hazard
(
    // Instruction in ID
    input  wire [`RISCV_REG_ADDR_W-1:0] id_rs1_addr_i,
    input  wire [`RISCV_REG_ADDR_W-1:0] id_rs2_addr_i,

    // Instruction in EX (ID/EX latch)
    input  wire [`RISCV_REG_ADDR_W-1:0] idex_rs1_addr_i,
    input  wire [`RISCV_REG_ADDR_W-1:0] idex_rs2_addr_i,
    input  wire [`RISCV_REG_ADDR_W-1:0] idex_rd_addr_i,
    input  wire                         idex_reg_write_i,
    input  wire                         idex_mem_read_i,

    // Instruction in MEM (EX/MEM latch)
    input  wire [`RISCV_REG_ADDR_W-1:0] exmem_rd_addr_i,
    input  wire                         exmem_reg_write_i,

    // Instruction in WB
    input  wire [`RISCV_REG_ADDR_W-1:0] memwb_rd_addr_i,
    input  wire                         memwb_reg_write_i,

    output wire                         load_use_stall_o,
    output wire [1:0]                   forward_a_sel_o,
    output wire [1:0]                   forward_b_sel_o
);

    localparam [1:0] FWD_NONE  = 2'b00;
    localparam [1:0] FWD_EXMEM = 2'b01;
    localparam [1:0] FWD_MEMWB = 2'b10;

    localparam [`RISCV_REG_ADDR_W-1:0] REG_X0 = {`RISCV_REG_ADDR_W{1'b0}};

    // Load in EX, dependent instruction in ID -> stall one cycle
    assign load_use_stall_o = idex_mem_read_i && idex_reg_write_i &&
                              (idex_rd_addr_i != REG_X0) &&
                              ((idex_rd_addr_i == id_rs1_addr_i) ||
                               (idex_rd_addr_i == id_rs2_addr_i));

    // EX/MEM has priority over MEM/WB (more recent result)
    assign forward_a_sel_o =
        (exmem_reg_write_i && (exmem_rd_addr_i != REG_X0) &&
         (exmem_rd_addr_i == idex_rs1_addr_i)) ? FWD_EXMEM :
        (memwb_reg_write_i && (memwb_rd_addr_i != REG_X0) &&
         (memwb_rd_addr_i == idex_rs1_addr_i)) ? FWD_MEMWB :
        FWD_NONE;

    assign forward_b_sel_o =
        (exmem_reg_write_i && (exmem_rd_addr_i != REG_X0) &&
         (exmem_rd_addr_i == idex_rs2_addr_i)) ? FWD_EXMEM :
        (memwb_reg_write_i && (memwb_rd_addr_i != REG_X0) &&
         (memwb_rd_addr_i == idex_rs2_addr_i)) ? FWD_MEMWB :
        FWD_NONE;

endmodule
