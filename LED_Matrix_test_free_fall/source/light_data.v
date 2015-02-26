//-----------------------------------------------------------------------------------------------------------------
//  File Name		:    light_data
//  Department      :    NEK、MPHY
//  Author			:    YDX
//  Author's Tel	:    18056076496
//-----------------------------------------------------------------------------------------------------------------
//  Release History
//  Version	Date			Author		Description
//  2.1		2015-02-06	    YDX
//-----------------------------------------------------------------------------------------------------------------
//  Keywords		:	1)		2)	3)
//
//-----------------------------------------------------------------------------------------------------------------
//  Parameter
//
//-----------------------------------------------------------------------------------------------------------------
//  Purpose		:
//
//-----------------------------------------------------------------------------------------------------------------
//  Target Device:	 Stratix III EP3SE110F
//  Tool versions:	 Quartus II  13.0 64-bit
//-----------------------------------------------------------------------------------------------------------------
//  Reuse Issues
//  Reset Strategy:
//  Clk Domains: 1)clk 20MHz
//  Critical Timing:
//  Asynchronous I/F:
//  Synthesizeable (y/n):y
//  Other:
//
//-FHDR--------------------------------------------------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////////////////////
module light_data(
	input clk,//20M
	input rst_n,
	
	input led_prepared,
	output reg led_en,
	output reg [3:0] height
				);
	
	reg [3:0] data_SM/*,sm_cnt*/;
	//reg	[3:0] height1,height2,height3,height4,height5,height6,height7,height8;
	reg [3:0] cnt;
	
	reg	[9:0] wait_cnt;
	
	wire [3:0] rn/*synthesis keep*/;
	assign rn[0] = ~(~(~rn[0]));
	assign rn[1] = ~(~(~(~(~rn[1]))));
	assign rn[2] = ~(~(~(~(~(~(~rn[2]))))));
	//assign rn[3] = ~(~(~(~(~(~(~(~(~rn[3]))))))));
	assign rn[3] = 1'b0;
 	reg	[3:0 ]random;
	always @(posedge clk)
	begin
		//random <= (rn <= 4'd8) ? rn : (rn - 4'd9);
		random <= rn;
	end
	
//	parameter _0 = 4'd0,
//			  _1 = 4'd1,
//			  _2 = 4'd2,
//			  _3 = 4'd3,
//			  _4 = 4'd4,
//			  _5 = 4'd5,
//			  _6 = 4'd6,
//			  _7 = 4'd7,
//			  _8 = 4'd8;
//			  
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)begin
			led_en <= 1'b0;
			height <= 4'h0;
			cnt <= 4'h4;
			wait_cnt <= 10'h0;
			//sm_cnt <= 2'b01;
		end
		else begin
			case(data_SM)
			4'h0:begin
				led_en <= 1'b0;
				height <= 4'h0;
				//data_SM <= (wait_cnt <= 10'd100) ? 4'h0 : 4'h1;
				wait_cnt <= (led_prepared) ? (wait_cnt + 1'b1) : wait_cnt;
				data_SM <= (wait_cnt == 10'd50) ? 4'h1 : 4'h0;
				//cnt <= (led_prepared && (cnt < 4'd8)) ? (cnt + 1'b1) : 4'h0;
				if(wait_cnt == 10'd50)begin
					if(cnt == 4'd4)begin
						cnt <= cnt + 4'd4;
					end
					else begin
						cnt <= 4'd4;
					end
				end
			end
			4'h1:begin
				wait_cnt <= 10'h0;
				led_en <= 1'b1;
				//height <= cnt;
				height <= random + 1'b1;
				data_SM <= 4'h2;
			end
			4'h2:begin
				led_en <= 1'b1;
				//height <= cnt;
				height <= random + 1'b1;
				data_SM <= 4'h3;
			end
			4'h3:begin
				led_en <= 1'b1;
				//height <= cnt;
				height <= random + 1'b1;
				data_SM <= 4'h4;
			end
			4'h4:begin
				led_en <= 1'b1;
				//height <= cnt;
				height <= random + 1'b1;
				data_SM <= 4'h5;
			end
			4'h5:begin
				led_en <= 1'b1;
				//height <= cnt;
				height <= random + 1'b1;
				data_SM <= 4'h6;
			end
			4'h6:begin
				led_en <= 1'b1;
				//height <= cnt;
				height <= random + 1'b1;
				data_SM <= 4'h7;
			end
			4'h7:begin
				led_en <= 1'b1;
				//height <= cnt;
				height <= random + 1'b1;
				data_SM <= 4'h8;
			end
			4'h8:begin
				led_en <= 1'b1;
				//height <= cnt;
				height <= random + 1'b1;
				data_SM <= 4'h0;
			end
//			2'b00:begin
//				led_en <= 1'b0;
//				height <= 4'h0;
//				cnt <= 4'h0;
//				//sm_cnt <= 2'b00;
//				//data_SM <= (light_prepared) ? sm_cnt : data_SM;
//				data_SM <= 2'b01;
//			end
//			2'b01:begin
//				led_en <= (cnt <= 4'd7) ? 1'b1 : 1'b0;
//				//height <= (height <= 4'd7) ? (height + 1'b1) : 4'd0;
//				//height <= 4'd4;
//				height <= random;
//				cnt <= (cnt <= 4'd7) ? (cnt + 1'b1) : 4'd0;
//				data_SM <= (cnt <= 4'd7) ? data_SM : 2'b00;
//				//sm_cnt <= (cnt <= 4'd7) ? sm_cnt : (sm_cnt + 1'b1);
//			end
//			2'b10:begin
//				led_en <= (cnt <= 4'd7) ? 1'b1 : 1'b0;
//				//height <= (height <= 4'd7) ? (height + 1'b1) : 4'd0;
//				height <= 4'd4;
//				//height <= {1'b0,rn};
//				cnt <= (cnt <= 4'd7) ? (cnt + 1'b1) : 4'd0;
//				data_SM <= (cnt <= 4'd7) ? data_SM : 2'b00;
//				sm_cnt <= (cnt <= 4'd7) ? sm_cnt : (sm_cnt + 1'b1);
//			end
//			2'b11:begin
//				led_en <= (cnt <= 4'd7) ? 1'b1 : 1'b0;
//				//height <= (height <= 4'd7) ? (height + 1'b1) : 4'd0;
//				height <= 4'd8;
//				//height <= {1'b0,rn};
//				cnt <= (cnt <= 4'd7) ? (cnt + 1'b1) : 4'd0;
//				data_SM <= (cnt <= 4'd7) ? data_SM : 2'b00;
//				sm_cnt <= (cnt <= 4'd7) ? sm_cnt : (2'b01);
//			end
			default:data_SM <= 4'h00;
			endcase
		end
	end

endmodule 