module DSP48A1(
  input [17:0]A,B,D,BCIN,
  input [47:0]C,
  input[7:0]OPMODE,
  input CLK,CARRYIN,
  input RSTA,RSTB,RSTM,RSTP,RSTC,RSTD,RSTCARRYIN,RSTOPMODE,
  input CEA,CEB,CEM,CEP,CEC,CED,CEARRYIN,CEOPMODE,
  input [47:0] PCIN,
  output  [17:0]BCOUT,
  output  [47:0] PCOUT,P,
  output  [35:0] M,
  output  CARRYOUT, CARRYOUTF);
 parameter A0REG=0,A1REG=1,B0REG=0,B1REG=1,CREG=1,DREG=1,PREG=1,MREG=1,CARRYINREG=1,CARRYOUTREG=1,OPMODEREG=1,CARRYINSEL="OPMODE[5]",B_INPUT="DIRECT",RSTTYPE="SYNC";


wire [17:0]D_REG_OUT,B0_REG_OUT,A0_REG_OUT;
wire [47:0]C_REG_OUT; //output of instantiated modules
wire [7:0]OPMODE_REG_OUT;
wire [17:0]B1_REG_OUT;
wire [17:0]A1_REG_OUT;
wire [36:0]M_REG_OUT;
wire [47:0]P_REG_OUT;
wire CYI_REG_OUT;
reg [17:0]ADD_SUB1_OUT;
reg [47:0]ADD_SUB2_OUT;
reg ADD_SUB2_CARRYOUT;
reg [17:0] B_MUX_OUT; //B0_REG input 
reg [17:0] MUX2_OUT;
wire [35:0] MUL_OUT;
wire CARRY_CASCADE;
reg [47:0] MUX_X_OUT,MUX_Z_OUT;
wire [47:0] D_A_B_CONCATENATED;
wire bufferd_output;

 
//instantation
D_FF_MUX #(.WIDTH(8),.RSTTYPE(RSTTYPE),.SEL(OPMODEREG)) OPMODE_REG(.D(OPMODE),.CLK(CLK),.RST(RSTOPMODE),.EN(CEOPMODE),.MUX_OUT(OPMODE_REG_OUT));
D_FF_MUX #(.WIDTH(18),.RSTTYPE(RSTTYPE),.SEL(DREG)) D_REG(.D(D),.CLK(CLK),.RST(RSTD),.EN(CED),.MUX_OUT(D_REG_OUT));
D_FF_MUX #(.WIDTH(18),.RSTTYPE(RSTTYPE),.SEL(B0REG)) B0_REG(.D(B_MUX_OUT),.CLK(CLK),.RST(RSTB),.EN(CEB),.MUX_OUT(B0_REG_OUT));
D_FF_MUX #(.WIDTH(18),.RSTTYPE(RSTTYPE),.SEL(A0REG)) A0_REG(.D(A),.CLK(CLK),.RST(RSTA),.EN(CEA),.MUX_OUT(A0_REG_OUT));
D_FF_MUX #(.WIDTH(48),.RSTTYPE(RSTTYPE),.SEL(CREG)) C_REG(.D(C),.CLK(CLK),.RST(RSTC),.EN(CEC),.MUX_OUT(C_REG_OUT));
D_FF_MUX #(.WIDTH(18),.RSTTYPE(RSTTYPE),.SEL(B1REG)) B1_REG(.D(MUX2_OUT),.CLK(CLK),.RST(RSTB),.EN(CEB),.MUX_OUT(B1_REG_OUT));
D_FF_MUX #(.WIDTH(18),.RSTTYPE(RSTTYPE),.SEL(A1REG)) A1_REG(.D(A0_REG_OUT),.CLK(CLK),.RST(RSTA),.EN(CEA),.MUX_OUT(A1_REG_OUT));
D_FF_MUX #(.WIDTH(36),.RSTTYPE(RSTTYPE),.SEL(MREG)) M_REG(.D(MUL_OUT),.CLK(CLK),.RST(RSTM),.EN(CEM),.MUX_OUT(M_REG_OUT));
D_FF_MUX #(.WIDTH(48),.RSTTYPE(RSTTYPE),.SEL(PREG)) P_REG(.D(ADD_SUB2_OUT),.CLK(CLK),.RST(RSTM),.EN(CEP),.MUX_OUT(ADD_SUB2_OUT));
D_FF_MUX #(.WIDTH(1),.RSTTYPE(RSTTYPE),.SEL(CARRYINREG)) CYI_REG(.D(CARRY_CASCADE),.CLK(CLK),.RST(RSTCARRYIN),.EN(CECARRYIN),.MUX_OUT(CYI_REG_OUT));
D_FF_MUX #(.WIDTH(1),.RSTTYPE(RSTTYPE),.SEL(CARRYOUTREG)) CYO_REG(.D(ADD_SUB2_CARRYOUT),.CLK(CLK),.RST(RSTCARRYIN),.EN(CECARRYIN),.MUX_OUT(CARRYOUT));


//MUX_B
always@(B or BCIN or B_MUX_OUT or B_INPUT)begin
if(B_INPUT=="DIRECT") B_MUX_OUT=B;
else if (B_INPUT=="CASCADE") B_MUX_OUT=BCIN;
end



always @(*) begin
//1st ADD/SUB OPERTION
  if(OPMODE[6]) ADD_SUB1_OUT= D_REG_OUT - B0_REG_OUT;
  else  ADD_SUB1_OUT=D_REG_OUT + B0_REG_OUT;

  //2nd mux 
  if(~OPMODE[4]) MUX2_OUT=ADD_SUB1_OUT;
  else  MUX2_OUT=B0_REG_OUT;
  end



//MULTIPLIER
assign MUL_OUT=A1_REG_OUT * B1_REG_OUT;

//BCOUT
assign BCOUT=B1_REG_OUT;

//buffer
buf(bufferd_output,M_REG_OUT); 
assign M= bufferd_output;


//CONCATENATED
assign D_A_B_CONCATENATD={D_REG_OUT[11:0],A1_REG_OUT,B1_REG_OUT};



//MUX_X
always @(D_A_B_CONCATENATD or PCOUT or M_REG_OUT or OPMODE[1:0] ) begin 
 case(OPMODE[1:0])
  2'b00: MUX_X_OUT= 48'bZ;
  2'b01: MUX_X_OUT= M_REG_OUT;
  2'b10: MUX_X_OUT = PCOUT;
  2'b11: MUX_X_OUT= D_A_B_CONCATENATED;
  default: MUX_X_OUT=48'bz;
  endcase
 end

 //MUX_Z
 always@ (C_REG_OUT or P or PCIN or OPMODE[3:2] ) begin
  case(OPMODE[3:2])
  2'b00: MUX_Z_OUT= 48'bX;
  2'b01: MUX_Z_OUT= PCIN;
  2'b10: MUX_Z_OUT=P;
  2'b11: MUX_Z_OUT=C_REG_OUT;
  default: MUX_Z_OUT=48'bz;
 endcase
end

//carryin mux
assign CARRY_CASCADE=(CARRYINSEL=="OPMODE[5]")?OPMODE[5]:(CARRYINSEL=="CARRYIN")? CARRYIN:0;

//post adder/sub
always  @(*) begin
   if(OPMODE[7]) ADD_SUB2_OUT = MUX_Z_OUT-(MUX_X_OUT+CYI_REG_OUT);
   else {ADD_SUB2_CARRYOUT, ADD_SUB2_OUT} = MUX_X_OUT+ MUX_Z_OUT + CYI_REG_OUT;
end



//OUTPUTS
assign P=P_REG_OUT;
assign PCOUT=P;
assign CARRYOUT=CARRYOUTF;


endmodule