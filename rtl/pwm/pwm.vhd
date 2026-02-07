library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity pwm is
    port (
        i_clk   : in std_logic; --! Clock signal
        i_rst : in std_logic; --! Reset signal, active high

        i_beat : in std_logic; --! Input beat signal for timing control
        i_init_dim : in std_logic_vector(7 downto 0); --! Input initial dimming value
        i_en_pwm : in std_logic; --! Input PWM enable signal
        i_inc_pwm : in std_logic; --! Input PWM increment signal
        i_dec_pwm : in std_logic; --! Input PWM decrement signal

        o_pwm : out std_logic
       
    );
end entity pwm;

architecture rtl of pwm is

    signal r_en_pwm : std_logic; --! Register for PWM enable signal
    signal r_pwm_cnt_limit : unsigned(7 downto 0); --! Signal for current dimming value
    signal r_pwm_cnt : unsigned(7 downto 0); --! Signal for current dimming value
    signal r_pwm : std_logic; --! Register for PWM output signal

begin

    o_en_pwm : process(i_clk, i_rst)
    begin
        if (i_rst = '1') then
            r_en_pwm <= '0';
        elsif rising_edge(i_clk) then
            r_en_pwm <= i_en_pwm; -- Output the PWM enable signal
        end if;
    end process;

    p_pwm_cnt_limit : process(i_clk, i_rst)
    begin
        if (i_rst = '1') then
            r_pwm_cnt_limit <= (others => '0');
        elsif rising_edge(i_clk) then
            if (i_en_pwm = '1') then
                if (r_en_pwm = '0') then -- set initial dimming value on enable
                    r_pwm_cnt_limit <= to_unsigned(to_integer(unsigned(i_init_dim)), r_pwm_cnt_limit'length);
                else
                    if (i_inc_pwm = '1' and r_pwm_cnt_limit < to_unsigned(255, r_pwm_cnt_limit'length)) then
                        r_pwm_cnt_limit <= r_pwm_cnt_limit + 1;
                    elsif (i_dec_pwm = '1' and r_pwm_cnt_limit > to_unsigned(0, r_pwm_cnt_limit'length)) then
                        r_pwm_cnt_limit <= r_pwm_cnt_limit - 1;
                    else
                        r_pwm_cnt_limit <= r_pwm_cnt_limit;
                    end if;
                end if;
            else -- PWM disabled
                r_pwm_cnt_limit <= (others => '0');
            end if;
        end if;
    end process;

    p_pwm_cnt : process(i_clk, i_rst)
    begin
        if (i_rst = '1') then
            r_pwm_cnt <= (others => '0');
        elsif rising_edge(i_clk) then
            if (i_en_pwm = '1') then
                if (i_beat = '1') then
                    if (r_pwm_cnt = to_unsigned(255, r_pwm_cnt'length)) then
                        r_pwm_cnt <= (others => '0');
                    else
                        r_pwm_cnt <= r_pwm_cnt + 1;
                    end if;
                else
                    r_pwm_cnt <= r_pwm_cnt;
                end if;
            else -- If PWM is disabled, reset the counter
                r_pwm_cnt <= (others => '0');
            end if;
        end if;
    end process;

    p_pwm : process(i_clk, i_rst)
    begin
        if (i_rst = '1') then
            r_pwm <= '0';
        elsif rising_edge(i_clk) then
            if (r_pwm_cnt = to_unsigned(0, r_pwm_cnt'length)) then
                r_pwm <= '1';
            elsif (r_pwm_cnt = r_pwm_cnt_limit) then
                r_pwm <= '0';
            else
                r_pwm <= r_pwm;
            end if;
        end if;
    end process;

    o_pwm <= r_pwm; -- Output PWM signal based on current dimming value
    

end architecture;