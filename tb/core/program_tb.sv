`timescale 1ns/1ps
`default_nettype none
module program_tb #(
  parameter HEX_FILE="programs/binaries/sum_1_to_100.hex",
  parameter logic[31:0]EXPECTED=5050,
  parameter TEST_NAME="program"
);
 logic clk=0,rst_n=0;always#5 clk=~clk;logic irq,iready=1,drq,dwr,dready=1;logic[31:0]ia,id,da,dwd,drd;logic[3:0]be;
 logic[63:0]cy,ins,st,bc,bt;logic rv,ill;logic[31:0]rp,ri;logic[31:0]memory[0:8191];integer i;logic host_written;
 rv32_core dut(.clk,.rst_n,.imem_request(irq),.imem_address(ia),.imem_read_data(id),.imem_ready(iready),.dmem_request(drq),.dmem_write(dwr),.dmem_address(da),.dmem_write_data(dwd),.dmem_byte_enable(be),.dmem_read_data(drd),.dmem_ready(dready),.cycle_count(cy),.instruction_count(ins),.stall_count(st),.branch_count(bc),.branch_taken_count(bt),.retired_valid(rv),.retired_pc(rp),.retired_instruction(ri),.illegal_instruction(ill));
 always_comb begin id=memory[ia[14:2]];drd=memory[da[14:2]];end
 always_ff@(posedge clk)if(drq&&dwr)begin
   if(be[0])memory[da[14:2]][7:0]<=dwd[7:0];if(be[1])memory[da[14:2]][15:8]<=dwd[15:8];
   if(be[2])memory[da[14:2]][23:16]<=dwd[23:16];if(be[3])memory[da[14:2]][31:24]<=dwd[31:24];
   if(da==32'h1ffc)host_written<=1;
 end
 always@(posedge clk)if(rst_n&&dut.u_registers.registers[0]!==0)$fatal(1,"x0 invariant");
 initial begin
   for(i=0;i<8192;i=i+1)memory[i]=0;host_written=0;$readmemh(HEX_FILE,memory);
   repeat(3)@(posedge clk);rst_n<=1;
   repeat(20000)begin @(posedge clk);#1;if(ill)$fatal(1,"%s illegal at %x",TEST_NAME,rp);
     if(host_written)begin if(memory[32'h1000>>2]!==EXPECTED)$fatal(1,"%s result=%0d expected=%0d",TEST_NAME,memory[32'h1000>>2],EXPECTED);
       $display("PASS program %s result=%0d cycles=%0d retired=%0d",TEST_NAME,EXPECTED,cy,ins);$finish;end end
   $fatal(1,"%s timeout pc=%x",TEST_NAME,ia);
 end
endmodule
`default_nettype wire
