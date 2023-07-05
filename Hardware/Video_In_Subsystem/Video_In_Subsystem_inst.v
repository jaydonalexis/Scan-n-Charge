	Video_In_Subsystem u0 (
		.clk_clk                                                 (<connected-to-clk_clk>),                                                 //                                       clk.clk
		.reset_reset_n                                           (<connected-to-reset_reset_n>),                                           //                                     reset.reset_n
		.video_in_TD_CLK27                                       (<connected-to-video_in_TD_CLK27>),                                       //                                  video_in.TD_CLK27
		.video_in_TD_DATA                                        (<connected-to-video_in_TD_DATA>),                                        //                                          .TD_DATA
		.video_in_TD_HS                                          (<connected-to-video_in_TD_HS>),                                          //                                          .TD_HS
		.video_in_TD_VS                                          (<connected-to-video_in_TD_VS>),                                          //                                          .TD_VS
		.video_in_clk27_reset                                    (<connected-to-video_in_clk27_reset>),                                    //                                          .clk27_reset
		.video_in_TD_RESET                                       (<connected-to-video_in_TD_RESET>),                                       //                                          .TD_RESET
		.video_in_overflow_flag                                  (<connected-to-video_in_overflow_flag>),                                  //                                          .overflow_flag
		.rgba_image_data                                         (<connected-to-rgba_image_data>),                                         //                                rgba_image.data
		.rgba_image_valid                                        (<connected-to-rgba_image_valid>),                                        //                                          .valid
		.stream_control_endofpacket                              (<connected-to-stream_control_endofpacket>),                              //                            stream_control.endofpacket
		.stream_control_ready                                    (<connected-to-stream_control_ready>),                                    //                                          .ready
		.stream_control_sreset                                   (<connected-to-stream_control_sreset>),                                   //                                          .sreset
		.video_in_feed_forward_avalon_forward_sink_data          (<connected-to-video_in_feed_forward_avalon_forward_sink_data>),          // video_in_feed_forward_avalon_forward_sink.data
		.video_in_feed_forward_avalon_forward_sink_startofpacket (<connected-to-video_in_feed_forward_avalon_forward_sink_startofpacket>), //                                          .startofpacket
		.video_in_feed_forward_avalon_forward_sink_endofpacket   (<connected-to-video_in_feed_forward_avalon_forward_sink_endofpacket>),   //                                          .endofpacket
		.video_in_feed_forward_avalon_forward_sink_empty         (<connected-to-video_in_feed_forward_avalon_forward_sink_empty>),         //                                          .empty
		.video_in_feed_forward_avalon_forward_sink_valid         (<connected-to-video_in_feed_forward_avalon_forward_sink_valid>),         //                                          .valid
		.video_in_feed_forward_avalon_forward_sink_ready         (<connected-to-video_in_feed_forward_avalon_forward_sink_ready>),         //                                          .ready
		.video_in_scaler_avalon_scaler_source_ready              (<connected-to-video_in_scaler_avalon_scaler_source_ready>),              //      video_in_scaler_avalon_scaler_source.ready
		.video_in_scaler_avalon_scaler_source_startofpacket      (<connected-to-video_in_scaler_avalon_scaler_source_startofpacket>),      //                                          .startofpacket
		.video_in_scaler_avalon_scaler_source_endofpacket        (<connected-to-video_in_scaler_avalon_scaler_source_endofpacket>),        //                                          .endofpacket
		.video_in_scaler_avalon_scaler_source_valid              (<connected-to-video_in_scaler_avalon_scaler_source_valid>),              //                                          .valid
		.video_in_scaler_avalon_scaler_source_data               (<connected-to-video_in_scaler_avalon_scaler_source_data>),               //                                          .data
		.video_in_scaler_avalon_scaler_source_channel            (<connected-to-video_in_scaler_avalon_scaler_source_channel>)             //                                          .channel
	);

