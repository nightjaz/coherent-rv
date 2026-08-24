`default_nettype none
module mesi_controller (
    input  logic [1:0] current_state,
    input  logic       local_read,
    input  logic       local_write,
    input  logic       bus_shared,
    input  logic       snoop_valid,
    input  logic [1:0] snoop_command,
    output logic [1:0] next_state,
    output logic [1:0] local_bus_command,
    output logic       local_bus_request,
    output logic       snoop_hit,
    output logic       snoop_supply,
    output logic       snoop_invalidate
);
    localparam logic [1:0] MESI_I=0, MESI_S=1, MESI_E=2, MESI_M=3;
    localparam logic [1:0] BUS_RD=0, BUS_RDX=1, BUS_UPGR=2, BUS_WB=3;
    always_comb begin
        next_state=current_state; local_bus_command=BUS_RD; local_bus_request=0;
        snoop_hit=0; snoop_supply=0; snoop_invalidate=0;
        if (snoop_valid) begin
            snoop_hit = current_state != MESI_I;
            case (snoop_command)
                BUS_RD: case(current_state)
                    MESI_E: begin next_state=MESI_S; snoop_supply=1; end
                    MESI_M: begin next_state=MESI_S; snoop_supply=1; end
                    default: ;
                endcase
                BUS_RDX: if (current_state != MESI_I) begin
                    snoop_supply = current_state == MESI_M || current_state == MESI_E;
                    snoop_invalidate=1; next_state=MESI_I;
                end
                BUS_UPGR: if (current_state == MESI_S) begin snoop_invalidate=1; next_state=MESI_I; end
                default: ;
            endcase
        end else if (local_write) begin
            case(current_state)
                MESI_I: begin local_bus_request=1; local_bus_command=BUS_RDX; next_state=MESI_M; end
                MESI_S: begin local_bus_request=1; local_bus_command=BUS_UPGR; next_state=MESI_M; end
                default: next_state=MESI_M;
            endcase
        end else if (local_read && current_state == MESI_I) begin
            local_bus_request=1; local_bus_command=BUS_RD;
            next_state=bus_shared ? MESI_S : MESI_E;
        end
    end
endmodule
`default_nettype wire
