`default_nettype none
module dual_core_soc #(
    parameter integer CACHE_SIZE=1024,
    parameter integer LINE_SIZE=32,
    parameter integer MEMORY_ADDRESS_WIDTH=16
)(
    input logic clk,input logic rst_n,
    output logic[63:0] core0_cycles,core0_retired,core1_cycles,core1_retired,
    output logic[63:0] bus_rd_count,bus_rdx_count,bus_upgr_count,
    output logic[63:0] l1_hits,l1_misses,writebacks,invalidations,
    output logic[63:0] mesi_m_cycles,mesi_e_cycles,mesi_s_cycles,mesi_i_cycles,
    output logic core0_illegal,core1_illegal
);
    logic c0ir,c0iready,c0dr,c0dw,c0dready,c1ir,c1iready,c1dr,c1dw,c1dready;
    logic[31:0]c0ia,c0ird,c0da,c0dwd,c0drd,c1ia,c1ird,c1da,c1dwd,c1drd;logic[3:0]c0be,c1be;
    logic[63:0]unused00,unused01,unused02,unused03,unused10,unused11,unused12,unused13;
    logic rv0,rv1;logic[31:0]rp0,ri0,rp1,ri1;
    rv32_core core0(.clk,.rst_n,.imem_request(c0ir),.imem_address(c0ia),.imem_read_data(c0ird),.imem_ready(c0iready),
      .dmem_request(c0dr),.dmem_write(c0dw),.dmem_address(c0da),.dmem_write_data(c0dwd),.dmem_byte_enable(c0be),.dmem_read_data(c0drd),.dmem_ready(c0dready),
      .cycle_count(core0_cycles),.instruction_count(core0_retired),.stall_count(unused00),.branch_count(unused01),.branch_taken_count(unused02),
      .retired_valid(rv0),.retired_pc(rp0),.retired_instruction(ri0),.illegal_instruction(core0_illegal));
    rv32_core core1(.clk,.rst_n,.imem_request(c1ir),.imem_address(c1ia),.imem_read_data(c1ird),.imem_ready(c1iready),
      .dmem_request(c1dr),.dmem_write(c1dw),.dmem_address(c1da),.dmem_write_data(c1dwd),.dmem_byte_enable(c1be),.dmem_read_data(c1drd),.dmem_ready(c1dready),
      .cycle_count(core1_cycles),.instruction_count(core1_retired),.stall_count(unused10),.branch_count(unused11),.branch_taken_count(unused12),
      .retired_valid(rv1),.retired_pc(rp1),.retired_instruction(ri1),.illegal_instruction(core1_illegal));

    logic ireq0,ireq1,imr0,imw0,imready0,imr1,imw1,imready1;logic[31:0]ima0,ima1;
    logic[LINE_SIZE*8-1:0]imline0,imline1,imzero='0;logic[63:0]ih0,im0,ih1,im1;
    icache #(.CACHE_SIZE(CACHE_SIZE),.LINE_SIZE(LINE_SIZE)) icache0(.clk,.rst_n,.cpu_request(c0ir),.cpu_address(c0ia),.cpu_read_data(c0ird),.cpu_ready(c0iready),
      .memory_request(ireq0),.memory_address(ima0),.memory_read_line(imline0),.memory_ready(imready0),.hit_count(ih0),.miss_count(im0));
    icache #(.CACHE_SIZE(CACHE_SIZE),.LINE_SIZE(LINE_SIZE)) icache1(.clk,.rst_n,.cpu_request(c1ir),.cpu_address(c1ia),.cpu_read_data(c1ird),.cpu_ready(c1iready),
      .memory_request(ireq1),.memory_address(ima1),.memory_read_line(imline1),.memory_ready(imready1),.hit_count(ih1),.miss_count(im1));
    simple_memory #(.ADDRESS_WIDTH(MEMORY_ADDRESS_WIDTH),.LINE_BYTES(LINE_SIZE)) instruction_memory0(.clk,.read_enable(ireq0),.write_enable(1'b0),.address(ima0),.write_line(imzero),.read_line(imline0),.ready(imready0));
    simple_memory #(.ADDRESS_WIDTH(MEMORY_ADDRESS_WIDTH),.LINE_BYTES(LINE_SIZE)) instruction_memory1(.clk,.read_enable(ireq1),.write_enable(1'b0),.address(ima1),.write_line(imzero),.read_line(imline1),.ready(imready1));

    logic br0,bg0,bd0,bs0,br1,bg1,bd1,bs1;logic[1:0]bc0,bc1;logic[31:0]ba0,ba1;
    logic[LINE_SIZE*8-1:0]bwl0,bwl1,brl0,brl1;logic sv0,sv1,sh0,sh1,ss0,ss1;logic[1:0]sc0,sc1;logic[31:0]sa0,sa1;logic[LINE_SIZE*8-1:0]sl0,sl1;
    logic mr,mw,mready;logic[31:0]ma;logic[LINE_SIZE*8-1:0]mwl,mrl;logic[63:0]dh0,dm0,dwb0,dinv0,dh1,dm1,dwb1,dinv1;
    logic[63:0]mm0,me0,ms0,mi0c,mm1,me1,ms1,mi1c;
    dcache #(.CACHE_SIZE(CACHE_SIZE),.LINE_SIZE(LINE_SIZE)) dcache0(.clk,.rst_n,.cpu_request(c0dr),.cpu_write(c0dw),.cpu_address(c0da),.cpu_write_data(c0dwd),.cpu_byte_enable(c0be),.cpu_read_data(c0drd),.cpu_ready(c0dready),
      .bus_request(br0),.bus_command(bc0),.bus_address(ba0),.bus_write_line(bwl0),.bus_grant(bg0),.bus_ready(bd0),.bus_shared(bs0),.bus_read_line(brl0),
      .snoop_valid(sv0),.snoop_command(sc0),.snoop_address(sa0),.snoop_hit(sh0),.snoop_supply(ss0),.snoop_line(sl0),.hit_count(dh0),.miss_count(dm0),.writeback_count(dwb0),.invalidation_count(dinv0),.mesi_m_cycles(mm0),.mesi_e_cycles(me0),.mesi_s_cycles(ms0),.mesi_i_cycles(mi0c));
    dcache #(.CACHE_SIZE(CACHE_SIZE),.LINE_SIZE(LINE_SIZE)) dcache1(.clk,.rst_n,.cpu_request(c1dr),.cpu_write(c1dw),.cpu_address(c1da),.cpu_write_data(c1dwd),.cpu_byte_enable(c1be),.cpu_read_data(c1drd),.cpu_ready(c1dready),
      .bus_request(br1),.bus_command(bc1),.bus_address(ba1),.bus_write_line(bwl1),.bus_grant(bg1),.bus_ready(bd1),.bus_shared(bs1),.bus_read_line(brl1),
      .snoop_valid(sv1),.snoop_command(sc1),.snoop_address(sa1),.snoop_hit(sh1),.snoop_supply(ss1),.snoop_line(sl1),.hit_count(dh1),.miss_count(dm1),.writeback_count(dwb1),.invalidation_count(dinv1),.mesi_m_cycles(mm1),.mesi_e_cycles(me1),.mesi_s_cycles(ms1),.mesi_i_cycles(mi1c));
    coherence_bus #(.LINE_SIZE(LINE_SIZE)) coherence(.clk,.rst_n,
      .request0(br0),.command0(bc0),.address0(ba0),.write_line0(bwl0),.grant0(bg0),.ready0(bd0),.shared0(bs0),.read_line0(brl0),
      .request1(br1),.command1(bc1),.address1(ba1),.write_line1(bwl1),.grant1(bg1),.ready1(bd1),.shared1(bs1),.read_line1(brl1),
      .snoop_valid0(sv0),.snoop_command0(sc0),.snoop_address0(sa0),.snoop_hit0(sh0),.snoop_supply0(ss0),.snoop_line0(sl0),
      .snoop_valid1(sv1),.snoop_command1(sc1),.snoop_address1(sa1),.snoop_hit1(sh1),.snoop_supply1(ss1),.snoop_line1(sl1),
      .memory_read(mr),.memory_write(mw),.memory_address(ma),.memory_write_line(mwl),.memory_read_line(mrl),.memory_ready(mready),
      .bus_rd_count,.bus_rdx_count,.bus_upgr_count);
    simple_memory #(.ADDRESS_WIDTH(MEMORY_ADDRESS_WIDTH),.LINE_BYTES(LINE_SIZE)) data_memory(.clk,.read_enable(mr),.write_enable(mw),.address(ma),.write_line(mwl),.read_line(mrl),.ready(mready));
    assign l1_hits=dh0+dh1;assign l1_misses=dm0+dm1;assign writebacks=dwb0+dwb1;assign invalidations=dinv0+dinv1;
    assign mesi_m_cycles=mm0+mm1;assign mesi_e_cycles=me0+me1;assign mesi_s_cycles=ms0+ms1;assign mesi_i_cycles=mi0c+mi1c;
endmodule
`default_nettype wire
