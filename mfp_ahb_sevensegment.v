
`include "mfp_ahb_const.vh"



module mfp_ahb_sevensegment (
	input                        HCLK,
    input                        HRESETn,
    input      [  1         :0]  HTRANS,
    input      [ 31         :0]  HWDATA,
    input                        HWRITE,
    input                        HSEL,
    input             [3:0]      HADDR,


// memory mapped I/o  
 
	output						CA,
	output						CB,
	output						CC,
	output						CD,
	output						CE,
	output						CF,
	output						CG,
	output [7:0]				AN,
	output                      DP
	);
	
	reg  [3:0]  HADDR_d;
    reg         HWRITE_d;
    reg         HSEL_d;
    reg  [1:0]  HTRANS_d;
    reg  [31:0] upper;
    reg  [31:0] lower;
    reg  [7:0]  dp;
    reg  [7:0]  en;
    wire        we;  

mfp_ahb_sevensegtimer  mfp_ahb_sevensegtimer(.clk(HCLK), .resetn(HRESETn), .EN(en), .DIGITS({upper, lower}), .dp(dp), .DISPENOUT(AN), .DISPOUT({DP,CA,CB,CC,CD,CE,CF,CG}));
  
// always at the positive clock edge passing the value to the defined register   
   always @ (posedge HCLK) 
	  begin
			HADDR_d  <= HADDR;
			HWRITE_d <= HWRITE;
			HSEL_d   <= HSEL;
			HTRANS_d <= HTRANS;
	  end
	  
	  assign we = (HTRANS_d != `HTRANS_IDLE) & HSEL_d & HWRITE_d;  // condition to select the seven-segment display
	  
	 always @(posedge HCLK or negedge HRESETn)
             if (~HRESETn) begin                              // at the reset condition the value of the seven segment displa will be as follow
               upper <= 32'H00000000;  
               lower <= 32'H00000000;
               en    <= 8'HF0;
               dp    <= 8'hF7;
             end else if (we)                               // if the write enable is asserted then the data from push button is given to the seven-segment display
             begin
                  case (HADDR_d)
                `H_SS_LADDR : lower <= HWDATA[31:0];
                 `H_SS_HADDR : upper <= HWDATA[31:0];
                 `H_SS_VADDR : en    <= HWDATA[7:0];
                 `H_SS_DADDR : dp    <= HWDATA[7:0];
               endcase  
               end  
	
	endmodule
	
