--------------------------------------------------------------------------------
--
-- CTU CAN FD IP Core
-- Copyright (C) 2021-2023 Ondrej Ille
-- Copyright (C) 2023-     Logic Design Services Ltd.s
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this VHDL component and associated documentation files (the "Component"),
-- to use, copy, modify, merge, publish, distribute the Component for
-- non-commercial purposes. Using the Component for commercial purposes is
-- forbidden unless previously agreed with Copyright holder.
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Component.
--
-- THE COMPONENT IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHTHOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE COMPONENT OR THE USE OR OTHER DEALINGS
-- IN THE COMPONENT.
--
-- The CAN protocol is developed by Robert Bosch GmbH and protected by patents.
-- Anybody who wants to implement this IP core on silicon has to obtain a CAN
-- protocol license from Bosch.
--
-- -------------------------------------------------------------------------------
--
-- CTU CAN FD IP Core
-- Copyright (C) 2015-2020 MIT License
--
-- Authors:
--     Ondrej Ille <ondrej.ille@gmail.com>
--     Martin Jerabek <martin.jerabek01@gmail.com>
--
-- Project advisors:
-- 	Jiri Novak <jnovak@fel.cvut.cz>
-- 	Pavel Pisa <pisa@cmp.felk.cvut.cz>
--
-- Department of Measurement         (http://meas.fel.cvut.cz/)
-- Faculty of Electrical Engineering (http://www.fel.cvut.cz)
-- Czech Technical University        (http://www.cvut.cz/)
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this VHDL component and associated documentation files (the "Component"),
-- to deal in the Component without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Component, and to permit persons to whom the
-- Component is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Component.
--
-- THE COMPONENT IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHTHOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE COMPONENT OR THE USE OR OTHER DEALINGS
-- IN THE COMPONENT.
--
-- The CAN protocol is developed by Robert Bosch GmbH and protected by patents.
-- Anybody who wants to implement this IP core on silicon has to obtain a CAN
-- protocol license from Bosch.
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--  @Purpose:
--    Clock generator agent.

--    Clock generator agent generates clock (whoooa thats surprise right).
--
--    Clock generator agent only generates clock when it is enabled. When it is
--    disabled, its clock output remains in value which clock output had at
--    time when it was disabled.
--
--    Clock generator agent has following configurable parameters:
--      Clock period        Obvious who does not know what clock period is should
--                          not be reading this text.
--      Jitter              Cycle to cycle jitter. Each clock cycle can last:
--                          period +- "rand_val"  where "rand_val" is less than
--                          or equal to jitter.
--      Duty cycle          Again, obvious, if you don't know what duty cycle
--                          is, seriously, stop reading!
--
--------------------------------------------------------------------------------
-- Revision History:
--    19.1.2020   Created file
--    04.2.2021   Adjusted to work without Vunits COM library.
--    20.7.2026   Added G_COM_ID.
--------------------------------------------------------------------------------

library ctu_can_agents;
context ctu_can_agents.ieee_context;
context ctu_can_agents.agents_deps_context;

use ctu_can_agents.clock_agent_pkg.all;

entity clock_agent is
    generic (
        G_COM_ID                : natural := C_CAN_AGENT_DEF_ID
    );
    port (
        -- Generated clock output
        clock_out   :   out std_logic := '0';
        clock_in    :   in  std_logic
    );
end entity;

architecture tb of clock_agent is

    ---------------------------------------------------------------------------
    -- Parameters configured over communication library
    ---------------------------------------------------------------------------

    -- Clock generator is enabled, clocks are being generated!
    -- Note: This must be enabled by default when testbench is controlled from
    --       SW, otherwise simulator will run out of events and timeout!
    signal enabled          :    boolean := false;

    -- Generated clock period
    signal period           :    time := 10 ns;

    -- Duty cycle of generated clock (in %)
    signal duty             :    integer range 0 to 100 := 50;

    -- Jitter of generated clock (short time -> cycle to cycle)
    signal jitter           :    time := 1 fs;

    -- High / Low times
    signal t_low            :    time;
    signal t_high           :    time;

    procedure recalc_parameters(
        p_period            :   in  time;
        p_duty              :   in  integer range 0 to 100;
        signal p_t_low      :   out time;
        signal p_t_high     :   out time
    )is
    begin
       p_t_low  <= p_period * (real(p_duty) / 100.0);
       p_t_high <= p_period * (1.0 - (real(p_duty) / 100.0));
    end;

begin

    ---------------------------------------------------------------------------
    -- Comunication receiver process
    ---------------------------------------------------------------------------
    p_receiver : process
        variable token : natural;
        variable cmd : integer;
        variable reply_code : integer;
        variable com_data : t_com_data;
    begin
        receive_start(default_channel, G_COM_ID, token, cmd, com_data);

        reply_code := C_REPLY_CODE_OK;

        case cmd is
        when CLOCK_AGNT_CMD_START =>
            enabled <= true;

        when CLOCK_AGNT_CMD_STOP =>
            enabled <= false;

        when CLOCK_AGNT_CMD_PERIOD_SET =>
            period <= get_param(com_data);
            recalc_parameters(period, duty, t_low, t_high);

        when CLOCK_AGNT_CMD_PERIOD_GET =>
            set_param(com_data, period);

        when CLOCK_AGNT_CMD_JITTER_SET =>
            jitter <= get_param(com_data);

        when CLOCK_AGNT_CMD_JITTER_GET =>
            set_param(com_data, jitter);

        when CLOCK_AGNT_CMD_DUTY_SET =>
            duty <= get_param(com_data);
            recalc_parameters(period, duty, t_low, t_high);

        when CLOCK_AGNT_CMD_DUTY_GET =>
            set_param(com_data, duty);

        when CLOCK_AGNT_CMD_WAIT_CYCLE =>
            wait until rising_edge(clock_in) for 1 us;

        when others =>
            reply_code := C_REPLY_CODE_ERR;
        end case;

        receive_finish(default_channel, token, reply_code, com_data);
    end process;


    ---------------------------------------------------------------------------
    -- Clock generation process
    ---------------------------------------------------------------------------
    p_clk_gen : process
        variable t_high_with_jitter : time;
        variable t_low_with_jitter : time;
        variable rand_real : real;
        variable rand_jitter : time;
        variable seed1 : positive := 1;
        variable seed2 : positive := 1;
        variable jitter_div_2 : time;
    begin
        if (enabled) then

            if (jitter > 0 fs) then
                uniform(seed1, seed2, rand_real);
                rand_jitter := jitter * rand_real;
                jitter_div_2 := jitter / 2;
                t_high_with_jitter := (period + rand_jitter - jitter_div_2) * (real(duty) / 100.0);
                t_low_with_jitter := (period + rand_jitter - jitter_div_2) * (1.0 - (real(duty) / 100.0));

                clock_out <= '1';
                wait for t_high_with_jitter;
                clock_out <= '0';
                wait for t_low_with_jitter;
            else
                clock_out <= '1';
                wait for t_high;
                clock_out <= '0';
                wait for t_low;
            end if;
        else
            wait until enabled;
        end if;
    end process;

end architecture;