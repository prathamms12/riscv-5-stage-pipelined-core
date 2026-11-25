//-----------------------------------------------------------------------------
// File    : riscv_exec.v
// Author  : Pratham
// Project : 5-Stage RISC-V (RV32IM) core
// Desc    : EX stage: operand muxes, ALU, PC+4, branch/jump resolution
//-----------------------------------------------------------------------------
`include "riscv_defs.v"

module riscv_exec
(
    input  wire [`RISCV_XLEN-1:0]   pc_i,
    input  wire [`RISCV_XLEN-1:0]   rs1_data_i,
    input  wire [`RISCV_XLEN-1:0]   rs2_data_i,
    input  wire [`RISCV_XLEN-1:0]   imm_i,

    // Control from decoder
    input  wire [`ALU_OP_W-1:0]     alu_op_i,
    input  wire [`ALU_SRC_A_W-1:0]  alu_src_a_sel_i,
    input  wire                     alu_src_b_imm_i,
    input  wire [2:0]               funct3_i,
    input  wire                     branch_i,
    input  wire                     jump_i,
    input  wire                     jalr_i,

    // Results
    output wire [`RISCV_XLEN-1:0]   alu_result_o,
    output wire [`RISCV_XLEN-1:0]   pc_plus4_o,

    // Pipeline redirect
    output wire                     redirect_o,
    output wire [`RISCV_XLEN-1:0]   redirect_pc_o
);

    // ALU operand A: rs1 / PC / zero
    reg [`RISCV_XLEN-1:0] operand_a;
    always @(*)
    begin
        case (alu_src_a_sel_i)
            `ALU_SRC_A_PC   : operand_a = pc_i;
            `ALU_SRC_A_ZERO : operand_a = {`RISCV_XLEN{1'b0}};
            default         : operand_a = rs1_data_i;
        endcase
    end

    // ALU operand B: rs2 / immediate
    wire [`RISCV_XLEN-1:0] operand_b = alu_src_b_imm_i ? imm_i : rs2_data_i;

    riscv_alu u_alu
    (
        .alu_op_i    (alu_op_i),
        .operand_a_i (operand_a),
        .operand_b_i (operand_b),
        .result_o    (alu_result_o)
    );

    // Dedicated adders: link value and branch/JAL target
    assign pc_plus4_o = pc_i + 32'd4;
    wire [`RISCV_XLEN-1:0] pc_plus_imm = pc_i + imm_i;

    // Branch condition (ALU already did SUB / SLT / SLTU)
    reg branch_taken;
    always @(*)
    begin
        case (funct3_i)
            `F3_BEQ  : branch_taken =  (alu_result_o == {`RISCV_XLEN{1'b0}});
            `F3_BNE  : branch_taken =  (alu_result_o != {`RISCV_XLEN{1'b0}});
            `F3_BLT  : branch_taken =  alu_result_o[0];
            `F3_BGE  : branch_taken = ~alu_result_o[0];
            `F3_BLTU : branch_taken =  alu_result_o[0];
            `F3_BGEU : branch_taken = ~alu_result_o[0];
            default  : branch_taken = 1'b0;
        endcase
    end

    wire branch_taken_qual = branch_i & branch_taken;

    // JALR target = (rs1 + imm) with bit 0 cleared
    wire [`RISCV_XLEN-1:0] jalr_target = {alu_result_o[`RISCV_XLEN-1:1], 1'b0};

    assign redirect_o    = branch_taken_qual | jump_i;
    assign redirect_pc_o = jalr_i ? jalr_target : pc_plus_imm;

endmodule
