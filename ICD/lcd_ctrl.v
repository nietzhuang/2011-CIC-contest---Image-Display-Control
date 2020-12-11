module LCD_CTRL(clk, reset, IROM_Q, cmd, cmd_valid, IROM_EN, IROM_A, IRB_RW, IRB_D, IRB_A, busy, done);
  input clk;
  input reset;
  input [7:0] IROM_Q;
  input [2:0] cmd;
  input cmd_valid;
  output IROM_EN;
  output [5:0] IROM_A;
  output IRB_RW;
  output reg [7:0] IRB_D;
  output [5:0] IRB_A;
  output busy;
  output done;

  reg [7:0] mem[63:0];
  reg [5:0] point;  
  
  reg [6:0] i;  
  reg [5:0] cnt;
  reg [5:0] cnt_addr;
  reg write;
  wire [9:0] avg; 
  
  assign avg = ((mem[point-1] + mem[point]) + (mem[point+7] + mem[point+8])) >> 2;
  assign IROM_A = cnt_addr;
  assign IRB_A = cnt_addr;
  
  ctr ctr(
     .clk(clk),
     .reset(reset),
     .write(write),
  
     .load(load),
     .IROM_EN(IROM_EN),
     .IRB_RW(IRB_RW),
     .busy(busy),
     .done(done)
     );

  always@(/*posedge*/negedge clk)begin // it's not sure whether it synthesizable using negative edge ,or it can use 2 clock cycle for cmd state insteadly.
    if(reset||(!(load||write)))
      cnt_addr <= 'd0;
    else if(load||write)
      cnt_addr <= cnt_addr + 1;    
  end
  
  always@(posedge clk)begin
    if(reset||(!load))
      cnt <= 'd0;
    else if(load||write)
      cnt <= cnt + 1;  
  end
  
  always@(posedge clk)begin
    if(reset)
      point <= 'd28;
    else if(cmd_valid)begin
      case(cmd)
        3'b001:begin // shift up
          if(point > 'd7)
            point <= point - 'd8;        
        end
        3'b010:begin // shift down
          if(point < 'd49)
            point <= point + 'd8;        
        end
        3'b011:begin // shift left
          if(point[2:0] != 3'b001)
            point <= point - 'd1;
        end
        3'b100:begin // shift right
          if(point[2:0] != 3'b111)
            point <= point + 'd1;
        end
        3'b101:begin // average
          mem[point-1] <= avg[7:0];
          mem[point] <= avg[7:0];
          mem[point+7] <= avg[7:0];
          mem[point+8] <= avg[7:0];
        end
        3'b110:begin // mirror X
          mem[point+7] <= mem[point-1];
          mem[point+8] <= mem[point];
          mem[point-1] <= mem[point+7];
          mem[point] <= mem[point+8]; //......
        end
        3'b111: begin // mirror Y
          mem[point] <= mem[point-1];
          mem[point+8] <= mem[point+7];
          mem[point-1] <= mem[point];
          mem[point+7] <= mem[point+8]; 
        end        
        //default:
      endcase
    end
  end
  
  always@(posedge clk)begin
    if(reset)begin
      for(i = 0; i <= 64; i = i + 1)
        mem[i] <= 8'd0;
    end  
    else if(load)begin
      mem[cnt] <= IROM_Q;
    end           
  end
     
  always@(posedge clk)begin
    if(reset)
      write <= 1'b0;
    else if(cmd == 3'b000)
      write <= 1'b1;  
  end

  always@*begin    
    IRB_D = mem[cnt_addr];    
  end
  
endmodule

