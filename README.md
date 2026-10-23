# 4-bit Array Multiplier: RTL to GDSII (SKY130)

A 4-bit × 4-bit unsigned array multiplier (16 AND gates, 12 full adders, 16 flip-flops),
verified in simulation and taken through synthesis, static timing analysis and
place and route on the SkyWater SKY130 process.

## Team

| Name | Roll number |
|---|---|
| Mrityunjay Badoni | 2026203019 |
| Shreekara Aithala | 2026203001 |

Hand-worked example uses Mrityunjay Badoni's roll number (last digit 9): A = 9 + 5 = 14, B = 7, P = 98.

## Environment

- Host: Windows 11 with WSL 2 and Docker Desktop
- Container: IIC-OSIC-TOOLS (`hpretl/iic-osic-tools:latest`)
- Tools: Icarus Verilog 14.0 (devel), Yosys 0.69, OpenSTA 3.1.0, OpenROAD 26Q3-2443-g50432012f,
  LibreLane 3.1.0.dev3, KLayout 0.30.12
- PDK: sky130A, standard cell library sky130_fd_sc_hd

All commands are listed below in the order they were run.

---

## 1. Environment setup

### 1.1 Host checks (Windows PowerShell)

```
wsl --version
wsl --status
docker run hello-world
```

### 1.2 Start the container (Windows PowerShell)

```
mkdir "$env:USERPROFILE\eda\designs"
docker run -d --user 1000:1000 --security-opt seccomp=unconfined -p 80:80 -p 5901:5901 -v "$env:USERPROFILE\eda\designs:/foss/designs" --name iic-osic-tools_xvnc docker.io/hpretl/iic-osic-tools:latest
docker exec -it iic-osic-tools_xvnc bash -l
```

The `start_vnc.bat` script from the IIC-OSIC-TOOLS repository was blocked by Windows
Smart App Control, so the `docker run` command it contains was run directly.
The browser desktop (for GTKWave and KLayout) is at http://localhost.

### 1.3 Tool and PDK checks (inside the container)

```
iverilog -V | head -1
yosys -V
sta -version
echo $PDK_ROOT $PDK
```

The default PDK was `ihp-sg13g2`, so sky130A was selected and made permanent:

```
sak-pdk sky130A
echo $PDK_ROOT $PDK
cat > /foss/designs/.designinit << 'EOF'
export PDK=sky130A
export PDKPATH=$PDK_ROOT/$PDK
export STD_CELL_LIBRARY=sky130_fd_sc_hd
EOF
cat /foss/designs/.designinit
```

Library and shared-folder checks:

```
ls $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/ | grep tt_025C_1v80
cd /foss/designs && touch hello.txt && ls -a
```

### 1.4 Restart test

Windows PowerShell:

```
docker stop iic-osic-tools_xvnc
docker start iic-osic-tools_xvnc
docker exec -it iic-osic-tools_xvnc bash -l
```

Inside the container:

```
echo $PDK_ROOT $PDK
which iverilog vvp gtkwave yosys sta openroad librelane klayout magic netgen
cat > /tmp/hello.v << 'EOF'
module hello; initial $display("iverilog works!"); endmodule
EOF
iverilog -o /tmp/hello /tmp/hello.v && vvp /tmp/hello
yosys -V
sta -version
openroad -version
librelane --version
klayout -v
ls $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/ | grep tt_025C_1v80
ls $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog/
ls -a /foss/designs
```

---

## 2. Repository structure

```
cd /foss/designs
mkdir -p mult4/rtl mult4/tb mult4/synth mult4/sta mult4/pnr mult4/report
cd mult4
```

---

## 3. Part A: RTL design and verification

All commands from here on are run from the repository root, `/foss/designs/mult4`.

### 3.1 Full adder

Compile check:

```
iverilog -g2012 -o /tmp/fa rtl/full_adder.v
```

Unit test of the full adder on all 8 input combinations, with a practice
testbench kept outside the repository (`/foss/designs/practice/tb_fa.v`):

```
iverilog -g2012 -o /tmp/tb_fa ../practice/tb_fa.v rtl/full_adder.v
vvp /tmp/tb_fa
```

Result: `PASS: all 8 cases correct`

### 3.2 Multiplier

Compile check:

```
iverilog -g2012 -o /tmp/m rtl/full_adder.v rtl/mult_array.v
```

### 3.3 Exhaustive testbench

```
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
```

Result: `PASS: 256 vectors checked, 0 errors`

### 3.4 Error test

`sum` in `rtl/full_adder.v` temporarily changed to `assign sum = a ^ b;`, then:

```
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
```

Result: `FAIL: 256 vectors checked, 95 errors`

`sum` restored to `assign sum = a ^ b ^ cin;` and re-verified:

```
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
```

Result: `PASS: 256 vectors checked, 0 errors`

### 3.5 Waveform

In a terminal on the browser desktop:

```
cd /foss/designs/mult4
gtkwave mult.vcd &
```

Example A = 14, B = 7: inputs captured at the 4645 ns clock edge,
product p = 98 captured at the 4655 ns clock edge (latency 2 clock cycles = 20 ns).

---

## Part B — Synthesis

Run from the repository root:

```bash
cd /foss/designs/mult4
yosys -c synth/synth.tcl
```

Outputs: `synth/mult_array_netlist.v`, `synth/mult_array_stat.rpt`

Gate-level simulation of the synthesized netlist:

```bash
CELLS=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog
iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=#1 -o gls \
  tb/tb_mult.v $CELLS/primitives.v $CELLS/sky130_fd_sc_hd.v synth/mult_array_netlist.v
vvp gls
```

Result: `PASS: 256 vectors checked, 0 errors`

## 5. Part C: Static timing analysis

(to be added)

## 6. Part D: Physical design

(to be added)
