------------------------------------------------------------------------
-- This component is used to save an image in memory. 
------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.math_real.ALL; -- For using ceil and log2.
USE IEEE.NUMERIC_STD.ALL; -- For using to_unsigned.
USE ieee.std_logic_unsigned.ALL; -- Needed for the sum used in counter.

ENTITY avalon_image_writer IS
	GENERIC (
		-- Size of each color component in bits (8 or 16).
		COMPONENT_SIZE : INTEGER := 8;
		-- Number of components per pixel that you will 
		--introduce in input_data (power of 2)
		NUMBER_COMPONENTS : INTEGER := 1;
		-- Number of pixels (all components) per write in the output avalon bus 
		--(>=1)
		PIX_WR : INTEGER := 4
	);
	PORT (
		-- Clock and reset.
		clk : IN STD_LOGIC;
		reset_n : IN STD_LOGIC;
		--stream reset only sets to 0 the pic and line counters 
		--to synchronize with the stream in case it is reset 
		--and save the configuration written by the processor. 
		stream_reset_n : IN STD_LOGIC;
		-- Image size
		img_width : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		img_height : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		-- Signals from the video stream representing one pixel
		input_data : IN STD_LOGIC_VECTOR((NUMBER_COMPONENTS * COMPONENT_SIZE - 1) DOWNTO 0);
		-- Signals to control the component
		-- When frame_valid is 1, the image from camera is being acquired.
		data_valid : IN STD_LOGIC; -- Valid pixel in R,G,B,Gray inputs.
		-- Avalon MM Slave port to configure the component
		S_address : IN STD_LOGIC_VECTOR(3 DOWNTO 0); --Address bus (4byte word addresses)
		S_writedata : IN STD_LOGIC_VECTOR(31 DOWNTO 0); --Input data bus (4byte word)
		S_readdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);--Output data bus (4byte word)
		S_write : IN STD_LOGIC; --Write signal
		S_read : IN STD_LOGIC; --Read signal
		-- Avalon MM Master port to save data into a memory.
		-- Byte addresses are multiples of 4 when accessing 32-bit data.
		M_address : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		M_write : OUT STD_LOGIC;
		M_byteenable : OUT STD_LOGIC_VECTOR((PIX_WR * NUMBER_COMPONENTS * COMPONENT_SIZE/8 - 1) DOWNTO 0);
		M_writedata : OUT STD_LOGIC_VECTOR((PIX_WR * NUMBER_COMPONENTS * COMPONENT_SIZE - 1) DOWNTO 0);
		M_waitrequest : IN STD_LOGIC;
		M_burstcount : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
	);
END avalon_image_writer;

ARCHITECTURE arch OF avalon_image_writer IS
	--Avalon slave
	--Internal register address map 
	--Mode permits to select between 2 modes: 
	--A 0 in this register (default) selects "SINGLE SHOT" mode.
	--A 1 in this register selects "CONTINUOUS" mode.
	CONSTANT MODE_ADDRESS : INTEGER := 0;
	CONSTANT BUFF0_ADDRESS : INTEGER := 1;
	CONSTANT BUFF1_ADDRESS : INTEGER := 2;
	--In continuous mode selects saving in 1 buffer (write a 0 here, 
	--the default after reset) or 2 buffers (write a 1 here)
	CONSTANT CONT_DOUBLE_BUFF_ADDRESS : INTEGER := 3;
	--Number of the buffer where you wanna write next image (0 or 1)
	--In CONTINUOUS mode writing in 2 buffers it is ignored cause
	--the component alternates buff0 and buff1.
	CONSTANT BUFFER_SELECT_ADDRESS : INTEGER := 4;
	-- Start the capure of image (SINGLE SHOT) or images (CONTINUOUS).
	-- In SINGLE SHOT write a 1 here to save 1 image to memory. It 
	-- automatically goes to 0 after writing a 1.
	-- In CONTINUOUS MODE write a 1 here to start capturing all images
	-- and write a 0 to stop the capture. 
	CONSTANT START_CAPTURE_ADDRESS : INTEGER := 5;
	-- Signal indicating standby state 
	--(outside of reset, waiting for flank in start_capture)
	--In SINGLE_SHOT mode it can be used after setting start_capture to 
	--check if writting the image to memory finished
	CONSTANT STANDBY_ADDRESS : INTEGER := 6;
	--Last buffer indicates which buffer was the last one written (0 or 1)
	CONSTANT LAST_BUFFER_ADDRESS : INTEGER := 7;
	--Downsampling rate (1=get all image, 2=half of rows and columns so
	--size is reduced by four, 4= one fourth of cols and rows are capture, 
	--so on...)
	CONSTANT DOWNSAMPLING_ADDRESS : INTEGER := 8;
	--Image counter
	CONSTANT IMAGE_COUNTER_ADDRESS : INTEGER := 9;
	--Associated registers
	SIGNAL mode : STD_LOGIC;
	SIGNAL buff0 : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL buff1 : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL cont_double_buff : STD_LOGIC;
	SIGNAL buffer_select : STD_LOGIC;
	SIGNAL start_capture : STD_LOGIC;
	SIGNAL standby : STD_LOGIC;
	SIGNAL last_buffer : STD_LOGIC;
	SIGNAL downsampling : STD_LOGIC_VECTOR(6 DOWNTO 0);
	SIGNAL image_counter : STD_LOGIC_VECTOR(31 DOWNTO 0);
	--Create macros for the modes (mode reg)
	CONSTANT SINGLE_SHOT : STD_LOGIC := '0';
	CONSTANT CONTINUOUS : STD_LOGIC := '1';
	--Create macros for cont_double_buff reg 
	CONSTANT SINGLE_BUFF : STD_LOGIC := '0';
	CONSTANT DOUBLE_BUFF : STD_LOGIC := '1';
	--Chip select
	SIGNAL cs : STD_LOGIC_VECTOR((2 ** 4 - 1) DOWNTO 0);
	--Variables for the state machine that writes values in memory
	TYPE array_of_std_logic_vector IS ARRAY(NATURAL RANGE <>)
	OF STD_LOGIC_VECTOR;
	CONSTANT NUMBER_OF_STATES : INTEGER := 4;
	--signals for the evolution of the state machine
	SIGNAL current_state : INTEGER RANGE 0 TO (NUMBER_OF_STATES - 1);
	SIGNAL next_state : INTEGER RANGE 0 TO (NUMBER_OF_STATES - 1);
	-- Conditions to change next state.
	-- State_condition(x) condition to go from x to x+1.
	SIGNAL state_condition : STD_LOGIC_VECTOR((NUMBER_OF_STATES - 2)
	DOWNTO 0);
	SIGNAL condition_2_to_1 : STD_LOGIC;
	--counters.
	SIGNAL pix_counter : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
	SIGNAL line_counter : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
	SIGNAL pix_wr_counter : STD_LOGIC_VECTOR(INTEGER(
	ceil(log2(real(PIX_WR + 1)))) DOWNTO 0);
	SIGNAL downsamp_counter_pixels : STD_LOGIC_VECTOR(6 DOWNTO 0);
	SIGNAL downsamp_counter_lines : STD_LOGIC_VECTOR(6 DOWNTO 0);
	SIGNAL enable_saving : STD_LOGIC;
	SIGNAL reset_buffer_address : STD_LOGIC;
	SIGNAL synchronized : STD_LOGIC;
	-- Write_buff saves the address where the next pixel will be saved.
	SIGNAL write_buff : STD_LOGIC_VECTOR(31 DOWNTO 0);
	-- Internal copy of the write output signal
	SIGNAL av_write : STD_LOGIC;
	-- Extra buffers to pack the pixels and reduce the number of writes in bus
	SIGNAL output_buff : array_of_std_logic_vector((PIX_WR - 1)
	DOWNTO 0) ((COMPONENT_SIZE * NUMBER_COMPONENTS - 1) DOWNTO 0);
	SIGNAL out_buff_EN : STD_LOGIC_VECTOR((PIX_WR - 1) DOWNTO 0);

BEGIN
	--Chip select for Avalon slave registers
	cs_generate : FOR I IN 0 TO (2 ** 4 - 1) GENERATE
		cs(I) <= '1' WHEN (I = S_address) ELSE '0';
	END GENERATE cs_generate;

	--Implement the logic of the registers connected to avalon slave
	avalon_slave : PROCESS (clk) BEGIN
		IF rising_edge(clk) THEN
			IF reset_n = '0' THEN --synchronous reset
				--reset only the registers only written from bus
				mode <= '0';
				buff0 <= (OTHERS => '0');
				buff1 <= (OTHERS => '0');
				cont_double_buff <= '0';
				buffer_select <= '0';
				downsampling <= (OTHERS => '0');
			ELSIF S_write = '1' THEN --write operation
				IF cs(MODE_ADDRESS) = '1' THEN
					mode <= S_writedata(0);
				ELSIF cs(BUFF0_ADDRESS) = '1' THEN
					buff0 <= S_writedata(31 DOWNTO 0);
				ELSIF cs(BUFF1_ADDRESS) = '1' THEN
					buff1 <= S_writedata(31 DOWNTO 0);
				ELSIF cs(CONT_DOUBLE_BUFF_ADDRESS) = '1' THEN
					cont_double_buff <= S_writedata(0);
				ELSIF cs(BUFFER_SELECT_ADDRESS) = '1' THEN
					buffer_select <= S_writedata(0);
				ELSIF cs(DOWNSAMPLING_ADDRESS) = '1' THEN
					downsampling <= S_writedata(6 DOWNTO 0);
				END IF;
			END IF;
		END IF;
		IF S_read = '1' THEN --read operation
			IF cs(MODE_ADDRESS) = '1' THEN
				S_readdata <= (31 DOWNTO 1 => '0') & mode;
			ELSIF cs(BUFF0_ADDRESS) = '1' THEN
				S_readdata <= buff0;
			ELSIF cs(BUFF1_ADDRESS) = '1' THEN
				S_readdata <= buff1;
			ELSIF cs(CONT_DOUBLE_BUFF_ADDRESS) = '1' THEN
				S_readdata <= (31 DOWNTO 1 => '0') & cont_double_buff;
			ELSIF cs(BUFFER_SELECT_ADDRESS) = '1' THEN
				S_readdata <= (31 DOWNTO 1 => '0') & buffer_select;
			ELSIF cs(START_CAPTURE_ADDRESS) = '1' THEN
				S_readdata <= (31 DOWNTO 1 => '0') & start_capture;
			ELSIF cs(STANDBY_ADDRESS) = '1' THEN
				S_readdata <= (31 DOWNTO 1 => '0') & standby;
			ELSIF cs(LAST_BUFFER_ADDRESS) = '1' THEN
				S_readdata <= (31 DOWNTO 1 => '0') & last_buffer;
			ELSIF cs(DOWNSAMPLING_ADDRESS) = '1' THEN
				S_readdata <= (31 DOWNTO 7 => '0') & downsampling;
			ELSIF cs(IMAGE_COUNTER_ADDRESS) = '1' THEN
				S_readdata <= image_counter;
			ELSE
				S_readdata <= (OTHERS => '0');
			END IF;
		END IF;
	END PROCESS avalon_slave;

	-- FSM (Finite State Machine) clocking and reset.
	fsm_mem : PROCESS (clk)
	BEGIN
		IF rising_edge(clk) THEN
			IF (reset_n = '0' OR stream_reset_n = '0') THEN
				current_state <= 0;
			ELSE
				current_state <= next_state;
			END IF;
		END IF;
	END PROCESS fsm_mem;

	-- Evolution of FSM.
	comb_fsm : PROCESS (current_state, state_condition, condition_2_to_1)
	BEGIN
		CASE current_state IS
			WHEN 0 =>
				IF state_condition(0) = '1' THEN
					next_state <= 1;
				ELSE
					next_state <= 0;
				END IF;
			WHEN 1 =>
				IF state_condition(1) = '1' THEN
					next_state <= 2;
				ELSE
					next_state <= 1;
				END IF;
			WHEN 2 =>
				IF condition_2_to_1 = '1' THEN
					next_state <= 1;
				ELSE
					next_state <= 2;
				END IF;
			WHEN OTHERS =>
				next_state <= 0;
		END CASE;
	END PROCESS comb_fsm;

	-- Conditions of FSM.
	state_condition(0) <= '1';
	state_condition(1) <= start_capture;

	--Evaluation and update pix_counter and line_counter
	pix_counter_proc : PROCESS (clk)
		VARIABLE end_of_image : STD_ULOGIC;
		VARIABLE end_of_line : STD_ULOGIC;
	BEGIN
		IF rising_edge(clk) THEN
			--Always count with pix and line counters
			IF (current_state = 0) THEN
				pix_counter <= (OTHERS => '0');
				line_counter <= (OTHERS => '0');
				image_counter <= (OTHERS => '0');
				end_of_image := '0';
				end_of_line := '0';
			ELSIF (data_valid = '1') THEN --new pixel in the input
				IF pix_counter = (img_width - 1) THEN
					pix_counter <= (OTHERS => '0');
					end_of_line := '1';
					IF line_counter = (img_height - 1) THEN
						line_counter <= (OTHERS => '0');
						end_of_image := '1';
						image_counter <= image_counter + 1;
					ELSE
						line_counter <= line_counter + 1;
						end_of_image := '0';
					END IF;
				ELSE
					pix_counter <= pix_counter + 1;
					end_of_image := '0';
					end_of_line := '0';
				END IF;
			END IF;

			IF (current_state = 1) THEN
				downsamp_counter_pixels <= (OTHERS => '0');
				downsamp_counter_lines <= (OTHERS => '0');
				pix_wr_counter <= (OTHERS => '0');
				condition_2_to_1 <= '0';
				reset_buffer_address <= '0';
				enable_saving <= '0';
			ELSE
				IF (data_valid = '1') THEN --new pixel in the input
					--Generate the conditions to change state
					IF (synchronized = '1') --at least 1 image captured at this point
						AND (end_of_image = '1')
						AND (mode = SINGLE_SHOT OR (mode = CONTINUOUS AND start_capture = '0')) THEN
						condition_2_to_1 <= '1';
					END IF;
					--Generate signal to permit saving in registers
					IF end_of_image = '1' THEN
						enable_saving <= '1';
					END IF;
					--Generate downsampling counters and write counter (count only if savinf is enabled)
					IF enable_saving = '1' AND data_valid = '1' THEN
						IF end_of_image = '1' THEN
							downsamp_counter_lines <= (OTHERS => '0');
						ELSIF end_of_line = '1' THEN
							IF downsamp_counter_lines + 1 = downsampling THEN
								downsamp_counter_lines <= (OTHERS => '0');
							ELSE
								downsamp_counter_lines <= downsamp_counter_lines + 1;
							END IF;
						END IF;

						IF end_of_line = '1' THEN
							downsamp_counter_pixels <= (OTHERS => '0');
						ELSE
							IF downsamp_counter_pixels + 1 = downsampling THEN
								downsamp_counter_pixels <= (OTHERS => '0');
							ELSE
								downsamp_counter_pixels <= downsamp_counter_pixels + 1;
							END IF;
						END IF;

						IF (downsamp_counter_pixels + 1) = downsampling AND
							(downsamp_counter_lines + 1) = downsampling THEN
							IF pix_wr_counter = (PIX_WR - 1) THEN
								pix_wr_counter <= (OTHERS => '0');
							ELSE
								pix_wr_counter <= pix_wr_counter + 1;
							END IF;
						END IF;
					END IF;
					--Update buffer address at the end of the image
					IF (end_of_image = '1') THEN
						reset_buffer_address <= '1';
					ELSE
						reset_buffer_address <= '0';
					END IF;

				END IF;
			END IF;
		END IF;
	END PROCESS;

	sync_proc : PROCESS (clk)
	BEGIN
		IF rising_edge(clk) THEN
			IF (current_state = 1) THEN
				synchronized <= '0';
			ELSIF (data_valid = '1') AND (current_state = 2) AND enable_saving = '1' THEN
				synchronized <= '1';
			END IF;
		END IF;
	END PROCESS;

	-- Generate standby signal
	WITH current_state SELECT standby <=
		'1' WHEN 1,
		'0' WHEN OTHERS;

	--generate start_capture
	start_capture_proc : PROCESS (clk)
	BEGIN
		IF rising_edge(clk) THEN
			IF (reset_n = '0') THEN
				start_capture <= '0';
			ELSIF mode = SINGLE_SHOT THEN
				IF start_capture = '1' THEN
					start_capture <= '0';
				ELSE
					IF S_write = '1' AND cs(START_CAPTURE_ADDRESS) = '1' THEN
						start_capture <= S_writedata(0);
					END IF;
				END IF;
			ELSIF mode = CONTINUOUS THEN
				IF S_write = '1' AND cs(START_CAPTURE_ADDRESS) = '1' THEN
					start_capture <= S_writedata(0);
				END IF;
			END IF;
		END IF;
	END PROCESS;

	-- Save data in extra output buffers 
	out_buff_generate : FOR I IN 0 TO (PIX_WR - 1) GENERATE
		output_buff_proc : PROCESS (clk)
		BEGIN
			IF rising_edge(clk) THEN
				IF current_state = 0 OR current_state = 1 THEN
					output_buff(I) <= (OTHERS => '0');
				ELSIF (out_buff_EN(I) = '1') THEN
					output_buff(I) <= input_data;
				END IF;
			END IF;
		END PROCESS;

		out_buff_EN_proc : PROCESS (clk, data_valid, pix_wr_counter,
			current_state)
		BEGIN
			IF (data_valid = '1') AND (pix_wr_counter = I)
				AND (downsamp_counter_pixels + 1) = downsampling
				AND (downsamp_counter_lines + 1) = downsampling
				AND (enable_saving = '1') THEN
				out_buff_EN(I) <= '1';
			ELSE
				out_buff_EN(I) <= '0';
			END IF;
		END PROCESS;
	END GENERATE out_buff_generate;

	--Generate Avalon signals
	--write data
	write_data_generate : FOR I IN 0 TO (PIX_WR - 1) GENERATE
		M_writedata(((I + 1) * NUMBER_COMPONENTS * COMPONENT_SIZE - 1)
		DOWNTO (I * NUMBER_COMPONENTS * COMPONENT_SIZE)) <=
		output_buff(I);
	END GENERATE write_data_generate;

	--byteenable
	M_byteenable <= (OTHERS => '1');
	--burstcount
	-- Always single transactions (no burst)
	M_burstcount <= "0000001";
	-- write

	write_proc : PROCESS (clk)
	BEGIN
		IF rising_edge(clk) THEN
			IF current_state = 0 OR current_state = 1 THEN
				av_write <= '0';
			ELSIF out_buff_EN(PIX_WR - 1) = '1' THEN
				av_write <= '1';
			ELSE
				av_write <= '0';
			END IF;
		END IF;
	END PROCESS;

	M_write <= av_write;
	-- address 

	buff_proc : PROCESS (clk)
	BEGIN
		IF rising_edge(clk) THEN
			IF (reset_n = '0' OR stream_reset_n = '0') THEN
				write_buff <= (OTHERS => '0');
				last_buffer <= '0';
			ELSIF current_state = 1 THEN
				--Initialize buffer
				IF mode = SINGLE_SHOT OR (mode = CONTINUOUS AND cont_double_buff = '0') THEN
					IF buffer_select = '0' THEN
						write_buff <= buff0;
						last_buffer <= '0';
					ELSE
						write_buff <= buff1;
						last_buffer <= '1';
					END IF;
				ELSE --mode = CONTINUOUS and cont_double_buff = '1'
					write_buff <= buff0;
					last_buffer <= '1';
				END IF;
			ELSIF av_write = '1' THEN
				IF reset_buffer_address = '1' AND mode = CONTINUOUS AND cont_double_buff = '1' THEN
					IF last_buffer = '1' THEN
						last_buffer <= '0';
						write_buff <= buff1;
					ELSE
						last_buffer <= '1';
						write_buff <= buff0;
					END IF;
				ELSIF reset_buffer_address = '1' AND mode = CONTINUOUS AND cont_double_buff = '0' THEN
					IF last_buffer = '0' THEN
						last_buffer <= '0';
						write_buff <= buff0;
					ELSE
						last_buffer <= '1';
						write_buff <= buff1;
					END IF;
				ELSE
					write_buff <= write_buff + (PIX_WR * NUMBER_COMPONENTS * COMPONENT_SIZE/8);
				END IF;
			END IF;
		END IF;
	END PROCESS;
  
	M_address <= write_buff;
END arch;