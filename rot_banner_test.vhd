library ieee;
use ieee.std_logic_1164.all;
entity rot_banner_test is
	port(
		CLOCK_50 : in std_logic;
		KEY            : in std_logic_vector(3 downto 0);
		SW             : in std_logic_vector(6 downto 0);
		VGA_HS, VGA_VS : out std_logic;	
		VGA_R, VGA_B, VGA_G : out std_logic_vector(2 downto 0)
	);
end rot_banner_test;

architecture arch of rot_banner_test is
	signal pixel_x, pixel_y : std_logic_vector(9 downto 0);
	signal video_on, pixel_tick : std_logic;
	signal rgb_reg, rgb_next : std_logic_vector(2 downto 0);
begin
	vga_sync_unit : entity work.vga_sync
		port map(clk => CLOCK_50, reset => not(KEY(0)),
					vsync => VGA_VS, hsync => VGA_HS, video_on => video_on,
					p_tick => pixel_tick, pixel_x => pixel_x, pixel_y => pixel_y);
	rot_banner_unit : entity work.vga_rot_banner
		port map(clk => CLOCK_50, reset => not(KEY(0)), btn => not(KEY(3 downto 1)), sw => SW,
					video_on => video_on, pixel_x => pixel_x, pixel_y => pixel_y,
					text_rgb => rgb_next);
	process(CLOCK_50)
	begin
		if(CLOCK_50'event and CLOCK_50 = '1') then
			if(pixel_tick = '1') then
				rgb_reg <= rgb_next;
			end if;
		end if;
	end process;
	VGA_R <= (others => rgb_reg(2));
	VGA_G <= (others => rgb_reg(1));
	VGA_B <= (others => rgb_reg(0));
end arch;
		