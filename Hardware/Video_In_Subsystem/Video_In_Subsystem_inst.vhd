	component Video_In_Subsystem is
		port (
			clk_clk                                                 : in  std_logic                     := 'X';             -- clk
			reset_reset_n                                           : in  std_logic                     := 'X';             -- reset_n
			video_in_TD_CLK27                                       : in  std_logic                     := 'X';             -- TD_CLK27
			video_in_TD_DATA                                        : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- TD_DATA
			video_in_TD_HS                                          : in  std_logic                     := 'X';             -- TD_HS
			video_in_TD_VS                                          : in  std_logic                     := 'X';             -- TD_VS
			video_in_clk27_reset                                    : in  std_logic                     := 'X';             -- clk27_reset
			video_in_TD_RESET                                       : out std_logic;                                        -- TD_RESET
			video_in_overflow_flag                                  : out std_logic;                                        -- overflow_flag
			rgba_image_data                                         : out std_logic_vector(31 downto 0);                    -- data
			rgba_image_valid                                        : out std_logic;                                        -- valid
			stream_control_endofpacket                              : in  std_logic                     := 'X';             -- endofpacket
			stream_control_ready                                    : out std_logic;                                        -- ready
			stream_control_sreset                                   : out std_logic;                                        -- sreset
			video_in_feed_forward_avalon_forward_sink_data          : in  std_logic_vector(23 downto 0) := (others => 'X'); -- data
			video_in_feed_forward_avalon_forward_sink_startofpacket : in  std_logic                     := 'X';             -- startofpacket
			video_in_feed_forward_avalon_forward_sink_endofpacket   : in  std_logic                     := 'X';             -- endofpacket
			video_in_feed_forward_avalon_forward_sink_empty         : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- empty
			video_in_feed_forward_avalon_forward_sink_valid         : in  std_logic                     := 'X';             -- valid
			video_in_feed_forward_avalon_forward_sink_ready         : out std_logic;                                        -- ready
			video_in_scaler_avalon_scaler_source_ready              : in  std_logic                     := 'X';             -- ready
			video_in_scaler_avalon_scaler_source_startofpacket      : out std_logic;                                        -- startofpacket
			video_in_scaler_avalon_scaler_source_endofpacket        : out std_logic;                                        -- endofpacket
			video_in_scaler_avalon_scaler_source_valid              : out std_logic;                                        -- valid
			video_in_scaler_avalon_scaler_source_data               : out std_logic_vector(23 downto 0);                    -- data
			video_in_scaler_avalon_scaler_source_channel            : out std_logic                                         -- channel
		);
	end component Video_In_Subsystem;

	u0 : component Video_In_Subsystem
		port map (
			clk_clk                                                 => CONNECTED_TO_clk_clk,                                                 --                                       clk.clk
			reset_reset_n                                           => CONNECTED_TO_reset_reset_n,                                           --                                     reset.reset_n
			video_in_TD_CLK27                                       => CONNECTED_TO_video_in_TD_CLK27,                                       --                                  video_in.TD_CLK27
			video_in_TD_DATA                                        => CONNECTED_TO_video_in_TD_DATA,                                        --                                          .TD_DATA
			video_in_TD_HS                                          => CONNECTED_TO_video_in_TD_HS,                                          --                                          .TD_HS
			video_in_TD_VS                                          => CONNECTED_TO_video_in_TD_VS,                                          --                                          .TD_VS
			video_in_clk27_reset                                    => CONNECTED_TO_video_in_clk27_reset,                                    --                                          .clk27_reset
			video_in_TD_RESET                                       => CONNECTED_TO_video_in_TD_RESET,                                       --                                          .TD_RESET
			video_in_overflow_flag                                  => CONNECTED_TO_video_in_overflow_flag,                                  --                                          .overflow_flag
			rgba_image_data                                         => CONNECTED_TO_rgba_image_data,                                         --                                rgba_image.data
			rgba_image_valid                                        => CONNECTED_TO_rgba_image_valid,                                        --                                          .valid
			stream_control_endofpacket                              => CONNECTED_TO_stream_control_endofpacket,                              --                            stream_control.endofpacket
			stream_control_ready                                    => CONNECTED_TO_stream_control_ready,                                    --                                          .ready
			stream_control_sreset                                   => CONNECTED_TO_stream_control_sreset,                                   --                                          .sreset
			video_in_feed_forward_avalon_forward_sink_data          => CONNECTED_TO_video_in_feed_forward_avalon_forward_sink_data,          -- video_in_feed_forward_avalon_forward_sink.data
			video_in_feed_forward_avalon_forward_sink_startofpacket => CONNECTED_TO_video_in_feed_forward_avalon_forward_sink_startofpacket, --                                          .startofpacket
			video_in_feed_forward_avalon_forward_sink_endofpacket   => CONNECTED_TO_video_in_feed_forward_avalon_forward_sink_endofpacket,   --                                          .endofpacket
			video_in_feed_forward_avalon_forward_sink_empty         => CONNECTED_TO_video_in_feed_forward_avalon_forward_sink_empty,         --                                          .empty
			video_in_feed_forward_avalon_forward_sink_valid         => CONNECTED_TO_video_in_feed_forward_avalon_forward_sink_valid,         --                                          .valid
			video_in_feed_forward_avalon_forward_sink_ready         => CONNECTED_TO_video_in_feed_forward_avalon_forward_sink_ready,         --                                          .ready
			video_in_scaler_avalon_scaler_source_ready              => CONNECTED_TO_video_in_scaler_avalon_scaler_source_ready,              --      video_in_scaler_avalon_scaler_source.ready
			video_in_scaler_avalon_scaler_source_startofpacket      => CONNECTED_TO_video_in_scaler_avalon_scaler_source_startofpacket,      --                                          .startofpacket
			video_in_scaler_avalon_scaler_source_endofpacket        => CONNECTED_TO_video_in_scaler_avalon_scaler_source_endofpacket,        --                                          .endofpacket
			video_in_scaler_avalon_scaler_source_valid              => CONNECTED_TO_video_in_scaler_avalon_scaler_source_valid,              --                                          .valid
			video_in_scaler_avalon_scaler_source_data               => CONNECTED_TO_video_in_scaler_avalon_scaler_source_data,               --                                          .data
			video_in_scaler_avalon_scaler_source_channel            => CONNECTED_TO_video_in_scaler_avalon_scaler_source_channel             --                                          .channel
		);

