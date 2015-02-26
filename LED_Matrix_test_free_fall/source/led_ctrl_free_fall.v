//-----------------------------------------------------------------------------------------------------------------
//  File Name		:    led_ctrl_free_fall
//  Department      :    NEK、MPHY
//  Author			:    YDX
//  Author's Tel	:    18056076496
//-----------------------------------------------------------------------------------------------------------------
//  Release History
//  Version	Date			Author		Description
//  3.0	2015-02-23	    YDX
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
//  Tool versions:	 Quartus II  13.1 32-bit
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
module led_ctrl_free_fall(
	input clk,//20M
	input rst_n,
	
	input led_en,
	input [3:0] height,
	
	output [7:0] col,
	output [7:0] row,
	output led_prepared
				);
				
	parameter frame_time = 40'd1000000;//500ms
	parameter hold_time = frame_time / 4'd3 * 4'd2 ;
	parameter remain_time = frame_time - hold_time;
	parameter fall_1_time_h = hold_time + remain_time * 10'd378 / 10'd1000,//root(1/7)
			  fall_2_time_h = hold_time + remain_time * 10'd535 / 10'd1000,//root(2/7)
			  fall_3_time_h = hold_time + remain_time * 10'd655 / 10'd1000,//root(3/7)
			  fall_4_time_h = hold_time + remain_time * 10'd756 / 10'd1000,//root(4/7)
			  fall_5_time_h = hold_time + remain_time * 10'd845 / 10'd1000,//root(5/7)
			  fall_6_time_h = hold_time + remain_time * 10'd926 / 10'd1000;//root(6/7)
	
	parameter fall_1_time_o = hold_time * 10'd143 / 10'd1000,//1/7
			  fall_2_time_o = hold_time * 10'd286 / 10'd1000,//2/7
			  fall_3_time_o = hold_time * 10'd429 / 10'd1000,//3/7
			  fall_4_time_o = hold_time * 10'd571 / 10'd1000,//4/7
			  fall_5_time_o = hold_time * 10'd714 / 10'd1000,//5/7
			  fall_6_time_o = hold_time * 10'd857 / 10'd1000;//6/7
			  
	parameter rise_1_time = frame_time * 10'd143 / 16'd2000,//1/7/2
			  rise_2_time = frame_time * 10'd286 / 16'd2000,//2/7/2
			  rise_3_time = frame_time * 10'd429 / 16'd2000,//3/7/2
			  rise_4_time = frame_time * 10'd571 / 16'd2000,//4/7/2
			  rise_5_time = frame_time * 10'd714 / 16'd2000,//5/7/2
			  rise_6_time = frame_time * 10'd857 / 16'd2000;//6/7/2
			  
	reg	[39:0] time_cnt;
	
	
	parameter ws = 3'd4,//word size is 4
			  ms = 4'd8;//memory size is 8
	reg	[ws-1'b1:0] height_current[ms-1'b1:0];//8 height_current,each is 4-bit width
	reg	[ws-1'b1:0] height_last[ms-1'b1:0];//8 height_current,each is 4-bit width
	reg	[ws-1'b1:0] height_current_0,height_current_1,
					height_current_2,height_current_3,
					height_current_4,height_current_5,
					height_current_6,height_current_7;
	reg	[ws-1'b1:0] height_last_0,height_last_1,
					height_last_2,height_last_3,
					height_last_4,height_last_5,
					height_last_6,height_last_7;
	
	parameter ch = 4'd8;//column height is the number of leds in a column
	reg	[ch-1'b1:0] col_last[ms-1'b1:0];//8 column data,each is 8-bit
	//reg	[ch-1'b1:0] col_current[ms-1'b1:0];//8 column data(current),each is 8-bit
	//reg	[ch-1'b1:0] col_temp[ms-1'b1:0];//8 column data(last),each is 8-bit
	
	reg	[1:0] cache_SM;
	reg	[ws-1'b1:0] index/*,col_index*/;
	reg	[ws-1'b1:0] row_index_0,row_index_1,row_index_2,row_index_3,
					row_index_4,row_index_5,row_index_6,row_index_7;//row_index controls which led shouble be lighted in a column;
	
	reg	cache_ok;
	
//	reg [7:0] led_SM;
//	localparam Idle 	= 8'h1,
//			   Col_ctrl	= 8'h2, 
//			   Light 	= 8'h4;
			   
//	reg	[ch-1'b1:0] column;
//	reg	[ws-1'b1:0] height_diff_o[ms-1'b1:0];
//	reg	[ws-1'b1:0] height_diff_h[ms-1'b1:0];
//	reg	[ws-1'b1:0] diff_cnt_o,diff_cnt_h;
	reg	col0_en,col1_en,col2_en,col3_en,col4_en,col5_en,col6_en,col7_en;
	
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)begin
			index <= 4'd0;
			cache_ok <= 1'b0;
			cache_SM <= 2'b00;
		end
		else begin
			case(cache_SM)
			2'b00:begin
				cache_ok <= 1'b0;
				cache_SM <= (led_en) ? 2'b01 : 2'b00;
				height_current[0] <= (led_en) ? height : height_current[0]; 
				height_last[0] <= (led_en) ? height_current[0] : height_last[0]; 
				index <= (led_en) ? 4'h1 : 4'h0;
			end
			2'b01:begin
				if(led_en)begin
					height_current[index] <= height;
					height_last[index] <= height_current[index];
					index <= index + 1'b1;
				end
				else begin
					cache_SM <= 2'b10;
				end
			end
			2'b10:begin
				height_current_0 <= (index == 4'd8) ? height_current[0] : 4'h0; 
				height_current_1 <= (index == 4'd8) ? height_current[1] : 4'h0; 
				height_current_2 <= (index == 4'd8) ? height_current[2] : 4'h0; 
				height_current_3 <= (index == 4'd8) ? height_current[3] : 4'h0; 
				height_current_4 <= (index == 4'd8) ? height_current[4] : 4'h0; 
				height_current_5 <= (index == 4'd8) ? height_current[5] : 4'h0; 
				height_current_6 <= (index == 4'd8) ? height_current[6] : 4'h0; 
				height_current_7 <= (index == 4'd8) ? height_current[7] : 4'h0;
				
				height_last_0 <= (index == 4'd8) ? height_last[0] : 4'h0; 
				height_last_1 <= (index == 4'd8) ? height_last[1] : 4'h0; 
				height_last_2 <= (index == 4'd8) ? height_last[2] : 4'h0; 
				height_last_3 <= (index == 4'd8) ? height_last[3] : 4'h0; 
				height_last_4 <= (index == 4'd8) ? height_last[4] : 4'h0; 
				height_last_5 <= (index == 4'd8) ? height_last[5] : 4'h0; 
				height_last_6 <= (index == 4'd8) ? height_last[6] : 4'h0; 
				height_last_7 <= (index == 4'd8) ? height_last[7] : 4'h0;
				
				cache_SM <= (index == 4'd8) ? 2'b11 : 2'b00;
				index <= 4'd0;
			end
			2'b11:begin//turn height data to column data
				cache_ok <= 1'b1;
				index <= index + 1'b1;
				cache_SM <= (index == 4'd7) ? 2'b00 : 2'b11;
				
//				case(height_current[index])//be careful that the leds are common anode and row[7] is at the bottom 
//				4'd8:begin col_current[index] <= 8'b00000000;end//all leds will be lighted
//				4'd7:begin col_current[index] <= 8'b00000001;end
//				4'd6:begin col_current[index] <= 8'b00000011;end
//				4'd5:begin col_current[index] <= 8'b00000111;end
//				4'd4:begin col_current[index] <= 8'b00001111;end
//				4'd3:begin col_current[index] <= 8'b00011111;end
//				4'd2:begin col_current[index] <= 8'b00111111;end
//				4'd1:begin col_current[index] <= 8'b01111111;end//only one led will be lighted,so row[7] is 0
//				4'd0:begin col_current[index] <= 8'b01111111;end//as above
//				default:begin col_current[index] <= 8'b11111111;end
//				endcase
				
				case(height_last[index])//be careful that the leds are common anode and row[7] is at the bottom 
				4'd8:begin col_last[index] <= 8'b00000000;end//all leds will be lighted
				4'd7:begin col_last[index] <= 8'b00000001;end
				4'd6:begin col_last[index] <= 8'b00000011;end
				4'd5:begin col_last[index] <= 8'b00000111;end
				4'd4:begin col_last[index] <= 8'b00001111;end
				4'd3:begin col_last[index] <= 8'b00011111;end
				4'd2:begin col_last[index] <= 8'b00111111;end
				4'd1:begin col_last[index] <= 8'b01111111;end//only one led will be lighted,so row[7] is 0
				4'd0:begin col_last[index] <= 8'b01111111;end//as above
				default:begin col_last[index] <= 8'b11111111;end
				endcase
			end
			default:cache_SM <= 2'b00;
			endcase
		end
	end
	

	reg	[1:0] col0_SM;
	reg	col0;
	reg	[7:0] column0,row0;
	reg	col0_prepared;
	reg	[39:0] time_cnt_0;
	reg	[ws-1'b1:0] diff_cnt_r_0,diff_cnt_o_0,diff_cnt_h_0,height_diff_0;
	
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)begin
			col0 <= 1'b0;
			column0 <= 8'hff;
			col0_prepared <= 1'b0;
			col0_SM <= 2'b00;
			col1_en <= 1'b0;
		end
		else begin
			case(col0_SM)
			2'b00:begin
				col1_en <= 1'b0;
				col0 <= 1'b0;
				row0 <= 8'hff;
				time_cnt_0 <= 40'h0;
				col0_prepared <= 1'b1;
				diff_cnt_r_0 <= 4'd0;
				diff_cnt_o_0 <= 4'd0;
				diff_cnt_h_0 <= 4'd0;
				if(cache_ok && col0_en)begin
					col0_SM <= (height_current_0 >= height_last_0) ? 2'b01 : 2'b10;
					height_diff_0 <= (height_current_0 >= height_last_0) ? (height_current_0 - height_last_0) : (height_last_0 - height_current_0);
					column0 <= col_last[0];
				end
				else begin
					height_diff_0 <= 4'd0;
					column0 <= 8'hff;
				end
			end
			2'b01:begin//rise
				col0_prepared <= 1'b0;
				col1_en <= 1'b0;
				if(time_cnt_0 <= frame_time)begin//within one frame
					col0_SM <= 2'b11;
					time_cnt_0 <= time_cnt_0 + 1'b1;
					
					diff_cnt_r_0 <= ((time_cnt_0 == rise_1_time) || (time_cnt_0 == rise_2_time) || (time_cnt_0 == rise_3_time) ||
									 (time_cnt_0 == rise_4_time) || (time_cnt_0 == rise_5_time) || (time_cnt_0 == rise_6_time))
									? (diff_cnt_r_0 + 1'b1): diff_cnt_r_0;
									
					if(diff_cnt_r_0 < height_diff_0)begin
						column0 <= ((time_cnt_0 == rise_1_time) || (time_cnt_0 == rise_2_time) || (time_cnt_0 == rise_3_time) ||
									(time_cnt_0 == rise_4_time) || (time_cnt_0 == rise_5_time) || (time_cnt_0 == rise_6_time))
									? {1'b0,column0[7:1]} : column0;
					end
					else begin
						column0 <=column0;
					end
				end
				else begin//a frame is finished
					col0_SM <= 2'b00;
					col0 <= 1'b0;
					column0 <= 8'hff;
				end
			end
			2'b10:begin//fall
				col0_prepared <= 1'b0;
				col1_en <= 1'b0;
				if(time_cnt_0 <= frame_time)begin//within one frame
					col0_SM <= 2'b11;
					time_cnt_0 <= time_cnt_0 + 1'b1;
					
					diff_cnt_o_0 <= ((time_cnt_0 == fall_1_time_o) || (time_cnt_0 == fall_2_time_o) || (time_cnt_0 == fall_3_time_o) ||
									 (time_cnt_0 == fall_4_time_o) || (time_cnt_0 == fall_5_time_o) || (time_cnt_0 == fall_6_time_o))
									? (diff_cnt_o_0 + 1'b1): diff_cnt_o_0;
					
					if(diff_cnt_o_0 < height_diff_0)begin
						if(time_cnt_0 <= fall_1_time_o)begin
							case(height_last_0)
							4'd8:column0 <= 8'b00000000;
							4'd7:column0 <= 8'b00000001;
							4'd6:column0 <= 8'b00000011;
							4'd5:column0 <= 8'b00000111;
							4'd4:column0 <= 8'b00001111;
							4'd3:column0 <= 8'b00011111;
							4'd2:column0 <= 8'b00111111;
							4'd1,
							4'd0:column0 <= 8'b01111111;
							default:begin end
							endcase
						end
						else if(time_cnt_0 <= fall_2_time_o)begin
							case(height_last_0)
							4'd8:column0 <= 8'b00000010;
							4'd7:column0 <= 8'b00000101;
							4'd6:column0 <= 8'b00001011;
							4'd5:column0 <= 8'b00010111;
							4'd4:column0 <= 8'b00101111;
							4'd3:column0 <= 8'b01011111;
							4'd2:column0 <= 8'b01111111;
							4'd1,
							4'd0:column0 <= 8'b01111111;
							default:begin end
							endcase
						end
						else if(time_cnt_0 <= fall_3_time_o)begin
							case(height_last_0)
							4'd8:column0 <= 8'b00000110;
							4'd7:column0 <= 8'b00001101;
							4'd6:column0 <= 8'b00011011;
							4'd5:column0 <= 8'b00110111;
							4'd4:column0 <= 8'b01101111;
							4'd3:column0 <= 8'b01011111;
							4'd2:column0 <= 8'b01111111;
							4'd1,
							4'd0:column0 <= 8'b01111111;
							default:begin end
							endcase
						end
						else if(time_cnt_0 <= fall_4_time_o)begin
							case(height_last_0)
							4'd8:column0 <= 8'b00001110;
							4'd7:column0 <= 8'b00011101;
							4'd6:column0 <= 8'b00111011;
							4'd5:column0 <= 8'b01110111;
							4'd4:column0 <= 8'b01101111;
							4'd3:column0 <= 8'b01011111;
							4'd2:column0 <= 8'b01111111;
							4'd1,
							4'd0:column0 <= 8'b01111111;
							default:begin end
							endcase
						end
						else if(time_cnt_0 <= fall_5_time_o)begin
							case(height_last_0)
							4'd8:column0 <= 8'b00011110;
							4'd7:column0 <= 8'b00111101;
							4'd6:column0 <= 8'b01111011;
							4'd5:column0 <= 8'b01110111;
							4'd4:column0 <= 8'b01101111;
							4'd3:column0 <= 8'b01011111;
							4'd2:column0 <= 8'b01111111;
							4'd1,
							4'd0:column0 <= 8'b01111111;
							default:begin end
							endcase
						end
						else if(time_cnt_0 <= fall_6_time_o)begin
							case(height_last_0)
							4'd8:column0 <= 8'b00111110;
							4'd7:column0 <= 8'b01111101;
							4'd6:column0 <= 8'b01111011;
							4'd5:column0 <= 8'b01110111;
							4'd4:column0 <= 8'b01101111;
							4'd3:column0 <= 8'b01011111;
							4'd2:column0 <= 8'b01111111;
							4'd1,
							4'd0:column0 <= 8'b01111111;
							default:begin end
							endcase
						end
						else begin
							case(height_last_0)
							4'd8:column0 <= 8'b01111110;
							4'd7:column0 <= 8'b01111101;
							4'd6:column0 <= 8'b01111011;
							4'd5:column0 <= 8'b01110111;
							4'd4:column0 <= 8'b01101111;
							4'd3:column0 <= 8'b01011111;
							4'd2:column0 <= 8'b01111111;
							4'd1,
							4'd0:column0 <= 8'b01111111;
							default:begin end
							endcase
						end
					end
					else begin
						column0 <= column0;
					end
					
					diff_cnt_h_0 <= ((time_cnt_0 == hold_time) || (time_cnt_0 == fall_1_time_h) || (time_cnt_0 == fall_2_time_h) ||
									 (time_cnt_0 == fall_3_time_h) || (time_cnt_0 == fall_4_time_h) || (time_cnt_0 == fall_5_time_h))
									? (diff_cnt_h_0 + 1'b1): diff_cnt_h_0;
					
					if(diff_cnt_h_0 < height_diff_0)begin
						if(time_cnt_0 <= hold_time)begin//the highest led keeps light for hold_time
								case(height_last_0)
								4'd8:column0[0] <= 1'b0;
								4'd7:column0[1:0] <= 2'b01;
								4'd6:column0[2:0] <= 3'b011;
								4'd5:column0[3:0] <= 4'b0111;
								4'd4:column0[4:0] <= 5'b01111;
								4'd3:column0[5:0] <= 6'b011111;
								4'd2:column0[6:0] <= 7'b0111111;
								4'd1,
								4'd0:column0[7:0] <= 8'b01111111;
								default:begin end
								endcase
							end
							else if(time_cnt_0 <= fall_1_time_h)begin
								case(height_last_0)
								4'd8:column0[1:0] <= 2'b01;
								4'd7:column0[2:0] <= 3'b011;
								4'd6:column0[3:0] <= 4'b0111;
								4'd5:column0[4:0] <= 5'b01111;
								4'd4:column0[5:0] <= 6'b011111;
								4'd3:column0[6:0] <= 7'b0111111;
								4'd2:column0[7:0] <= 8'b01111111;
								default:begin end
								endcase
							end
							else if(time_cnt_0 <= fall_2_time_h)begin
								case(height_last_0)
								4'd8:column0[2:0] <= 3'b011;
								4'd7:column0[3:0] <= 4'b0111;
								4'd6:column0[4:0] <= 5'b01111;
								4'd5:column0[5:0] <= 6'b011111;
								4'd4:column0[6:0] <= 7'b0111111;
								4'd3:column0[7:0] <= 8'b01111111;
								default:begin end
								endcase
							end
							else if(time_cnt_0 <= fall_3_time_h)begin
								case(height_last_0)
								4'd8:column0[3:0] <= 4'b0111;
								4'd7:column0[4:0] <= 5'b01111;
								4'd6:column0[5:0] <= 6'b011111;
								4'd5:column0[6:0] <= 7'b0111111;
								4'd4:column0[7:0] <= 8'b01111111;
								default:begin end
								endcase
							end
							else if(time_cnt_0 <= fall_4_time_h)begin
								case(height_last_0)
								4'd8:column0[4:0] <= 5'b01111;
								4'd7:column0[5:0] <= 6'b011111;
								4'd6:column0[6:0] <= 7'b0111111;
								4'd5:column0[7:0] <= 8'b01111111;
								default:begin end
								endcase
							end
							else if(time_cnt_0 <= fall_5_time_h)begin
								case(height_last_0)
								4'd8:column0[5:0] <= 6'b011111;
								4'd7:column0[6:0] <= 7'b0111111;
								4'd6:column0[7:0] <= 8'b01111111;
								default:begin end
								endcase
							end
							else if(time_cnt_0 <= fall_6_time_h)begin
								case(height_last_0)
								4'd8:column0[6:0] <= 7'b0111111;
								4'd7:column0[7:0] <= 8'b01111111;
								default:begin end
								endcase
							end
							else begin
								case(height_last_0)
								4'd8:column0[7:0] <= 8'b01111111;
								default:begin end
								endcase
							end
					end
					else begin
						column0 <= column0;
					end
				end
				else begin//One frame has been finished,turn to Idle to wait for next frame
					col0_SM <= 2'b00;
					col0 <= 1'b0;
					column0 <= 8'hff;
				end
			end
			2'b11:begin
				if(row_index_0 <= (ch - 1'b1))begin//within one column	
					row_index_0 <= row_index_0 + 1'b1;
					col0 <= 1'b1;//enable leds in this column
					row0 <= 8'hff;
					row0[row_index_0] <= column0[row_index_0];
				end
				else begin//Leds in prior column have been lighted,turn to next column
					row_index_0 <= 4'd0;
					//column0 <= 8'hff;
					col0 <= 1'b0;
					row0 <= 8'hff;
					col0_SM <= (height_current_0 >= height_last_0) ? 2'b01 : 2'b10;
					col1_en <= 1'b1;
				end
			end
			default:begin
				col0_SM <= 2'b00;
				col0 <= 1'b0;
				column0 <= 8'hff;
			end
			endcase
		end
	end
	
	assign row = row0 & row1;
	assign col = {col1,col0,5'h0};
	assign led_prepared = col0_prepared && col1_prepared;
	
	reg	[1:0] col1_SM;
	reg	col1;
	reg	[7:0] column1,row1;
	reg	col1_prepared;
	reg	[39:0] time_cnt_1;
	reg	[ws-1'b1:0] diff_cnt_r_1,diff_cnt_o_1,diff_cnt_h_1,height_diff_1;
	
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)begin
			col1 <= 1'b0;
			column1 <= 8'hff;
			col1_prepared <= 1'b0;
			col1_SM <= 2'b00;
			col0_en <= 1'b1;
		end
		else begin
			case(col1_SM)
			2'b00:begin
				col1 <= 1'b0;
				row1 <= 8'hff;
				
				time_cnt_1 <= 40'h0;
				col1_prepared <= 1'b1;
				diff_cnt_r_1 <= 4'd0;
				diff_cnt_o_1 <= 4'd0;
				diff_cnt_h_1 <= 4'd0;
				if(col1_en)begin
					col1_SM <= (height_current_1 >= height_last_1) ? 2'b01 : 2'b10;
					height_diff_1 <= (height_current_1 >= height_last_1) ? (height_current_1 - height_last_1) : (height_last_1 - height_current_1);
					column1 <= col_last[1];
					col0_en <= 1'b1;
				end
				else begin
					height_diff_1 <= 4'd0;
					column1 <= 8'hff;
					col0_en <= 1'b0;
				end
			end
			2'b01:begin//rise
				col1_prepared <= 1'b0;
				col0_en <= 1'b0;
				if(time_cnt_1 <= frame_time)begin//within one frame
					col1_SM <= 2'b11;
					time_cnt_1 <= time_cnt_1 + 1'b1;
					
					diff_cnt_r_1 <= ((time_cnt_1 == rise_1_time) || (time_cnt_1 == rise_2_time) || (time_cnt_1 == rise_3_time) ||
									 (time_cnt_1 == rise_4_time) || (time_cnt_1 == rise_5_time) || (time_cnt_1 == rise_6_time))
									? (diff_cnt_r_1 + 1'b1): diff_cnt_r_1;
									
					if(diff_cnt_r_1 < height_diff_1)begin
						column1 <= ((time_cnt_1 == rise_1_time) || (time_cnt_1 == rise_2_time) || (time_cnt_1 == rise_3_time) ||
									(time_cnt_1 == rise_4_time) || (time_cnt_1 == rise_5_time) || (time_cnt_1 == rise_6_time))
									? {1'b0,column1[7:1]} : column1;
					end
					else begin
						column1 <=column1;
					end
				end
				else begin//a frame is finished
					col1_SM <= 2'b00;
					col1 <= 1'b0;
					column1 <= 8'hff;
				end
			end
			2'b10:begin//fall
				col1_prepared <= 1'b0;
				col0_en <= 1'b0;
				if(time_cnt_1 <= frame_time)begin//within one frame
					col1_SM <= 2'b11;
					time_cnt_1 <= time_cnt_1 + 1'b1;
					
					diff_cnt_o_1 <= ((time_cnt_1 == fall_1_time_o) || (time_cnt_1 == fall_2_time_o) || (time_cnt_1 == fall_3_time_o) ||
									 (time_cnt_1 == fall_4_time_o) || (time_cnt_1 == fall_5_time_o) || (time_cnt_1 == fall_6_time_o))
									? (diff_cnt_o_1 + 1'b1): diff_cnt_o_1;
					
					if(diff_cnt_o_1 < height_diff_1)begin
						if(time_cnt_1 <= fall_1_time_o)begin
							case(height_last_1)
							4'd8:column1 <= 8'b00000000;
							4'd7:column1 <= 8'b00000001;
							4'd6:column1 <= 8'b00000011;
							4'd5:column1 <= 8'b00000111;
							4'd4:column1 <= 8'b00001111;
							4'd3:column1 <= 8'b00011111;
							4'd2:column1 <= 8'b00111111;
							4'd1,
							4'd0:column1 <= 8'b01111111;
							default:begin end
							endcase
						end
						else if(time_cnt_1 <= fall_2_time_o)begin
							case(height_last_1)
							4'd8:column1 <= 8'b00000010;
							4'd7:column1 <= 8'b00000101;
							4'd6:column1 <= 8'b00001011;
							4'd5:column1 <= 8'b00010111;
							4'd4:column1 <= 8'b00101111;
							4'd3:column1 <= 8'b01011111;
							4'd2:column1 <= 8'b01111111;
							4'd1,
							4'd0:column1 <= 8'b01111111;
							default:begin end
							endcase
						end
						else if(time_cnt_1 <= fall_3_time_o)begin
							case(height_last_1)
							4'd8:column1 <= 8'b00000110;
							4'd7:column1 <= 8'b00001101;
							4'd6:column1 <= 8'b00011011;
							4'd5:column1 <= 8'b00110111;
							4'd4:column1 <= 8'b01101111;
							4'd3:column1 <= 8'b01011111;
							4'd2:column1 <= 8'b01111111;
							4'd1,
							4'd0:column1 <= 8'b01111111;
							default:begin end
							endcase
						end
						else if(time_cnt_1 <= fall_4_time_o)begin
							case(height_last_1)
							4'd8:column1 <= 8'b00001110;
							4'd7:column1 <= 8'b00011101;
							4'd6:column1 <= 8'b00111011;
							4'd5:column1 <= 8'b01110111;
							4'd4:column1 <= 8'b01101111;
							4'd3:column1 <= 8'b01011111;
							4'd2:column1 <= 8'b01111111;
							4'd1,
							4'd0:column1 <= 8'b01111111;
							default:begin end
							endcase
						end
						else if(time_cnt_1 <= fall_5_time_o)begin
							case(height_last_1)
							4'd8:column1 <= 8'b00011110;
							4'd7:column1 <= 8'b00111101;
							4'd6:column1 <= 8'b01111011;
							4'd5:column1 <= 8'b01110111;
							4'd4:column1 <= 8'b01101111;
							4'd3:column1 <= 8'b01011111;
							4'd2:column1 <= 8'b01111111;
							4'd1,
							4'd0:column1 <= 8'b01111111;
							default:begin end
							endcase
						end
						else if(time_cnt_1 <= fall_6_time_o)begin
							case(height_last_1)
							4'd8:column1 <= 8'b00111110;
							4'd7:column1 <= 8'b01111101;
							4'd6:column1 <= 8'b01111011;
							4'd5:column1 <= 8'b01110111;
							4'd4:column1 <= 8'b01101111;
							4'd3:column1 <= 8'b01011111;
							4'd2:column1 <= 8'b01111111;
							4'd1,
							4'd0:column1 <= 8'b01111111;
							default:begin end
							endcase
						end
						else begin
							case(height_last_1)
							4'd8:column1 <= 8'b01111110;
							4'd7:column1 <= 8'b01111101;
							4'd6:column1 <= 8'b01111011;
							4'd5:column1 <= 8'b01110111;
							4'd4:column1 <= 8'b01101111;
							4'd3:column1 <= 8'b01011111;
							4'd2:column1 <= 8'b01111111;
							4'd1,
							4'd0:column1 <= 8'b01111111;
							default:begin end
							endcase
						end
					end
					else begin
						column1 <= column1;
					end
					
					diff_cnt_h_1 <= ((time_cnt_1 == hold_time) || (time_cnt_1 == fall_1_time_h) || (time_cnt_1 == fall_2_time_h) ||
									 (time_cnt_1 == fall_3_time_h) || (time_cnt_1 == fall_4_time_h) || (time_cnt_1 == fall_5_time_h))
									? (diff_cnt_h_1 + 1'b1): diff_cnt_h_1;
					
					if(diff_cnt_h_1 < height_diff_1)begin
						if(time_cnt_1 <= hold_time)begin//the highest led keeps light for hold_time
								case(height_last_1)
								4'd8:column1[0] <= 1'b0;
								4'd7:column1[1:0] <= 2'b01;
								4'd6:column1[2:0] <= 3'b011;
								4'd5:column1[3:0] <= 4'b0111;
								4'd4:column1[4:0] <= 5'b01111;
								4'd3:column1[5:0] <= 6'b011111;
								4'd2:column1[6:0] <= 7'b0111111;
								4'd1,
								4'd0:column1[7:0] <= 8'b01111111;
								default:begin end
								endcase
							end
							else if(time_cnt_1 <= fall_1_time_h)begin
								case(height_last_1)
								4'd8:column1[1:0] <= 2'b01;
								4'd7:column1[2:0] <= 3'b011;
								4'd6:column1[3:0] <= 4'b0111;
								4'd5:column1[4:0] <= 5'b01111;
								4'd4:column1[5:0] <= 6'b011111;
								4'd3:column1[6:0] <= 7'b0111111;
								4'd2:column1[7:0] <= 8'b01111111;
								default:begin end
								endcase
							end
							else if(time_cnt_1 <= fall_2_time_h)begin
								case(height_last_1)
								4'd8:column1[2:0] <= 3'b011;
								4'd7:column1[3:0] <= 4'b0111;
								4'd6:column1[4:0] <= 5'b01111;
								4'd5:column1[5:0] <= 6'b011111;
								4'd4:column1[6:0] <= 7'b0111111;
								4'd3:column1[7:0] <= 8'b01111111;
								default:begin end
								endcase
							end
							else if(time_cnt_1 <= fall_3_time_h)begin
								case(height_last_1)
								4'd8:column1[3:0] <= 4'b0111;
								4'd7:column1[4:0] <= 5'b01111;
								4'd6:column1[5:0] <= 6'b011111;
								4'd5:column1[6:0] <= 7'b0111111;
								4'd4:column1[7:0] <= 8'b01111111;
								default:begin end
								endcase
							end
							else if(time_cnt_1 <= fall_4_time_h)begin
								case(height_last_1)
								4'd8:column1[4:0] <= 5'b01111;
								4'd7:column1[5:0] <= 6'b011111;
								4'd6:column1[6:0] <= 7'b0111111;
								4'd5:column1[7:0] <= 8'b01111111;
								default:begin end
								endcase
							end
							else if(time_cnt_1 <= fall_5_time_h)begin
								case(height_last_1)
								4'd8:column1[5:0] <= 6'b011111;
								4'd7:column1[6:0] <= 7'b0111111;
								4'd6:column1[7:0] <= 8'b01111111;
								default:begin end
								endcase
							end
							else if(time_cnt_1 <= fall_6_time_h)begin
								case(height_last_1)
								4'd8:column1[6:0] <= 7'b0111111;
								4'd7:column1[7:0] <= 8'b01111111;
								default:begin end
								endcase
							end
							else begin
								case(height_last_1)
								4'd8:column1[7:0] <= 8'b01111111;
								default:begin end
								endcase
							end
					end
					else begin
						column1 <= column1;
					end
				end
				else begin//One frame has been finished,turn to Idle to wait for next frame
					col1_SM <= 2'b00;
					col1 <= 1'b0;
					column1 <= 8'hff;
				end
			end
			2'b11:begin
				if(row_index_1 <= (ch - 1'b1))begin//within one column	
					row_index_1 <= row_index_1 + 1'b1;
					col1 <= 1'b1;//enable leds in this column
					row1 <= 8'hff;
					row1[row_index_1] <= column1[row_index_1];
				end
				else begin//Leds in prior column have been lighted,turn to next column
					row_index_1 <= 4'd0;
					//column1 <= 8'hff;
					col1 <= 1'b0;
					row1 <= 8'hff;
					col1_SM <= (height_current_1 >= height_last_1) ? 2'b01 : 2'b10;
					col0_en <= 1'b1;
				end
			end
			default:begin
				col1_SM <= 2'b00;
				col1 <= 1'b0;
				column1 <= 8'hff;
			end
			endcase
		end
	end
	
//	assign row = row1;
//	assign col[1] = col1;
//	assign led_prepared = col1_prepared;
	

endmodule 