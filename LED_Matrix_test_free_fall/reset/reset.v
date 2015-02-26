module reset(//reset about 10s
	input clk,//20MHz
	output reg rst_n//low active
);
	reg	[27:0] cnt;
	always @(posedge clk)
	begin
		cnt <= (cnt <= 28'd200000000 / 4'd8) ? (cnt+1'b1) : cnt;
		rst_n <= (cnt >= 28'd190000000 / 4'd8) ? 1'b1 : 1'b0;
	end
endmodule 