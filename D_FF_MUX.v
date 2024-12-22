module D_FF_MUX(D,CLK,RST,EN,MUX_OUT);
parameter RSTTYPE="SYNC";
parameter SEL=1;
parameter WIDTH=18; 
input EN; input [WIDTH-1:0] D; input CLK; input RST; output [WIDTH-1:0]MUX_OUT;

reg Q1,Q2;
wire Q;
assign Q=(RSTTYPE=="SYNC")?Q1:(RSTTYPE=="ASYNC")?Q2:0;


  assign MUX_OUT = (SEL)? D : Q;

generate
if(RSTTYPE=="SYNC") begin
always @(posedge CLK) begin
 if (RST)
  Q1<=0;
else if(EN)
   Q1<=D;
 end     
end

else if(RSTTYPE== "ASYNC") begin
    always @(posedge CLK or negedge RST) begin
  if (RST)
   Q2<=0;
 else if(EN)
    Q2<=D;
  end
end
 
endgenerate
endmodule 