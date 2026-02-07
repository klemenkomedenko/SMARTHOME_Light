
# Entity: pwm 
- **File**: pwm.vhd

## Diagram
![Diagram](pwm.svg "Diagram")
## Ports

| Port name  | Direction | Type                         | Description                          |
| ---------- | --------- | ---------------------------- | ------------------------------------ |
| i_clk      | in        | std_logic                    | Clock signal                         |
| i_rst      | in        | std_logic                    | Reset signal, active high            |
| i_beat     | in        | std_logic                    | Input beat signal for timing control |
| i_init_dim | in        | std_logic_vector(7 downto 0) | Input initial dimming value          |
| i_en_pwm   | in        | std_logic                    | Input PWM enable signal              |
| i_inc_pwm  | in        | std_logic                    | Input PWM increment signal           |
| i_dec_pwm  | in        | std_logic                    | Input PWM decrement signal           |
| o_pwm      | out       | std_logic                    |                                      |

## Signals

| Name            | Type                 | Description                      |
| --------------- | -------------------- | -------------------------------- |
| r_en_pwm        | std_logic            | Register for PWM enable signal   |
| r_pwm_cnt_limit | unsigned(7 downto 0) | Signal for current dimming value |
| r_pwm_cnt       | unsigned(7 downto 0) | Signal for current dimming value |
| r_pwm           | std_logic            |                                  |

## Processes
- o_en_pwm: ( i_clk, i_rst )
- p_pwm_cnt_limit: ( i_clk, i_rst )
- p_pwm_cnt: ( i_clk, i_rst )
- p_pwm: ( i_clk, i_rst )
