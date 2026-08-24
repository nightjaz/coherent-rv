`timescale 1ns/1ps
`default_nettype none
module coherence_tb #(parameter integer CACHE_SIZE=1024,parameter integer RANDOM_OPS=1000,
    parameter logic [31:0] SEED=32'h1ace_beef);
    localparam integer LS=32;
    localparam integer NUM_SETS=CACHE_SIZE/LS;
    logic clk=0,rst_n=0; always #5 clk=~clk;
    logic req0,wr0,ready0;logic[31:0]addr0,wdata0,rdata0;logic[3:0]be0;
    logic req1,wr1,ready1;logic[31:0]addr1,wdata1,rdata1;logic[3:0]be1;
    logic br0,bg0,bd0,bs0,br1,bg1,bd1,bs1;logic[1:0]bc0,bc1;logic[31:0]ba0,ba1;
    logic[LS*8-1:0]bwl0,bwl1,brl0,brl1;
    logic sv0,sv1,sh0,sh1,ss0,ss1;logic[1:0]sc0,sc1;logic[31:0]sa0,sa1;logic[LS*8-1:0]sl0,sl1;
    logic mr,mw,mready;logic[31:0]ma;logic[LS*8-1:0]mwl,mrl;
    logic[63:0]h0,mi0,wb0,inv0,h1,mi1,wb1,inv1,busrd,busrdx,busupgr;
    integer k,j,litmus_k,spin_count; logic[31:0]reference[0:15]; logic[31:0]lfsr,value,flag_value,data_value;
    logic[63:0] before_rd,before_rdx,before_upgr,before_wb,before_inv,before_false_bus;
    logic[1:0]previous0[0:NUM_SETS-1],previous1[0:NUM_SETS-1];integer transitions[0:15];
    logic[63:0]elapsed_cycles;
    dcache #(.CACHE_SIZE(CACHE_SIZE),.LINE_SIZE(LS)) c0(
      .clk,.rst_n,.cpu_request(req0),.cpu_write(wr0),.cpu_address(addr0),.cpu_write_data(wdata0),.cpu_byte_enable(be0),.cpu_read_data(rdata0),.cpu_ready(ready0),
      .bus_request(br0),.bus_command(bc0),.bus_address(ba0),.bus_write_line(bwl0),.bus_grant(bg0),.bus_ready(bd0),.bus_shared(bs0),.bus_read_line(brl0),
      .snoop_valid(sv0),.snoop_command(sc0),.snoop_address(sa0),.snoop_hit(sh0),.snoop_supply(ss0),.snoop_line(sl0),
      .hit_count(h0),.miss_count(mi0),.writeback_count(wb0),.invalidation_count(inv0));
    dcache #(.CACHE_SIZE(CACHE_SIZE),.LINE_SIZE(LS)) c1(
      .clk,.rst_n,.cpu_request(req1),.cpu_write(wr1),.cpu_address(addr1),.cpu_write_data(wdata1),.cpu_byte_enable(be1),.cpu_read_data(rdata1),.cpu_ready(ready1),
      .bus_request(br1),.bus_command(bc1),.bus_address(ba1),.bus_write_line(bwl1),.bus_grant(bg1),.bus_ready(bd1),.bus_shared(bs1),.bus_read_line(brl1),
      .snoop_valid(sv1),.snoop_command(sc1),.snoop_address(sa1),.snoop_hit(sh1),.snoop_supply(ss1),.snoop_line(sl1),
      .hit_count(h1),.miss_count(mi1),.writeback_count(wb1),.invalidation_count(inv1));
    coherence_bus #(.LINE_SIZE(LS)) bus(
      .clk,.rst_n,.request0(br0),.command0(bc0),.address0(ba0),.write_line0(bwl0),.grant0(bg0),.ready0(bd0),.shared0(bs0),.read_line0(brl0),
      .request1(br1),.command1(bc1),.address1(ba1),.write_line1(bwl1),.grant1(bg1),.ready1(bd1),.shared1(bs1),.read_line1(brl1),
      .snoop_valid0(sv0),.snoop_command0(sc0),.snoop_address0(sa0),.snoop_hit0(sh0),.snoop_supply0(ss0),.snoop_line0(sl0),
      .snoop_valid1(sv1),.snoop_command1(sc1),.snoop_address1(sa1),.snoop_hit1(sh1),.snoop_supply1(ss1),.snoop_line1(sl1),
      .memory_read(mr),.memory_write(mw),.memory_address(ma),.memory_write_line(mwl),.memory_read_line(mrl),.memory_ready(mready),
      .bus_rd_count(busrd),.bus_rdx_count(busrdx),.bus_upgr_count(busupgr));
    simple_memory #(.ADDRESS_WIDTH(16),.LINE_BYTES(LS)) mem(.clk,.read_enable(mr),.write_enable(mw),.address(ma),.write_line(mwl),.read_line(mrl),.ready(mready));
    cache_assertions cache0_sva(.clk,.rst_n,.cpu_ready(ready0),.cpu_request(req0),.cpu_address(addr0),.bus_ready(bd0),.bus_grant(bg0),.bus_request(br0),.bus_address(ba0));
    cache_assertions cache1_sva(.clk,.rst_n,.cpu_ready(ready1),.cpu_request(req1),.cpu_address(addr1),.bus_ready(bd1),.bus_grant(bg1),.bus_request(br1),.bus_address(ba1));
    generate genvar gi;for(gi=0;gi<NUM_SETS;gi=gi+1)begin: assertion_set
      coherence_assertions ca(.clk,.rst_n,.grant0(bg0),.grant1(bg1),.state0(c0.states[gi]),.state1(c1.states[gi]),.tags_equal(c0.tags[gi]==c1.tags[gi]));
    end endgenerate

    task automatic write0(input[31:0]a,input[31:0]v);begin
      @(negedge clk);addr0=a;wdata0=v;be0=4'hf;wr0=1;req0=1;
      do @(posedge clk);while(!ready0);#1;@(negedge clk);req0=0;wr0=0;
    end endtask
    task automatic write1(input[31:0]a,input[31:0]v);begin
      @(negedge clk);addr1=a;wdata1=v;be1=4'hf;wr1=1;req1=1;
      do @(posedge clk);while(!ready1);#1;@(negedge clk);req1=0;wr1=0;
    end endtask
    task automatic read0(input[31:0]a,output[31:0]v);begin
      @(negedge clk);addr0=a;wr0=0;req0=1;
      do @(posedge clk);while(!ready0);#1;v=rdata0;@(negedge clk);req0=0;
    end endtask
    task automatic read1(input[31:0]a,output[31:0]v);begin
      @(negedge clk);addr1=a;wr1=0;req1=1;
      do @(posedge clk);while(!ready1);#1;v=rdata1;@(negedge clk);req1=0;
    end endtask

    always @(posedge clk) if(!rst_n)elapsed_cycles<=0;else begin
      elapsed_cycles<=elapsed_cycles+1;
      if(bg0&&bg1)$fatal(1,"dual bus grant");
      for(j=0;j<NUM_SETS;j=j+1) begin
        if(previous0[j]!=c0.states[j])transitions[{previous0[j],c0.states[j]}]<=transitions[{previous0[j],c0.states[j]}]+1;
        if(previous1[j]!=c1.states[j])transitions[{previous1[j],c1.states[j]}]<=transitions[{previous1[j],c1.states[j]}]+1;
        previous0[j]<=c0.states[j];previous1[j]<=c1.states[j];
        if(c0.states[j]==3 && c1.states[j]==3 && c0.tags[j]==c1.tags[j])$fatal(1,"M/M invariant set=%0d br=%b%b bg=%b%b sv=%b%b cmd=%0d/%0d",j,br1,br0,bg1,bg0,sv1,sv0,bc0,bc1);
        if(c0.tags[j]==c1.tags[j] && ((c0.states[j]==3&&c1.states[j]!=0)||(c1.states[j]==3&&c0.states[j]!=0)))$fatal(1,"M peer not I");
        if(c0.tags[j]==c1.tags[j] && ((c0.states[j]==2&&c1.states[j]!=0)||(c1.states[j]==2&&c0.states[j]!=0)))$fatal(1,"E peer not I");
      end
    end
    initial begin
      req0=0;wr0=0;addr0=0;wdata0=0;be0=15;req1=0;wr1=0;addr1=0;wdata1=0;be1=15;
      for(k=0;k<16;k=k+1)begin reference[k]=0;transitions[k]=0;end
      for(k=0;k<NUM_SETS;k=k+1)begin previous0[k]=0;previous1[k]=0;end
      repeat(3)@(posedge clk);rst_n<=1;
      read0(0,value);if(value!==0||c0.states[0]!==2)$fatal(1,"exclusive read failed state=%0d",c0.states[0]);
      before_rd=busrd;before_rdx=busrdx;before_upgr=busupgr;
      write0(0,3);reference[0]=3;
      if(c0.states[0]!==3||busrd!==before_rd||busrdx!==before_rdx||busupgr!==before_upgr)
        $fatal(1,"E->M must be a silent local transition");
      read1(0,value);if(value!==3||c0.states[0]!==1||c1.states[0]!==1)$fatal(1,"shared read after E->M failed");
      read0(32'hc0,value);if(c0.states[6]!==2)$fatal(1,"second exclusive acquisition failed");
      read1(32'hc0,value);if(c0.states[6]!==1||c1.states[6]!==1)$fatal(1,"E->S intervention failed");
      write0(0,7);reference[0]=7;if(c0.states[0]!==3||c1.states[0]!==0)$fatal(1,"S->M invalidation failed");
      read1(0,value);if(value!==7||c0.states[0]!==1||c1.states[0]!==1)$fatal(1,"modified intervention failed value=%0d",value);
      fork write0(0,11); write1(0,13); join
      reference[0]=(c0.states[0]==3)?11:13;
      read0(0,value);if(value!==reference[0])$fatal(1,"competing writes serialization failed got=%0d expected=%0d",value,reference[0]);
      before_inv=inv0+inv1;
      before_false_bus=busrd+busrdx+busupgr;
      write0(32'h40,32'h11111111);write1(32'h44,32'h22222222);
      read0(32'h40,value);if(value!==32'h11111111)$fatal(1,"false sharing word0 corrupted");
      read0(32'h44,value);if(value!==32'h22222222)$fatal(1,"false sharing word1 corrupted");
      if(inv0+inv1<=before_inv)$fatal(1,"false sharing did not cause invalidation traffic");
      $display("MEASURE false_sharing invalidations=%0d bus_transactions=%0d",inv0+inv1-before_inv,busrd+busrdx+busupgr-before_false_bus);
      before_wb=wb0+wb1;
      read0(32'h200,value);read0(32'h200+CACHE_SIZE,value);
      if(wb0+wb1!==before_wb)$fatal(1,"clean eviction incorrectly wrote back");
      lfsr=SEED;
      for(litmus_k=0;litmus_k<100;litmus_k=litmus_k+1)begin
        write0(32'h80,0);write0(32'h84,32'h1000+litmus_k);
        fork
          begin repeat(lfsr[2:0])@(posedge clk);write0(32'h80,1);end
          begin repeat(lfsr[5:3])@(posedge clk);flag_value=0;spin_count=0;
            while(flag_value!=1&&spin_count<200)begin read1(32'h80,flag_value);spin_count=spin_count+1;end
            if(flag_value!=1)$fatal(1,"message passing flag timeout iteration=%0d c0state=%0d c1state=%0d c0flag=%x c1flag=%x br=%b%b ctrl=%0d/%0d",litmus_k,c0.states[4],c1.states[4],c0.data[4][31:0],c1.data[4][31:0],br1,br0,c0.control_state,c1.control_state);
            read1(32'h84,data_value);if(data_value!==32'h1000+litmus_k)$fatal(1,"message passing stale data iteration=%0d",litmus_k);
          end
        join
        lfsr={lfsr[30:0],lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};
      end
      lfsr=SEED;
      for(k=0;k<RANDOM_OPS;k=k+1)begin
        lfsr={lfsr[30:0],lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};
        if(lfsr[2])begin
          if(lfsr[3])write0({26'b0,lfsr[7:4],2'b00},lfsr^k);else write1({26'b0,lfsr[7:4],2'b00},lfsr^k);
          reference[lfsr[7:4]]=lfsr^k;
        end else begin
          if(lfsr[3])read0({26'b0,lfsr[7:4],2'b00},value);else read1({26'b0,lfsr[7:4],2'b00},value);
          if(value!==reference[lfsr[7:4]])$fatal(1,"random mismatch op=%0d addr=%0d got=%x expected=%x",k,lfsr[7:4],value,reference[lfsr[7:4]]);
        end
      end
      write0(0,32'hfeed1234);read0(CACHE_SIZE,value);
      if(mem.lines[0][31:0]!==32'hfeed1234)$fatal(1,"dirty eviction writeback failed");
      if(transitions[2]==0||transitions[1]==0||transitions[3]==0||transitions[11]==0||transitions[9]==0||transitions[7]==0||transitions[4]==0||transitions[13]==0||transitions[12]==0)
        $fatal(1,"MESI transition coverage incomplete IE=%0d IS=%0d IM=%0d EM=%0d ES=%0d SM=%0d SI=%0d MS=%0d MI=%0d",transitions[2],transitions[1],transitions[3],transitions[11],transitions[9],transitions[7],transitions[4],transitions[13],transitions[12]);
      $display("COVERAGE MESI IE=%0d IS=%0d IM=%0d EM=%0d ES=%0d SM=%0d SI=%0d MS=%0d MI=%0d",transitions[2],transitions[1],transitions[3],transitions[11],transitions[9],transitions[7],transitions[4],transitions[13],transitions[12]);
      $display("PASS coherence cache=%0d random=%0d litmus=100 BusRd=%0d BusRdX=%0d BusUpgr=%0d invalidations=%0d hits=%0d misses=%0d writebacks=%0d cycles=%0d",CACHE_SIZE,RANDOM_OPS,busrd,busrdx,busupgr,inv0+inv1,h0+h1,mi0+mi1,wb0+wb1,elapsed_cycles);
      $finish;
    end
endmodule
`default_nettype wire
