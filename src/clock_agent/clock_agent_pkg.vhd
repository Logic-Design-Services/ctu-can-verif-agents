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
--    Package with API for Clock agent.
--
--------------------------------------------------------------------------------
-- Revision History:
--    19.1.2020   Created file
--    04.2.2021   Adjusted to work without Vunits COM library.
--    20.7.2026   Added configurable ID.
--------------------------------------------------------------------------------

library ctu_can_agents;
context ctu_can_agents.ieee_context;
context ctu_can_agents.agents_deps_context;

package clock_agent_pkg is

    ---------------------------------------------------------------------------
    -- Clock generator component
    ---------------------------------------------------------------------------
    component clock_agent is
    generic (
        G_COM_ID                : natural := C_CAN_AGENT_DEF_ID
    );
    port (
        -- Generated clock output
        clock_out   :   out std_logic := '0';
        clock_in    :   in  std_logic
    );
    end component;

    ---------------------------------------------------------------------------
    -- Message print helpers
    ---------------------------------------------------------------------------
    procedure clock_agent_info_m(
        constant    id          : in    natural;
        constant    msg         : in    string
    );

    procedure clock_agent_debug_m(
        constant    id          : in    natural;
        constant    msg         : in    string
    );

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Clock generator agent API
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------

    ---------------------------------------------------------------------------
    -- Start clock generator agent.
    --
    -- @param channel   Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure clock_agent_start(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    );

    ---------------------------------------------------------------------------
    -- Stop clock generator agent.
    --
    -- @param channel   Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure clock_agent_stop(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    );

    ---------------------------------------------------------------------------
    -- Set clock period of clock generator agent.
    --
    -- @param channel   Channel on which to send the request
    -- @param period    Clock period to be set.
    ---------------------------------------------------------------------------
    procedure clock_agent_set_period(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    period      : in    time
    );

    ---------------------------------------------------------------------------
    -- Get clock period of clock generator agent.
    --
    -- @param channel   Channel on which to send the request
    -- @param period    Obtained clock period.
    ---------------------------------------------------------------------------
    procedure clock_agent_get_period(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    period      : out   time
    );

    ---------------------------------------------------------------------------
    -- Set clock generator jitter.
    --
    -- @param channel   Channel on which to send the request
    -- @param jitter    Jitter to be set.
    ---------------------------------------------------------------------------
    procedure clock_agent_set_jitter(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    jitter      : in    time
    );

    ---------------------------------------------------------------------------
    -- Get clock generator jitter.
    --
    -- @param channel   Channel on which to send the request
    -- @param jitter    Obtained jitter.
    ---------------------------------------------------------------------------
    procedure clock_agent_get_jitter(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    jitter      : out   time
    );

    ---------------------------------------------------------------------------
    -- Set clock generator duty cycle.
    --
    -- @param channel   Channel on which to send the request
    -- @param duty      Duty cycle to be set.
    ---------------------------------------------------------------------------
    procedure clock_agent_set_duty(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    duty        : in    integer range 0 to 100
    );

    ---------------------------------------------------------------------------
    -- Get clock generator duty cycle.
    --
    -- @param channel   Channel on which to send the request
    -- @param duty      Obtained duty cycle.
    ---------------------------------------------------------------------------
    procedure clock_agent_get_duty(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    duty        : out   integer range 0 to 100
    );

    ---------------------------------------------------------------------------
    -- Wait 1 clock period of clock. Waits on clock_in, not on clock_out.
    -- So when clocks are not generated by clock generator, it still works
    -- properly!
    --
    -- During the waiting, communication channel is blocked and shall not be
    -- used by other processes/agents.
    --
    -- @param channel    Channel on which to send the request
    -- @param num_cycles Number
    ---------------------------------------------------------------------------
    procedure clock_agent_wait_cycle(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    );


    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Private declarations
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------

    -- Supported commands for clock agent (sent as message types)
    constant CLOCK_AGNT_CMD_START         : integer := 0;
    constant CLOCK_AGNT_CMD_STOP          : integer := 1;
    constant CLOCK_AGNT_CMD_PERIOD_SET    : integer := 2;
    constant CLOCK_AGNT_CMD_PERIOD_GET    : integer := 3;
    constant CLOCK_AGNT_CMD_JITTER_SET    : integer := 4;
    constant CLOCK_AGNT_CMD_JITTER_GET    : integer := 5;
    constant CLOCK_AGNT_CMD_DUTY_SET      : integer := 6;
    constant CLOCK_AGNT_CMD_DUTY_GET      : integer := 7;
    constant CLOCK_AGNT_CMD_WAIT_CYCLE    : integer := 8;

    -- Tag for messages
    constant clock_agent_TAG : string := "Clock Agent: ";

end package;


package body clock_agent_pkg is


    ---------------------------------------------------------------------------
    -- Message print helpers
    ---------------------------------------------------------------------------
    procedure clock_agent_info_m(
        constant    id          : in    natural;
        constant    msg         : in    string
    ) is begin
        info_m(clock_agent_TAG & "(" & natural'image(id) & "): " & msg);
    end procedure;

    procedure clock_agent_debug_m(
        constant    id          : in    natural;
        constant    msg         : in    string
    ) is begin
        debug_m(clock_agent_TAG & "(" & natural'image(id) & "): " & msg);
    end procedure;

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Clock generator agent API
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------

    procedure clock_agent_start(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    ) is
    begin
        clock_agent_info_m(id, "Starting clock generator agent!");
        send(channel, id, CLOCK_AGNT_CMD_START);
        clock_agent_debug_m(id, "Clock generator agent started!");
    end procedure;


    procedure clock_agent_stop(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    ) is
    begin
        clock_agent_info_m(id, "Stopping clock generator agent!");
        send(channel, id, CLOCK_AGNT_CMD_STOP);
        clock_agent_debug_m(id, "Clock generator agent stopped");
    end procedure;


    procedure clock_agent_set_period(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    period      : in    time
    ) is
    begin
        clock_agent_info_m(id, "Setting clock agent period to: " & time'image(period));
        com_channel_data.set_param(period);
        send(channel, id, CLOCK_AGNT_CMD_PERIOD_SET);
        clock_agent_debug_m(id, "Clock generator period set");
    end procedure;


    procedure clock_agent_get_period(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    period      : out   time
    ) is
    begin
        clock_agent_info_m(id, "Getting clock agent period");
        send(channel, id, CLOCK_AGNT_CMD_PERIOD_GET);
        period := com_channel_data.get_param;
        clock_agent_debug_m(id, "Clock generator period got");
    end procedure;


    procedure clock_agent_set_jitter(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    jitter      : in    time
    ) is
    begin
        clock_agent_info_m(id, "Setting clock agent jitter to: " & time'image(jitter));
        com_channel_data.set_param(jitter);
        send(channel, id, CLOCK_AGNT_CMD_JITTER_SET);
        clock_agent_debug_m(id, "Clock generator period set");
    end procedure;


    procedure clock_agent_get_jitter(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    jitter      : out   time
    ) is
    begin
        clock_agent_info_m(id, "Getting clock agent jitter");
        send(channel, id, CLOCK_AGNT_CMD_JITTER_GET);
        jitter := com_channel_data.get_param;
        clock_agent_debug_m(id, "Clock generator jitter got");
    end procedure;


    procedure clock_agent_set_duty(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    duty        : in    integer range 0 to 100
    ) is
    begin
        clock_agent_info_m(id, "Setting clock agent duty cycle to: " & integer'image(duty));
        com_channel_data.set_param(duty);
        send(channel, id, CLOCK_AGNT_CMD_DUTY_SET);
        clock_agent_debug_m(id, "Clock generator period set");
    end procedure;


    procedure clock_agent_get_duty(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    duty        : out   integer range 0 to 100
    ) is
    begin
        clock_agent_info_m(id, "Getting clock agent duty cycle");
        send(channel, id, CLOCK_AGNT_CMD_DUTY_GET);
        duty := com_channel_data.get_param;
        clock_agent_debug_m(id, "Clock generator duty cycle got");
    end procedure;


    procedure clock_agent_wait_cycle(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    ) is
    begin
        clock_agent_debug_m(id, "Waiting one clock cycle");
        send(channel, id, CLOCK_AGNT_CMD_WAIT_CYCLE);
        clock_agent_debug_m(id, "Waited one clock cycle");
    end procedure;


end package body;
