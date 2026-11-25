# RISC-V 5-Stage Pipelined Core (RV32IM)

Verilog-2001 implementation of a 5-stage (IF / ID / EX / MEM / WB) RISC-V core
with a dual-port TCM, load-use stalling, EX-stage forwarding and branch/jump
redirect.

**Author:** Pratham

## Layout

| Path | Contents |
|------|----------|
| `rtl/` | Core, pipeline stages, hazard unit, TCM RAM, SoC top |
| `tb/tb_riscv.v` | Self-checking testbench (49 checks) |
| `docs/` | Core schematic |

## Run the simulation (Icarus Verilog)

```sh
iverilog -g2005 -I rtl -o sim.vvp rtl/*.v tb/tb_riscv.v
vvp sim.vvp
```

Expected last lines: `ALL TESTS PASSED  (49 checks)`.

## Modules

`riscv_core` instantiates `riscv_fetch`, `riscv_decode` (`riscv_decoder` +
`riscv_regfile` + immediate generator), `riscv_exec` (`riscv_alu`), `riscv_lsu`,
`riscv_writeback`, `riscv_hazard` and `riscv_pipe_ctrl`. `riscv_tcm_top` wraps
the core and `riscv_tcm_ram` with an AXI4 interface.
