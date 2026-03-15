library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity top is    
    generic (
        g_CLK_FREQ    : integer := 22_500_000; --! Define clock frequency 22.5 MHz 
        g_BAUD_RATE   : integer := 1_000_000;  --! BAUDRATE of UART protocole 1 Mbps
        g_BEAT_FREQ   : integer := 1_000  --! Beat frequency for PWM timing control 1 kHz
    );
    port (
        i_rx : in std_logic;
        o_tx : out std_logic;

        o_pwm : out std_logic_vector(63 downto 0)
        
    );
end entity top;

architecture rtl of top is
    signal s_clk_osc : std_logic; 
    signal s_clk_pll : std_logic; 
    signal s_clk_pll_lock : std_logic; 
    signal r_rst : std_logic_vector(7 downto 0);

    signal s_rx_data : std_logic_vector(7 downto 0); --! Signal for UART received data
    signal s_tx_data : std_logic_vector(7 downto 0); --! Signal for UART transmited data
    signal s_rx_vld : std_logic;
    signal s_tx_start : std_logic;
    signal s_tx_busy : std_logic;

    signal s_addr : std_logic_vector(7 downto 0);
    signal s_we : std_logic;
    signal s_wdata : std_logic_vector(7 downto 0);
    signal s_rdata : std_logic_vector(7 downto 0);

    signal s_init_dim : std_logic_vector(15 downto 0);
    signal s_en_pwm : std_logic_vector(63 downto 0);
    signal s_inc_pwm : std_logic_vector(63 downto 0);
    signal s_dec_pwm : std_logic_vector(63 downto 0);
    signal s_beat : std_logic;



    
    component clk_osc is
        port(
            hf_out_en_i: in std_logic;
            hf_clk_out_o: out std_logic
        );
    end component;

    component clk_pll is
        port(
            clki_i: in std_logic;
            clkop_o: out std_logic;
            lock_o: out std_logic
        );
    end component;

begin

    u_clk_osc : clk_osc port map(
        hf_out_en_i=> '1',
        hf_clk_out_o=> s_clk_osc
    );

    u_clk_pll : clk_pll port map(
        clki_i=> s_clk_osc,
        clkop_o=> s_clk_pll,
        lock_o=> s_clk_pll_lock
    );

    p_rst : process(s_clk_pll, s_clk_pll_lock)
    begin
        if s_clk_pll_lock = '0' then
            r_rst <= (others => '1');
        elsif rising_edge(s_clk_pll) then
            r_rst <= r_rst(r_rst'high - 1 downto 0) &'0';
        end if;
    end process;

    uart_inst : entity work.uart
    generic map (
        g_CLK_FREQ => g_CLK_FREQ,
        g_BAUD_RATE => g_BAUD_RATE
    )
    port map (
        i_clk => s_clk_pll,
        i_rst => r_rst(r_rst'high),
        i_rx => i_rx,
        o_tx => o_tx,
        o_rx_data => s_rx_data,
        o_rx_vld => s_rx_vld,
        i_tx_data => s_tx_data,
        i_tx_start => s_tx_start,
        o_tx_busy => s_tx_busy
    );

    arbiter_inst : entity work.arbiter
    port map (
        i_clk => s_clk_pll,
        i_rst => r_rst(r_rst'high),
        o_addr => s_addr,
        o_we => s_we,
        o_wdata => s_wdata,
        i_rdata => s_rdata,
        i_uart_rx_data => s_rx_data,
        i_uart_rx_vld => s_rx_vld,
        o_uart_tx_data => s_tx_data,
        o_uart_tx_vld => s_tx_start,
        i_uart_tx_busy => s_tx_busy
    );

    reg_inst : entity work.reg
    port map (
        i_clk => s_clk_pll,
        i_rst => r_rst(r_rst'high),
        i_addr => s_addr,
        i_we => s_we,
        i_wdata => s_wdata,
        o_rdata => s_rdata,
        o_init_dim => s_init_dim,
        o_en_pwm => s_en_pwm,
        o_inc_pwm => s_inc_pwm,
        o_dec_pwm => s_dec_pwm
    );

    gen_pwm : for i in 0 to 63 generate
        pwm_inst : entity work.pwm
        port map (
            i_clk => s_clk_pll,
            i_rst => r_rst(r_rst'high),
            i_beat => s_beat,
            i_init_dim => s_init_dim(7 downto 0),
            i_en_pwm => s_en_pwm(i),
            i_inc_pwm => s_inc_pwm(i),
            i_dec_pwm => s_dec_pwm(i),
            o_pwm => o_pwm(i)
        );
    end generate;

    beat_inst : entity work.beat
    generic map (
        g_CLK_FREQ => g_CLK_FREQ,
        g_BEAT_FREQ => g_BEAT_FREQ
    )
    port map (
        i_clk => s_clk_pll,
        i_rst => r_rst(r_rst'high),
        o_beat => s_beat
    );



end architecture rtl;