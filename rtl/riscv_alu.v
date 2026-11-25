//-----------------------------------------------------------------------------
// File    : riscv_alu.v
// Author  : Pratham
// Project : 5-Stage RISC-V (RV32IM) core
// Desc    : Combinational ALU (add/sub, shifts, SLT/SLTU, logic)
//-----------------------------------------------------------------------------
`include "riscv_defs.v"

module riscv_alu
(
    input  wire [`ALU_OP_W-1:0]   alu_op_i,
    input  wire [`RISCV_XLEN-1:0] operand_a_i,
    input  wire [`RISCV_XLEN-1:0] operand_b_i,
    output reg  [`RISCV_XLEN-1:0] result_o
);

    always @(*)
    begin
        case (alu_op_i)
            `ALU_ADD : result_o = operand_a_i + operand_b_i;
            `ALU_SUB : result_o = operand_a_i - operand_b_i;
            `ALU_SLL : result_o = operand_a_i << operand_b_i[4:0];
            `ALU_SRL : result_o = operand_a_i >> operand_b_i[4:0];
            `ALU_SRA : result_o = $signed(operand_a_i) >>> operand_b_i[4:0];
            `ALU_SLT : result_o = ($signed(operand_a_i) < $signed(operand_b_i)) ?
                                  {{(`RISCV_XLEN-1){1'b0}}, 1'b1} : {`RISCV_XLEN{1'b0}};
            `ALU_SLTU: result_o = (operand_a_i < operand_b_i) ?
                                  {{(`RISCV_XLEN-1){1'b0}}, 1'b1} : {`RISCV_XLEN{1'b0}};
            `ALU_XOR : result_o = operand_a_i ^ operand_b_i;
            `ALU_OR  : result_o = operand_a_i | operand_b_i;
            `ALU_AND : result_o = operand_a_i & operand_b_i;
            default  : result_o = {`RISCV_XLEN{1'b0}};
        endcase
    end

endmodule
