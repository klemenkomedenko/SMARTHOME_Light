library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity arbiter is
    port (
        i_clk : in std_logic; --! Clock signal
        i_rst : in std_logic; --! Reset signal, active high
 
        o_addr : out std_logic_vector(7 downto 0); --! Output address bus
        o_we : out std_logic; --! Output write enable signal
        o_wdata : out std_logic_vector(7 downto 0); --! Output write data bus
        i_rdata : in std_logic_vector(7 downto 0); --! Input read data bus

        i_uart_rx_data : in std_logic_vector(7 downto 0); --! Input UART received data bus
        i_uart_rx_vld : in std_logic; --! Input UART received data valid signal

        o_uart_tx_data : out std_logic_vector(7 downto 0); --! Output UART transmit data bus
        o_uart_tx_vld : out std_logic; --! Output UART transmit data valid signal
        i_uart_tx_busy : in std_logic --! Input UART transmit busy signal
        
    );
end entity arbiter;

architecture rtl of arbiter is

    type t_arb_fsm is (IDLE, --! Idle state, waiting for UART data
                      WAIT_CMD, --! Waiting for command from UART
                      WADDR, --! Writing address to memory
                      WLEN, --! Setting write enable signal
                      WDATA, --! Writing data to memory
                      WEOP, --! Ending write operation
                      RADDR, --! Writing address to memory
                      RLEN, --! Setting read enable signal
                      RRPLY, --! Replying with read data to UART
                      RDATA, --! Reading data from memory
                      REOP --! Ending read operation
                      ); --! Writing data to memory
    signal s_arb_fsm, r_arb_fsm : t_arb_fsm := IDLE;

    signal s_wdata_cnt : unsigned(7 downto 0); --! Counter for number of bytes written
    signal r_wdata_cnt : unsigned(7 downto 0); --! Register Counter for number of bytes written
    signal r_wdata_len : unsigned(7 downto 0); --! Register for number of bytes to write
    signal s_wdata_len : unsigned(7 downto 0); --! Counter for number of bytes to write
    signal r_rdata_cnt : unsigned(7 downto 0); --! Register Counter for number of bytes read
    signal s_rdata_cnt : unsigned(7 downto 0); --! Counter for number of bytes read
    signal r_rdata_len : unsigned(7 downto 0); --! Register for number of bytes to read
    signal s_rdata_len : unsigned(7 downto 0); --! Counter for number of bytes to read
    signal r_uart_tx_busy : std_logic; --! Register for UART transmit busy signal
    signal s_fe_uart_tx_busy : std_logic; --! Signal for edge detection of UART transmit busy signal

    signal s_addr : std_logic_vector(7 downto 0); --! Signal for output address bus
    signal r_addr : std_logic_vector(7 downto 0); --! Signal for output address bus
    signal s_we : std_logic; --! Signal for output write enable

begin

    p_uart_tx_busy : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            r_uart_tx_busy <= '0';
        elsif rising_edge(i_clk) then
            r_uart_tx_busy <= i_uart_tx_busy;
        end if;
    end process;
 
    s_fe_uart_tx_busy <= r_uart_tx_busy and not(i_uart_tx_busy);

    p_arb_fsm_sync : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            s_arb_fsm <= IDLE;
        elsif rising_edge(i_clk) then
            s_arb_fsm <= r_arb_fsm;
        end if;
    end process;

    p_arb_fsm : process(r_arb_fsm, i_uart_rx_vld, i_uart_rx_data, i_rdata, i_uart_tx_busy, r_wdata_cnt, r_wdata_len, r_rdata_cnt, r_rdata_len)
    begin
        case r_arb_fsm is
            when IDLE =>
                r_arb_fsm <= WAIT_CMD;

            when WAIT_CMD =>
                if i_uart_rx_data = x"4B" and i_uart_rx_vld = '1' then
                    r_arb_fsm <= WADDR;
                elsif i_uart_rx_data = x"B4" and i_uart_rx_vld = '1' then
                    r_arb_fsm <= RADDR;
                else
                    r_arb_fsm <= WAIT_CMD;
                end if;

            when WADDR =>
                if (i_uart_rx_vld = '1') then
                    r_arb_fsm <= WLEN;
                else
                    r_arb_fsm <= WADDR;
                end if;

            when WLEN =>
                if (i_uart_rx_vld = '1') then
                    r_arb_fsm <= WDATA;
                else
                    r_arb_fsm <= WLEN;
                end if;

            when WDATA =>
                if (i_uart_rx_vld = '1' and r_wdata_cnt = r_wdata_len) then
                    r_arb_fsm <= WEOP;
                else
                    r_arb_fsm <= WDATA;
                end if;

            when WEOP =>
                if (i_uart_rx_vld = '1') then
                    r_arb_fsm <= WAIT_CMD;
                else
                    r_arb_fsm <= WEOP;
                end if;

            when RADDR =>
                if (i_uart_rx_vld = '1') then
                    r_arb_fsm <= RLEN;
                else
                    r_arb_fsm <= RADDR;
                end if;

            when RLEN =>
                if (i_uart_rx_vld = '1') then
                    r_arb_fsm <= RRPLY;
                else
                    r_arb_fsm <= RLEN;
                end if;

            when RRPLY =>
                if s_fe_uart_tx_busy = '1' then
                    r_arb_fsm <= RDATA;
                else
                    r_arb_fsm <= RRPLY;
                end if;

            when RDATA =>
                if (s_fe_uart_tx_busy = '1' and r_rdata_cnt = r_rdata_len) then
                    r_arb_fsm <= REOP;
                else
                    r_arb_fsm <= RDATA;
                end if;

            when REOP =>
                if s_fe_uart_tx_busy = '1' then
                    r_arb_fsm <= WAIT_CMD;
                else
                    r_arb_fsm <= REOP;
                end if;
            
            when others =>
                r_arb_fsm <= IDLE;
        end case;
    end process;

    p_arb_fsm_mux : process(r_arb_fsm, i_uart_rx_vld, i_uart_rx_data, i_rdata, i_uart_tx_busy, r_wdata_cnt, r_wdata_len,
                            r_rdata_cnt, r_rdata_len, r_addr)
    begin
        s_wdata_len <= r_wdata_cnt;
        s_wdata_cnt <= r_wdata_len;
        s_rdata_len <= r_rdata_cnt;
        s_rdata_cnt <= r_rdata_len;
        s_addr <= r_addr;
        s_we <= '0';
        case r_arb_fsm is
            when IDLE =>

            when WAIT_CMD =>

            when WADDR =>
                s_addr <= i_uart_rx_data;

            when WLEN =>
                s_wdata_len <= unsigned(i_uart_rx_data);

            when WDATA =>
                if (i_uart_rx_vld = '1') then
                    s_wdata_cnt <= r_wdata_cnt + 1;
                else 
                    s_wdata_cnt <= r_wdata_cnt;
                end if;

            when WEOP =>

            when RADDR =>
                s_addr <= i_uart_rx_data;

            when RLEN =>
                s_rdata_len <= unsigned(i_uart_rx_data);

            when RRPLY =>

            when RDATA =>

            when REOP =>
        end case;
    end process;

    p_arb_fsm_output : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
             r_wdata_cnt <= (others => '0');
             r_wdata_len <= (others => '0');
             r_rdata_cnt <= (others => '0');
             r_rdata_len <= (others => '0');
             r_addr <= (others => '0');
        elsif rising_edge(i_clk) then
             r_wdata_cnt <= s_wdata_cnt;
             r_wdata_len <= s_wdata_len;
             r_rdata_cnt <= s_rdata_cnt;
             r_rdata_len <= s_rdata_len;
             r_addr <= s_addr;
        end if;
    end process;

end architecture;