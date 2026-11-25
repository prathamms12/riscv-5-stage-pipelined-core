//-----------------------------------------------------------------------------
// File    : riscv_lsu.v
// Author  : Pratham
// Project : 5-Stage RISC-V (RV32IM) core
// Desc    : Load/store unit: byte-lane strobes, store shift, load extract/extend, misalign check
//-----------------------------------------------------------------------------
`include "riscv_defs.v"

module riscv_lsu
(
    input  wire [`RISCV_XLEN-1:0] addr_i,
    input  wire [`RISCV_XLEN-1:0] store_data_i,
    input  wire [2:0]             funct3_i,
    input  wire                   mem_read_i,
    input  wire                   mem_write_i,

    // Memory side
    output wire [`RISCV_XLEN-1:0] mem_addr_o,
    output wire [`RISCV_XLEN-1:0] mem_wdata_o,
    output wire [3:0]             mem_wstrb_o,
    output wire                   mem_write_o,
    output wire                   mem_read_o,
    input  wire [`RISCV_XLEN-1:0] mem_rdata_i,

    // To WB
    output wire [`RISCV_XLEN-1:0] load_data_o,
    output wire                   misaligned_o
);

    wire [1:0] byte_offset = addr_i[1:0];

    // ---------------- Store path ----------------
    reg [3:0] wstrb_r;
    reg       misaligned_store;

    always @(*)
    begin
        wstrb_r          = 4'b0000;
        misaligned_store = 1'b0;
        case (funct3_i)
            `F3_SB: wstrb_r = 4'b0001 << byte_offset;
            `F3_SH:
            begin
                wstrb_r          = 4'b0011 << byte_offset;
                misaligned_store = byte_offset[0];
            end
            `F3_SW:
            begin
                wstrb_r          = 4'b1111;
                misaligned_store = (byte_offset != 2'b00);
            end
            default: ;
        endcase
    end

    wire [`RISCV_XLEN-1:0] wdata = store_data_i << (byte_offset * 8);

    // ---------------- Load path ----------------
    reg [`RISCV_XLEN-1:0] load_data_r;
    reg                   misaligned_load;

    always @(*)
    begin
        load_data_r     = mem_rdata_i;
        misaligned_load = 1'b0;
        case (funct3_i)
            `F3_LB:
                case (byte_offset)
                    2'b00: load_data_r = {{24{mem_rdata_i[7]}},  mem_rdata_i[7:0]};
                    2'b01: load_data_r = {{24{mem_rdata_i[15]}}, mem_rdata_i[15:8]};
                    2'b10: load_data_r = {{24{mem_rdata_i[23]}}, mem_rdata_i[23:16]};
                    2'b11: load_data_r = {{24{mem_rdata_i[31]}}, mem_rdata_i[31:24]};
                endcase
            `F3_LBU:
                case (byte_offset)
                    2'b00: load_data_r = {24'b0, mem_rdata_i[7:0]};
                    2'b01: load_data_r = {24'b0, mem_rdata_i[15:8]};
                    2'b10: load_data_r = {24'b0, mem_rdata_i[23:16]};
                    2'b11: load_data_r = {24'b0, mem_rdata_i[31:24]};
                endcase
            `F3_LH:
            begin
                misaligned_load = byte_offset[0];
                load_data_r     = byte_offset[1] ? {{16{mem_rdata_i[31]}}, mem_rdata_i[31:16]}
                                                 : {{16{mem_rdata_i[15]}}, mem_rdata_i[15:0]};
            end
            `F3_LHU:
            begin
                misaligned_load = byte_offset[0];
                load_data_r     = byte_offset[1] ? {16'b0, mem_rdata_i[31:16]}
                                                 : {16'b0, mem_rdata_i[15:0]};
            end
            `F3_LW:
            begin
                misaligned_load = (byte_offset != 2'b00);
                load_data_r     = mem_rdata_i;
            end
            default: ;
        endcase
    end

    assign misaligned_o = mem_write_i ? misaligned_store :
                          mem_read_i  ? misaligned_load  : 1'b0;

    assign mem_addr_o  = addr_i;
    assign mem_wdata_o = wdata;
    assign mem_wstrb_o = (mem_write_i && !misaligned_o) ? wstrb_r : 4'b0000;
    assign mem_write_o = mem_write_i && !misaligned_o;
    assign mem_read_o  = mem_read_i  && !misaligned_o;
    assign load_data_o = load_data_r;

endmodule
