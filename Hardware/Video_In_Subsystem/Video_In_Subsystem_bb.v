
module Video_In_Subsystem (
	clk_clk,
	reset_reset_n,
	video_in_TD_CLK27,
	video_in_TD_DATA,
	video_in_TD_HS,
	video_in_TD_VS,
	video_in_clk27_reset,
	video_in_TD_RESET,
	video_in_overflow_flag,
	rgba_image_data,
	rgba_image_valid,
	stream_control_endofpacket,
	stream_control_ready,
	stream_control_sreset,
	video_in_feed_forward_avalon_forward_sink_data,
	video_in_feed_forward_avalon_forward_sink_startofpacket,
	video_in_feed_forward_avalon_forward_sink_endofpacket,
	video_in_feed_forward_avalon_forward_sink_empty,
	video_in_feed_forward_avalon_forward_sink_valid,
	video_in_feed_forward_avalon_forward_sink_ready,
	video_in_scaler_avalon_scaler_source_ready,
	video_in_scaler_avalon_scaler_source_startofpacket,
	video_in_scaler_avalon_scaler_source_endofpacket,
	video_in_scaler_avalon_scaler_source_valid,
	video_in_scaler_avalon_scaler_source_data,
	video_in_scaler_avalon_scaler_source_channel);	

	input		clk_clk;
	input		reset_reset_n;
	input		video_in_TD_CLK27;
	input	[7:0]	video_in_TD_DATA;
	input		video_in_TD_HS;
	input		video_in_TD_VS;
	input		video_in_clk27_reset;
	output		video_in_TD_RESET;
	output		video_in_overflow_flag;
	output	[31:0]	rgba_image_data;
	output		rgba_image_valid;
	input		stream_control_endofpacket;
	output		stream_control_ready;
	output		stream_control_sreset;
	input	[23:0]	video_in_feed_forward_avalon_forward_sink_data;
	input		video_in_feed_forward_avalon_forward_sink_startofpacket;
	input		video_in_feed_forward_avalon_forward_sink_endofpacket;
	input	[1:0]	video_in_feed_forward_avalon_forward_sink_empty;
	input		video_in_feed_forward_avalon_forward_sink_valid;
	output		video_in_feed_forward_avalon_forward_sink_ready;
	input		video_in_scaler_avalon_scaler_source_ready;
	output		video_in_scaler_avalon_scaler_source_startofpacket;
	output		video_in_scaler_avalon_scaler_source_endofpacket;
	output		video_in_scaler_avalon_scaler_source_valid;
	output	[23:0]	video_in_scaler_avalon_scaler_source_data;
	output		video_in_scaler_avalon_scaler_source_channel;
endmodule
