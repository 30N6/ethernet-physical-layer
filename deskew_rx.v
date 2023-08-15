/* Buffers must contain at least as much as the max dynamic skew.
* The maxium skew is the largest difference in the fill level
* of the buffers at any time.
* Lane markers read out of each lane at the same time
*/
module deskew_rx #(
	parameter LANE_N = 4,
	parameter BLOCK_W = 66,
	/* max dynamic skew */
	parameter MAX_SKEW_BIT_N = 1856,
	parameter MAX_SKEW_BLOCK_N = ( MAX_SKEW_BIT_N - BLOCK_W -1 )/BLOCK_W
)(
	input clk,
	input nreset,

	input [LANE_N-1:0] valid_i, // valid blocks, signal_ok and block lock
	// alignement marker lock interface	
	input [LANE_N-1:0] am_slip_v_i, 
	input [LANE_N-1:0] am_lock_v_i,
	
	// block data
	input [LANE_N*BLOCK_W-1:0] data_i,

	// deskwed data	
	output [LANE_N*BLOCK_W-1:0] data_o
);
logic am_full_lock_v;
assign am_full_lock_v = &( valid_i & am_lock_v_i);

genvar l;
generate
	for(l=0; l<LANE_N; l++) begin
		// displatch data per lane
		deskew_lane_rx #(
			.BLOCK_W(BLOCK_W),
			.MAX_SKEW_BIT_N(MAX_SKEW_BIT_N),
			.MAX_SKEW_BLOCK_N(MAX_SKEW_BLOCK_N)
		)m_deskew_lane(
			.clk(clk),
			.nreset(nreset),
			.am_slip_v_i(am_slip_v_i[l]),
			.am_full_lock_v_i(am_full_lock_v),
			.data_i(data_i[l*BLOCK_W+BLOCK_W-1:l*BLOCK_W]),
			.data_o(data_o[l*BLOCK_W+BLOCK_W-1:l*BLOCK_W])
		);
	end
endgenerate

endmodule