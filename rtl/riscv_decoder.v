//-----------------------------------------------------------------------------
// File    : riscv_decoder.v
// Author  : Pratham
// Project : 5-Stage RISC-V (RV32IM) core
// Desc    : Combinational RV32IM instruction decode table
//-----------------------------------------------------------------------------
`include "riscv_defs.v"

module riscv_decoder
(
    input  wire [31:0]                   instr_i,

    output wire [`RISCV_REG_ADDR_W-1:0]  rd_addr_o,
    output wire [`RISCV_REG_ADDR_W-1:0]  rs1_addr_o,
    output wire [`RISCV_REG_ADDR_W-1:0]  rs2_addr_o,

    output reg  [`IMM_TYPE_W-1:0]        imm_type_o,

    output reg  [`ALU_OP_W-1:0]          alu_op_o,
    output reg  [`ALU_SRC_A_W-1:0]       alu_src_a_sel_o,
    output reg                           alu_src_b_imm_o,

    output reg                           mem_read_o,
    output reg                           mem_write_o,

    output reg                           branch_o,
    output reg                           jump_o,
    output reg                           jalr_o,

    output reg                           reg_write_o,
    output reg  [`WB_SEL_W-1:0]          wb_sel_o,

    output reg                           muldiv_en_o,
    output reg  [`MULDIV_OP_W-1:0]       muldiv_op_o,

    output reg                           csr_en_o,
    output reg                           system_o,
    output reg                           illegal_o
);

    wire [6:0] opcode = instr_i[`INSTR_OPCODE_R];
    wire [2:0] funct3 = instr_i[`INSTR_FUNCT3_R];
    wire [6:0] funct7 = instr_i[`INSTR_FUNCT7_R];

    assign rd_addr_o  = instr_i[`INSTR_RD_R];
    assign rs1_addr_o = instr_i[`INSTR_RS1_R];
    assign rs2_addr_o = instr_i[`INSTR_RS2_R];

    // Single always block: defaults first, then the opcode case
    always @(*)
    begin
        imm_type_o      = `IMM_NONE;
        alu_op_o        = `ALU_ADD;
        alu_src_a_sel_o = `ALU_SRC_A_RS1;
        alu_src_b_imm_o = 1'b0;
        mem_read_o      = 1'b0;
        mem_write_o     = 1'b0;
        branch_o        = 1'b0;
        jump_o          = 1'b0;
        jalr_o          = 1'b0;
        reg_write_o     = 1'b0;
        wb_sel_o        = `WB_SEL_ALU;
        muldiv_en_o     = 1'b0;
        muldiv_op_o     = {`MULDIV_OP_W{1'b0}};
        csr_en_o        = 1'b0;
        system_o        = 1'b0;
        illegal_o       = 1'b0;

        case (opcode)

            `OPCODE_OP_IMM:
            begin
                imm_type_o      = `IMM_I;
                alu_src_b_imm_o = 1'b1;
                reg_write_o     = 1'b1;
                case (funct3)
                    `F3_ADD_SUB: alu_op_o = `ALU_ADD;
                    `F3_SLT    : alu_op_o = `ALU_SLT;
                    `F3_SLTU   : alu_op_o = `ALU_SLTU;
                    `F3_XOR    : alu_op_o = `ALU_XOR;
                    `F3_OR     : alu_op_o = `ALU_OR;
                    `F3_AND    : alu_op_o = `ALU_AND;
                    `F3_SLL    : alu_op_o = `ALU_SLL;
                    `F3_SRL_SRA: alu_op_o = (funct7 == `F7_SUB_SRA) ? `ALU_SRA : `ALU_SRL;
                    default    : illegal_o = 1'b1;
                endcase
            end

            `OPCODE_OP:
            begin
                reg_write_o = 1'b1;
                if (funct7 == `F7_MULDIV)
                begin
                    muldiv_en_o = 1'b1;
                    wb_sel_o    = `WB_SEL_MULDIV;
                    case (funct3)
                        `F3_MUL   : muldiv_op_o = `MULDIV_MUL;
                        `F3_MULH  : muldiv_op_o = `MULDIV_MULH;
                        `F3_MULHSU: muldiv_op_o = `MULDIV_MULHSU;
                        `F3_MULHU : muldiv_op_o = `MULDIV_MULHU;
                        `F3_DIV   : muldiv_op_o = `MULDIV_DIV;
                        `F3_DIVU  : muldiv_op_o = `MULDIV_DIVU;
                        `F3_REM   : muldiv_op_o = `MULDIV_REM;
                        `F3_REMU  : muldiv_op_o = `MULDIV_REMU;
                        default   : illegal_o   = 1'b1;
                    endcase
                end
                else
                begin
                    case (funct3)
                        `F3_ADD_SUB: alu_op_o = (funct7 == `F7_SUB_SRA) ? `ALU_SUB : `ALU_ADD;
                        `F3_SLT    : alu_op_o = `ALU_SLT;
                        `F3_SLTU   : alu_op_o = `ALU_SLTU;
                        `F3_XOR    : alu_op_o = `ALU_XOR;
                        `F3_OR     : alu_op_o = `ALU_OR;
                        `F3_AND    : alu_op_o = `ALU_AND;
                        `F3_SLL    : alu_op_o = `ALU_SLL;
                        `F3_SRL_SRA: alu_op_o = (funct7 == `F7_SUB_SRA) ? `ALU_SRA : `ALU_SRL;
                        default    : illegal_o = 1'b1;
                    endcase
                end
            end

            `OPCODE_LOAD:
            begin
                imm_type_o      = `IMM_I;
                alu_src_b_imm_o = 1'b1;
                alu_op_o        = `ALU_ADD;
                mem_read_o      = 1'b1;
                reg_write_o     = 1'b1;
                wb_sel_o        = `WB_SEL_MEM;
                case (funct3)
                    `F3_LB, `F3_LH, `F3_LW, `F3_LBU, `F3_LHU: ;
                    default: illegal_o = 1'b1;
                endcase
            end

            `OPCODE_STORE:
            begin
                imm_type_o      = `IMM_S;
                alu_src_b_imm_o = 1'b1;
                alu_op_o        = `ALU_ADD;
                mem_write_o     = 1'b1;
                case (funct3)
                    `F3_SB, `F3_SH, `F3_SW: ;
                    default: illegal_o = 1'b1;
                endcase
            end

            `OPCODE_BRANCH:
            begin
                imm_type_o = `IMM_B;
                branch_o   = 1'b1;
                case (funct3)
                    `F3_BEQ , `F3_BNE : alu_op_o = `ALU_SUB;
                    `F3_BLT , `F3_BGE : alu_op_o = `ALU_SLT;
                    `F3_BLTU, `F3_BGEU: alu_op_o = `ALU_SLTU;
                    default           : illegal_o = 1'b1;
                endcase
            end

            `OPCODE_JAL:
            begin
                imm_type_o      = `IMM_J;
                jump_o          = 1'b1;
                alu_src_a_sel_o = `ALU_SRC_A_PC;
                alu_src_b_imm_o = 1'b1;
                reg_write_o     = 1'b1;
                wb_sel_o        = `WB_SEL_PC4;
            end

            `OPCODE_JALR:
            begin
                imm_type_o      = `IMM_I;
                jump_o          = 1'b1;
                jalr_o          = 1'b1;
                alu_src_b_imm_o = 1'b1;
                reg_write_o     = 1'b1;
                wb_sel_o        = `WB_SEL_PC4;
                if (funct3 != 3'b000)
                    illegal_o = 1'b1;
            end

            // LUI: rd = 0 + imm
            `OPCODE_LUI:
            begin
                imm_type_o      = `IMM_U;
                alu_src_a_sel_o = `ALU_SRC_A_ZERO;
                alu_src_b_imm_o = 1'b1;
                reg_write_o     = 1'b1;
            end

            // AUIPC: rd = PC + imm
            `OPCODE_AUIPC:
            begin
                imm_type_o      = `IMM_U;
                alu_src_a_sel_o = `ALU_SRC_A_PC;
                alu_src_b_imm_o = 1'b1;
                reg_write_o     = 1'b1;
            end

            `OPCODE_SYSTEM:
            begin
                system_o = 1'b1;
                if (funct3 != `F3_PRIV)
                begin
                    csr_en_o    = 1'b1;
                    reg_write_o = 1'b1;
                    wb_sel_o    = `WB_SEL_CSR;
                    case (funct3)
                        `F3_CSRRW, `F3_CSRRS, `F3_CSRRC,
                        `F3_CSRRWI, `F3_CSRRSI, `F3_CSRRCI: ;
                        default: illegal_o = 1'b1;
                    endcase
                end
            end

            `OPCODE_MISC_MEM: ;   // FENCE: no-op

            default: illegal_o = 1'b1;
        endcase
    end

endmodule
