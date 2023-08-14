/* Testbench for the decoding module
 * with the x(l)gmii interface
 */
module xgmii_dec_rx_tb;
localparam IS_40G = 1;
localparam HEAD_W = 2;
localparam DATA_W = 64;
localparam KEEP_W = DATA_W/8;
localparam CTRL_W = 8;
localparam BLOCK_TYPE_W = 8;
localparam LANE0_CNT_N  = IS_40G ? 1 : 2;
localparam XGMII_DATA_W = 64;	
localparam XGMII_CTRL_W = XGMII_DATA_W/8;	

localparam SYNC_HEAD_CTRL = 2'b10;
localparam SYNC_HEAD_DATA = 2'b01;

localparam [BLOCK_TYPE_W-1:0]
    BLOCK_TYPE_CTRL     = 8'h1e, // C7 C6 C5 C4 C3 C2 C1 C0 BT
    BLOCK_TYPE_IDLE     = 8'h00,
    BLOCK_TYPE_OS_4     = 8'h2d, // D7 D6 D5 O4 C3 C2 C1 C0 BT
    BLOCK_TYPE_START_4  = 8'h33, // D7 D6 D5    C3 C2 C1 C0 BT
    BLOCK_TYPE_OS_START = 8'h66, // D7 D6 D5    O0 D3 D2 D1 BT
    BLOCK_TYPE_OS_04    = 8'h55, // D7 D6 D5 O4 O0 D3 D2 D1 BT
    BLOCK_TYPE_START_0  = 8'h78, // D7 D6 D5 D4 D3 D2 D1    BT
    BLOCK_TYPE_OS_0     = 8'h4b, // C7 C6 C5 C4 O0 D3 D2 D1 BT
    BLOCK_TYPE_TERM_0   = 8'h87, // C7 C6 C5 C4 C3 C2 C1    BT
    BLOCK_TYPE_TERM_1   = 8'h99, // C7 C6 C5 C4 C3 C2    D0 BT
    BLOCK_TYPE_TERM_2   = 8'haa, // C7 C6 C5 C4 C3    D1 D0 BT
    BLOCK_TYPE_TERM_3   = 8'hb4, // C7 C6 C5 C4    D2 D1 D0 BT
    BLOCK_TYPE_TERM_4   = 8'hcc, // C7 C6 C5    D3 D2 D1 D0 BT
    BLOCK_TYPE_TERM_5   = 8'hd2, // C7 C6    D4 D3 D2 D1 D0 BT
    BLOCK_TYPE_TERM_6   = 8'he1, // C7    D5 D4 D3 D2 D1 D0 BT
    BLOCK_TYPE_TERM_7   = 8'hff; //    D6 D5 D4 D3 D2 D1 D0 BT

localparam [CTRL_W-1:0] 
	XGMII_CTRL_IDLE  = 8'h07,	
	XGMII_CTRL_START = 8'hfb,	
	XGMII_CTRL_TERM  = 8'hfd,
	XGMII_CTRL_ERR   = 8'hfe;

logic [HEAD_W-1:0]      head_i;
logic [DATA_W-1:0]      data_i;
logic                   ctrl_v_o;
logic                   idle_v_o;
logic [LANE0_CNT_N-1:0] start_v_o;
logic                   term_v_o;
logic                   err_v_o;
logic                   ord_v_o;
logic [DATA_W-1:0]      data_o;
logic [KEEP_W-1:0]      keep_o;
logic [XGMII_DATA_W-1:0] xgmii_txd_o;
logic [XGMII_CTRL_W-1:0] xgmii_txc_o;

reg clk; 
always clk = #5 ~clk;

initial begin
	$dumpfile("build/wave.vcd");
	$dumpvars(0, xgmii_dec_rx_tb);
	
	// test 1 : send idle
	$display("test 1 %t", $time);
	head_i = SYNC_HEAD_CTRL; 	
	data_i[CTRL_W-1:0] = BLOCK_TYPE_IDLE;
	data_i[DATA_W-1:CTRL_W] = { $random, $random };
	#1
	assert(&xgmii_txc_o);
	assert(xgmii_txd_o[CTRL_W-1:0] == XGMII_CTRL_IDLE);

	$display("Test finished"); 
	$finish;
end


// decoder
pcs_dec_lite #( .IS_40G(IS_40G))
m_dec_lite(
.head_i(head_i),
.data_i(data_i),
.ctrl_v_o(ctrl_v_o),
.idle_v_o(idle_v_o),
.start_v_o(start_v_o),
.term_v_o(term_v_o),
.err_v_o(err_v_o),
.ord_v_o(ord_v_o),
.data_o(data_o), // x(l)gmii data
.keep_o(keep_o)
);

// decoder -> xgmii interface
xgmii_dec_intf_rx #(.IS_40G(IS_40G))
m_xgmii_dec_intf(
.ctrl_v_i(ctrl_v_o),
.idle_v_i(idle_v_o),
.start_v_i(start_v_o),
.term_v_i(term_v_o),
.err_v_i(err_v_o),
.ord_v_i(ord_v_o),
.data_i(data_o), // x(l)gmii data
.keep_i(keep_o), 
.xgmii_txd_o(xgmii_txd_o),
.xgmii_txc_o(xgmii_txc_o)
);


endmodule
