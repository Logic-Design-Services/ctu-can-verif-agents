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
--    Digital input output agent.
--
--    Allows driving and monitoring single pin buses of arbitrary functionality.
--    Supports following function:
--      - Drive value, Release value (goes to Hi-Z)
--      - Sense value
--      - Check value
--      - Wait for value (optionally with timeout)
--
--------------------------------------------------------------------------------
-- Revision History:
--    20.7.2026   Created file
--------------------------------------------------------------------------------

library ctu_can_agents;
context ctu_can_agents.ieee_context;
context ctu_can_agents.agents_deps_context;

use ctu_can_agents.dio_agent_pkg.all;

entity dio_agent is
    generic(
        G_COM_ID                :       natural
    );
    port (
        dio                     : inout std_logic
    );
end entity;

architecture tb of dio_agent is

begin

    ---------------------------------------------------------------------------
    -- Comunication receiver process
    ---------------------------------------------------------------------------
    p_receiver : process
        variable cmd        : integer;
        variable reply_code : integer;
        variable timeout    : time;
        variable data       : std_logic;
    begin
        receive_start(default_channel, G_COM_ID);

        -- Command is sent as message type
        cmd := com_channel_data.get_msg_code;
        reply_code := C_REPLY_CODE_OK;

        case cmd is
        when DIO_AGENT_CMD_DRIVE_VALUE =>
            dio <= com_channel_data.get_param;

        when DIO_AGENT_CMD_RELEASE_VALUE =>
            dio <= 'Z';

        when DIO_AGENT_CMD_SENSE_VALUE =>
            com_channel_data.set_param(dio);

        when DIO_AGENT_CMD_CHECK_VALUE =>
            data := com_channel_data.get_param;
            check_m(dio = data, DIO_AGENT_TAG & "(" & integer'image(G_COM_ID) & "): " &
                          "Value mismatch. " & "Expected: " & std_logic'image(data) &
                                              " Observed: " & std_logic'image(dio));

        when DIO_AGENT_CMD_WAIT_UNTIL_VALUE =>
            timeout := com_channel_data.get_param;
            data := com_channel_data.get_param;
            if (timeout > 0 ns) then
                wait until dio = data for timeout;
            else
                wait until dio = data;
            end if;

        when DIO_AGENT_CMD_WAIT_UNTIL_RISING_EDGE =>
            timeout := com_channel_data.get_param;
            if (timeout > 0 ns) then
                wait until rising_edge(dio) for timeout;
            else
                wait until rising_edge(dio);
            end if;

        when DIO_AGENT_CMD_WAIT_UNTIL_FALLING_EDGE =>
            if (timeout > 0 ns) then
                wait until falling_edge(dio) for timeout;
            else
                wait until falling_edge(dio);
            end if;

        when others =>
            info_m("Invalid message type: " & integer'image(cmd));
            reply_code := C_REPLY_CODE_ERR;

        end case;

        receive_finish(default_channel, reply_code);
    end process;

end architecture;