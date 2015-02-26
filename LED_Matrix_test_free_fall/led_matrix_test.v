module led_matrix_test(
	input OSC_CLK,
	output [7:0] col,
	output [7:0] row
					);
					
//===========================CLK Generate===========================//
	pll	pll_inst (
	.inclk0 ( OSC_CLK ),//inclk 20M
	.c0 ( CLK_20M ),//20M
	.c1 ( CLK_100M )//100M
	);
	wire CLK_20M,CLK_100M;
	
//===========================reset signal generate===========================//
	reset reset_inst(
	.clk(CLK_20M),
	.rst_n(rst_n)
	);
	
	wire rst_n;
	
//===========================Led ctrl===========================//
	light_data light_data_inst
	(
	.clk(CLK_20M) ,	// input  clk
	.rst_n(rst_n) ,	// input  rst_n
	.led_prepared(led_prepared) ,	// input  led_prepared
	.led_en(led_en) ,	// output  led_en
	.height(height) 	// output [3:0] height
	);
	wire led_en;
	wire [3:0] height;
	
	led_ctrl_free_fall led_ctrl_free_fall_inst
	(
	.clk(CLK_20M) ,	// input  clk
	.rst_n(rst_n) ,	// input  rst_n
	.led_en(led_en) ,	// input  led_en
	.height(height) ,	// input [4:0] height
	.col(col) ,	// output [7:0] col
	.row(row), 	// output [7:0] row
	.led_prepared(led_prepared) 	// output  light_finished
	);
	wire led_prepared;
endmodule 