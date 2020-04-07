library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_rot_banner is
	port(
		clk, reset : in std_logic;
		video_on : in std_logic;
		btn : in std_logic_vector(2 downto 0);
		sw : in std_logic_vector(6 downto 0);
		pixel_x, pixel_y : in std_logic_vector(9 downto 0);
		text_rgb : out std_logic_vector(2 downto 0)
	);
end vga_rot_banner;

architecture arch of vga_rot_banner is
	-- font ROM
	signal rom_addr : std_logic_vector(10 downto 0);
	signal char_addr : std_logic_vector(6 downto 0);
	signal row_addr : std_logic_vector(3 downto 0);
	signal bit_addr : unsigned(2 downto 0);
	signal font_word : std_logic_vector(7 downto 0);
	signal font_bit : std_logic;
	--shift signals
	signal refr_tick : std_logic;
	signal shift_reg, shift_next : unsigned(4 downto 0);
	signal count_reg, count_next : unsigned(22 downto 0);
	--tile RAM
	signal we : std_logic;
	signal addr_r, addr_w : std_logic_vector(7 downto 0);
	signal din, dout : std_logic_vector(6 downto 0);
	
	--40 by 15 tile map
	constant MAX_X : integer := 20;
	constant MAX_Y : integer := 8;
	
	--delayed pixel count
	signal pix_x1_reg, pix_y1_reg : unsigned(9 downto 0);
	signal pix_x2_reg, pix_y2_reg : unsigned(9 downto 0);
	
	--object output colour
	signal font_rgb: std_logic_vector(2 downto 0);
	signal text_on : std_logic;
begin
	-- instantiate font ROM
	font_unit : entity work.font_rom
		port map(clk => clk, addr => rom_addr, data => font_word);
		
	video_ram : entity work.altera_dual_port_ram_sync
		generic map(ADDR_WIDTH => 8, DATA_WIDTH => 7)
		port map(clk => clk, we => '1', addr_a => addr_w, 
					addr_b => addr_r, din_a => din, dout_a => open, 
					dout_b => dout);
					
	count_next <= count_reg + 1;
	shift_next <= shift_reg + 1 when count_reg = 0 else
					  shift_reg;
	--registers
	process(clk)
	begin
		if(clk'event and clk = '1') then
			pix_x1_reg <= unsigned(pixel_x);
			pix_x2_reg <= pix_x1_reg;
			pix_y1_reg <= unsigned(pixel_y);
			pix_y2_reg <= pix_y1_reg;
			shift_reg <= shift_next;
			count_reg <= count_next;
		end if;
	end process;
	addr_w <= pixel_y(8 downto 6) & pixel_x(9 downto 5);
	-- tile RAM read
	addr_r <= pixel_y(8 downto 6) & pixel_x(9 downto 5);
	char_addr <= dout;
	-- font_ROM
	row_addr <= pixel_y(5 downto 2);
	rom_addr <= char_addr & row_addr;
	bit_addr <= pix_x2_reg(4 downto 2);
	font_bit <= font_word(to_integer(not bit_addr));
	text_on <= '1' when pixel_y(8 downto 6) = "011" else
				  '0';
	--green text on black screen
	font_rgb <= "010" when font_bit = '1' else "000";
	
	din <= "1001000" when unsigned(pixel_x(9 downto 5)) =  "00000" - shift_reg else--H
			 "1100101" when unsigned(pixel_x(9 downto 5)) =  "00001" - shift_reg else--e
			 "1101100" when unsigned(pixel_x(9 downto 5)) =  "00010" - shift_reg else--l
			 "1101100" when unsigned(pixel_x(9 downto 5)) =  "00011" - shift_reg else--l
			 "1101111" when unsigned(pixel_x(9 downto 5)) =  "00100" - shift_reg else--o
			 "0101100" when unsigned(pixel_x(9 downto 5)) =  "00101" - shift_reg else--,
			 "0000000" when unsigned(pixel_x(9 downto 5)) =  "00110" - shift_reg else--
			 "1000110" when unsigned(pixel_x(9 downto 5)) =  "00111" - shift_reg else--F
			 "1010000" when unsigned(pixel_x(9 downto 5)) =  "01000" - shift_reg else--P
			 "1000111" when unsigned(pixel_x(9 downto 5)) =  "01001" - shift_reg else--G
			 "1000001" when unsigned(pixel_x(9 downto 5)) =  "01010" - shift_reg else--A
			 "0000000" when unsigned(pixel_x(9 downto 5)) =  "01011" - shift_reg else--
			 "1010111" when unsigned(pixel_x(9 downto 5)) =  "01100" - shift_reg else--W
			 "1101111" when unsigned(pixel_x(9 downto 5)) =  "01101" - shift_reg else--o
			 "1110010" when unsigned(pixel_x(9 downto 5)) =  "01110" - shift_reg else--r
			 "1101100" when unsigned(pixel_x(9 downto 5)) =  "01111" - shift_reg else--l
			 "1100100" when unsigned(pixel_x(9 downto 5)) =  "10000" - shift_reg else--d
			 "0101110" when unsigned(pixel_x(9 downto 5)) =  "10001" - shift_reg else--.
			 "0000000";
				 

	process(video_on, font_rgb)
	begin
		if video_on = '0' then
			text_rgb <= "000";
		else
			if text_on = '1' then
				text_rgb <= font_rgb;
			end if;
		end if;
	end process;
end arch;