module ctr(
  input clk,
  input reset,
  input write,
  
  output reg load,
  output reg IROM_EN,
  output reg IRB_RW,
  output reg busy,
  output done
);
  reg [5:0] cnt;    
  reg done_flag;
  
  reg [2:0] cstate, nstate; 
  parameter LorD = 3'b000, CMD = 3'b001, PROC = 3'b010, WRITE = 3'b011, WAIT = 3'b100, IDLE = 3'b101;

  
  assign done = done_flag;  
  
  always@(posedge clk)begin
    if(reset)
      cstate <= IDLE;
    else
      cstate <= nstate;  
  end
  
  always@(posedge clk)begin
    if(reset||(cstate == CMD)||(cstate == PROC))
      cnt <= 6'd0;
    else if((cstate == LorD)||(cstate == WRITE))
      cnt <= cnt + 1;
  end
  
  always@(posedge clk)begin
    if(reset)
      done_flag <= 1'b0;
    else if(write && (cnt == 'd63))
      done_flag <= 1'b1;
  end
  
  always@*begin
    case(cstate)
      IDLE:nstate = LorD;            
      LorD:begin
        if(cnt == 'd63)
          nstate = WAIT;
        else
          nstate = LorD;
      end
      WAIT:nstate = CMD;
      CMD:begin
        if(write)
          nstate = WRITE;
        else
          nstate = PROC;        
      end
      PROC:begin 
        if(write)
          nstate = WRITE;
        else
          nstate = CMD;        
      end
      WRITE:begin
        if(cnt == 'd63)
          nstate = LorD;
        else
          nstate = WRITE;
      end
      default:nstate = LorD;          
    endcase
  end
  
  always@*begin
    case(cstate)
      IDLE:begin
        load = 1'b0;
        IROM_EN = 1'b0;
        busy = 1'b1;
        IRB_RW = 1'b1;
      end
      LorD:begin
        load = 1'b1;
        IROM_EN = 1'b0;
        busy = 1'b1;
        IRB_RW = 1'b1;
      end
      WAIT:begin
        load = 1'b0;
        IROM_EN = 1'b0;
        busy = 1'b1;
        IRB_RW = 1'b1;
      end
      CMD:begin
        load = 1'b0;
        IROM_EN = 1'b1;
        busy = 1'b0; 
        IRB_RW = 1'b1;        
      end
      PROC:begin
        load = 1'b0;
        IROM_EN = 1'b1;
        busy = 1'b1;      
        IRB_RW = 1'b1;
      end
      WRITE:begin
        load = 1'b0;
        IROM_EN = 1'b1;
        busy = 1'b1;
        IRB_RW = 1'b0;
      end
      default:begin
        load = 1'b0;
        IROM_EN = 1'b1;
        busy = 1'b0;
        IRB_RW = 1'b1;
      end
    endcase
  end
endmodule