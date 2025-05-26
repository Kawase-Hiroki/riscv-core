module m_top();
    reg r_clk = 0;
    initial #150 forever #50 r_clk = ~r_clk;
    m_proc m(r_clk);

    initial #99 forever #100
        $display("%4d %h %h %d %d %d", $time, m.r_pc, m.w_imm, m.w_r1, m.w_s2, m.w_rt);
    initial #1400 $finish;
endmodule

module m_proc(w_clk);
    input wire w_clk;
    wire [31:0] w_npc;
    wire [31:0] w_ir;
    wire [31:0] w_imm;
    wire [31:0] w_r1;
    wire [31:0] w_r2;
    wire [31:0] w_s2;
    wire [31:0] w_rt;
    wire [31:0] w_alu;
    wire [31:0] w_ldd;
    wire [31:0] w_tcp;
    wire [31:0] w_pcin;
    wire w_r, w_i, w_s, w_b, w_u, w_j, w_ld;
    wire w_tkn;
    reg [31:0] r_pc = 0;

    //IF
    assign w_pcin = (w_b & w_tkn) ? w_tcp : w_npc;
    assign w_npc = r_pc + 4;
    m_am_item m1 (r_pc, w_ir);

    //ID
    m_gen_imm m2 (w_ir, w_imm, w_r, w_i, w_s, w_b, w_u, w_j, w_ld);
    m_RF m3 (w_clk, w_ir[19:15], w_ir[24:20], w_r1, w_r2, w_ir[11:7], !w_s & !w_b, w_rt);
    assign w_s2 = (!w_r & !w_b) ? w_imm : w_r2;
    assign w_tcp = r_pc + w_imm;

    //EX
    m_alu m5 (w_r1, w_s2, w_alu, w_tkn);

    //MA
    m_am_dmem m4 (w_clk, w_alu, w_s, w_r2, w_ldd);

    //WB
    assign w_rt = (w_ld) ? w_ldd : w_alu;
    
    always @(posedge w_clk) r_pc <= w_pcin;

    wire w_halt = (!w_s & !w_b & w_ir[11:7] == 5'd30);
endmodule

module m_RF (w_clk, w_ra1, w_ra2, w_rd1, w_rd2, w_wa, w_we, w_wd);
    input wire w_clk, w_we;
    input wire [4:0] w_ra1, w_ra2, w_wa;
    output wire [31:0] w_rd1, w_rd2;
    input wire [31:0] w_wd;
    reg [31:0] mem [0:31];
    
    assign w_rd1 = (w_ra1 == 0) ? 0 : mem[w_ra1];
    assign w_rd2 = (w_ra2 == 0) ? 0 : mem[w_ra2];
    always @(posedge w_clk) if (w_we) mem[w_wa] <= w_wd;
    always @(posedge w_clk) if (w_we & w_wa == 5'd30) $finish;
    integer i; initial for(i = 0 ;i < 32; i = i + 1) mem[i] = 0;
endmodule

module m_gen_imm(w_ir, w_imm, w_r, w_i, w_s, w_b, w_u, w_j, w_ld);
    input wire [31:0] w_ir;
    output wire [31:0] w_imm;
    output wire w_r, w_i, w_s, w_b, w_u, w_j, w_ld;
    assign w_j = (w_ir[6:2] == 5'b11011);
    assign w_b = (w_ir[6:2] == 5'b11000);
    assign w_s = (w_ir[6:2] == 5'b01000);
    assign w_r = (w_ir[6:2] == 5'b01100);
    assign w_u = (w_ir[6:2] == 5'b01101 || w_ir[6:2] == 5'b00101);
    assign w_i = ~(w_j | w_b | w_s | w_r | w_u);
    assign w_ld = (w_ir[6:2] == 5'b00000);
    assign w_imm = (w_i) ? {{20{w_ir[31]}}, w_ir[31:20]} :
                   (w_s) ? {{20{w_ir[31]}}, w_ir[31:25], w_ir[11:7]} :
                   (w_b) ? {{19{w_ir[31]}}, w_ir[7], w_ir[30:25], w_ir[11:8], 1'b0} :
                   (w_j) ? {{12{w_ir[31]}}, w_ir[19:12], w_ir[20], w_ir[30:21], 1'b0} :
                   (w_u) ? {w_ir[31:12], 12'd0} : 32'd0;
endmodule

module m_am_item(w_pc, w_insn);
    input wire [31:0] w_pc;
    output wire [31:0] w_insn;
    reg [31:0] cm_ram [0:4095];
    assign w_insn = cm_ram[w_pc[7:2]];
    `include "program.txt"
endmodule

module m_am_dmem(w_clk, w_adr, w_we, w_wd, w_rd);
    input wire w_clk, w_we;
    input wire [31:0] w_adr, w_wd;
    output wire [31:0] w_rd;
    reg [31:0] cm_ram [0:4095];
    assign w_rd = cm_ram[w_adr[7:2]];
    always @(posedge w_clk) if (w_we) cm_ram[w_adr[7:2]] <= w_wd;
    `include "program.txt"
endmodule

module m_alu(w_in1, w_in2, w_op, w_out, w_tkn);
    input wire [31:0] w_in1, w_in2;
    input wire w_op[2:1];
    output wire [31:0] w_out;
    output wire w_tkn;
    assign w_out = w_in1 + w_in2;
    assign w_tkn = w_in1 != w_in2;
endmodule