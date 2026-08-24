`default_nettype none
module cache_controller(
    input logic clk,input logic rst_n,input logic lookup_miss,input logic victim_modified,
    input logic bus_done,output logic do_writeback,output logic do_refill,output logic respond
);
    typedef enum logic[2:0]{IDLE,LOOKUP,WRITEBACK,REFILL,RESPOND}state_t;
    state_t state,next;
    always_comb begin
      next=state;do_writeback=0;do_refill=0;respond=0;
      case(state)
        IDLE:next=LOOKUP;
        LOOKUP:if(lookup_miss)next=victim_modified?WRITEBACK:REFILL;else next=RESPOND;
        WRITEBACK:begin do_writeback=1;if(bus_done)next=REFILL;end
        REFILL:begin do_refill=1;if(bus_done)next=RESPOND;end
        RESPOND:begin respond=1;next=IDLE;end
        default:next=IDLE;
      endcase
    end
    always_ff@(posedge clk or negedge rst_n)if(!rst_n)state<=IDLE;else state<=next;
endmodule
`default_nettype wire
