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
--    Package with API for DIO agent.
--
--------------------------------------------------------------------------------
-- Revision History:
--    20.6.2026   Created file
--------------------------------------------------------------------------------

library ctu_can_agents;
context ctu_can_agents.ieee_context;
context ctu_can_agents.agents_deps_context;

package dio_agent_pkg is

    ---------------------------------------------------------------------------
    -- Interrupt agent component
    ---------------------------------------------------------------------------
    component dio_agent is
    generic (
        G_COM_ID        :         natural
    );
    port (
        dio             :   inout std_logic
    );
    end component;

    ---------------------------------------------------------------------------
    -- Message print helpers
    ---------------------------------------------------------------------------
    procedure dio_agent_info_m(
        constant    id          : in    natural;
        constant    msg         : in    string
    );

    procedure dio_agent_debug_m(
        constant    id          : in    natural;
        constant    msg         : in    string
    );

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Interrupt agent API
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------

    ---------------------------------------------------------------------------
    -- Drive value on IO pin
    --
    -- @param channel   Channel where to send the request
    -- @param id        Agent ID on the communication channel
    -- @param value     Value to drive on the the IO pin
    ---------------------------------------------------------------------------
    procedure dio_agent_drive(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    value       : in    std_logic
    );

    ---------------------------------------------------------------------------
    -- Release driver of an IO pin
    --
    -- @param channel   Channel where to send the request
    -- @param id        Agent ID on the communication channel
    ---------------------------------------------------------------------------
    procedure dio_agent_relase(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    );

    ---------------------------------------------------------------------------
    -- Sense value of an IO pin
    --
    -- @param channel   Channel where to send the request
    -- @param id        Agent ID on the communication channel
    -- @param value     Output variable where to store the pin value.
    ---------------------------------------------------------------------------
    procedure dio_agent_sense(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    value       : out   std_logic
    );

    ---------------------------------------------------------------------------
    -- Check value of an IO pin, throw an error if not as expected.
    --
    -- @param channel   Channel where to send the request
    -- @param id        Agent ID on the communication channel
    -- @param value     Expected pin value
    ---------------------------------------------------------------------------
    procedure dio_agent_check(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    value       : in    std_logic
    );

    ---------------------------------------------------------------------------
    -- Wait until DIO pin has a value (with optional timeout).
    -- Filters glitches shorter than
    --
    -- @param channel   Channel where to send the request
    -- @param value     Value to wait for
    -- @param id        Agent ID on the communication channel
    -- @param timeout   Wait timeout - 0 ns means indefinitely
    ---------------------------------------------------------------------------
    procedure dio_agent_wait_until_value(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    value       : in    std_logic;
        constant    timeout     : in    time := 0 ns
    );

    ---------------------------------------------------------------------------
    -- Wait until rising edge on DIO pin (with optional timeout)
    --
    -- @param channel   Channel where to send the request
    -- @param value     Value to wait for
    -- @param id        Agent ID on the communication channel
    -- @param timeout   Wait timeout - 0 ns means indefinitely
    ---------------------------------------------------------------------------
    procedure dio_agent_wait_rising_edge(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    timeout     : in    time := 0 ns
    );

    ---------------------------------------------------------------------------
    -- Wait until falling edge on DIO pin (with optional timeout)
    --
    -- @param channel   Channel where to send the request
    -- @param value     Value to wait for
    -- @param id        Agent ID on the communication channel
    -- @param timeout   Wait timeout - 0 ns means indefinitely
    ---------------------------------------------------------------------------
    procedure dio_agent_wait_falling_edge(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    timeout     : in    time := 0 ns
    );


    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Private declarations
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------

    -- Supported commands
    constant DIO_AGENT_CMD_DRIVE_VALUE                  : integer := 0;
    constant DIO_AGENT_CMD_RELEASE_VALUE                : integer := 1;
    constant DIO_AGENT_CMD_SENSE_VALUE                  : integer := 2;
    constant DIO_AGENT_CMD_CHECK_VALUE                  : integer := 3;
    constant DIO_AGENT_CMD_WAIT_UNTIL_VALUE             : integer := 4;
    constant DIO_AGENT_CMD_WAIT_UNTIL_RISING_EDGE       : integer := 5;
    constant DIO_AGENT_CMD_WAIT_UNTIL_FALLING_EDGE      : integer := 6;

    -- Tag for messages
    constant DIO_AGENT_TAG : string := "DIO Agent: ";

end package;


package body dio_agent_pkg is

    ---------------------------------------------------------------------------
    -- Message print helpers
    ---------------------------------------------------------------------------
    procedure dio_agent_info_m(
        constant    id          : in    natural;
        constant    msg         : in    string
    ) is
    begin
        info_m(DIO_AGENT_TAG & "(" & natural'image(id) & "): " & msg);
    end procedure;

    procedure dio_agent_debug_m(
        constant    id          : in    natural;
        constant    msg         : in    string
    )  is
    begin
        debug_m(DIO_AGENT_TAG & "(" & natural'image(id) & "): " & msg);
    end procedure;

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- DIO agent API
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Interrupt agent API
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------

    procedure dio_agent_drive(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    value       : in    std_logic
    ) is
    begin
        dio_agent_info_m(id,  "Driving value: " & std_logic'image(value));
        com_channel_data.set_param(value);
        send(channel, id, DIO_AGENT_CMD_DRIVE_VALUE);
        dio_agent_debug_m(id, "Value driven");
    end procedure;

    procedure dio_agent_relase(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    ) is
    begin
        dio_agent_info_m(id,  "Releasing driver");
        send(channel, id, DIO_AGENT_CMD_RELEASE_VALUE);
        dio_agent_debug_m(id, "Driver released");
    end procedure;

    procedure dio_agent_sense(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    value       : out   std_logic
    ) is
    begin
        dio_agent_info_m(id,  "Sensing value");
        send(channel, id, DIO_AGENT_CMD_SENSE_VALUE);
        value := com_channel_data.get_param;
        dio_agent_debug_m(id, "Value sensed: " & std_logic'image(value));
    end procedure;

    procedure dio_agent_check(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    value       : in    std_logic
    ) is
    begin
        dio_agent_info_m(id,  "Checking value: " & std_logic'image(value));
        com_channel_data.set_param(value);
        send(channel, id, DIO_AGENT_CMD_CHECK_VALUE);
        dio_agent_debug_m(id, "Value checked");
    end procedure;

    procedure dio_agent_wait_until_value(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    value       : in    std_logic;
        constant    timeout     : in    time := 0 ns
    ) is
    begin
        if (timeout > 0 ns) then
            dio_agent_info_m(id, "Waiting until value: " & std_logic'image(value));
        else
            dio_agent_info_m(id, "Waiting until value: " & std_logic'image(value) &
                                 "for " & time'image(timeout));
        end if;
        com_channel_data.set_param(value);
        com_channel_data.set_param(timeout);
        send(channel, id, DIO_AGENT_CMD_WAIT_UNTIL_VALUE);
        dio_agent_debug_m(id, "Waiting finished");
    end procedure;

    procedure dio_agent_wait_rising_edge(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    timeout     : in    time := 0 ns
    ) is
    begin
        if (timeout > 0 ns) then
            dio_agent_info_m(id, "Waiting until rising edge");
        else
            dio_agent_info_m(id, "Waiting until rising edge " &
                                 "for " & time'image(timeout));
        end if;
        com_channel_data.set_param(timeout);
        send(channel, id, DIO_AGENT_CMD_WAIT_UNTIL_RISING_EDGE);
        dio_agent_debug_m(id, "Waiting finished");
    end procedure;

    procedure dio_agent_wait_falling_edge(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    timeout     : in    time := 0 ns
    ) is
    begin
        if (timeout > 0 ns) then
            dio_agent_info_m(id, "Waiting until falling edge");
        else
            dio_agent_info_m(id, "Waiting until falling edge " &
                                 "for " & time'image(timeout));
        end if;
        com_channel_data.set_param(timeout);
        send(channel, id, DIO_AGENT_CMD_WAIT_UNTIL_FALLING_EDGE);
        dio_agent_debug_m(id, "Waiting finished");
    end procedure;

end package body;
