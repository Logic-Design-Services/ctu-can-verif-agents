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
--    Package with API for Timestamp agent.
--
--------------------------------------------------------------------------------
-- Revision History:
--    12.3.2021   Created file
--    20.7.2026   Added configurable ID.
--------------------------------------------------------------------------------

library ctu_can_agents;
context ctu_can_agents.ieee_context;
context ctu_can_agents.agents_deps_context;

package timestamp_agent_pkg is

    ---------------------------------------------------------------------------
    -- Interrupt agent component
    ---------------------------------------------------------------------------
    component timestamp_agent is
    port (
        clk_sys     : in std_logic;
        timestamp   : out std_logic_vector(63 downto 0)
    );
    end component;

    ---------------------------------------------------------------------------
    -- Message print helpers
    ---------------------------------------------------------------------------
    procedure timestamp_agent_info_m(
        constant    id          : in    natural := C_TIMESTAMP_AGENT_DEF_ID;
        constant    msg         : in    string
    );

    procedure timestamp_agent_debug_m(
        constant    id          : in    natural := C_TIMESTAMP_AGENT_DEF_ID;
        constant    msg         : in    string
    );

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Timestamp agent API
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------

    ---------------------------------------------------------------------------
    -- Start timestamp agent
    --
    -- @param channel   Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure timestamp_agent_start(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural := C_RESET_AGENT_DEF_ID
    );

    ---------------------------------------------------------------------------
    -- Stop timestamp agent
    --
    -- @param channel   Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure timestamp_agent_stop(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural := C_RESET_AGENT_DEF_ID
    );

    ---------------------------------------------------------------------------
    -- Set step of timestamp agent
    --
    -- @param channel   Channel on which to send the request
    -- @param step      Natural
    ---------------------------------------------------------------------------
    procedure timestamp_agent_set_step(
        signal      channel     : inout t_com_channel;
        constant    step        : in    natural;
        constant    id          : in    natural := C_RESET_AGENT_DEF_ID
    );

    ---------------------------------------------------------------------------
    -- Set prescaler of timestamp agent
    --
    -- @param channel   Channel on which to send the request
    -- @param prescaler Natural
    ---------------------------------------------------------------------------
    procedure timestamp_agent_set_prescaler(
        signal      channel     : inout t_com_channel;
        constant    prescaler   : in    natural;
        constant    id          : in    natural := C_RESET_AGENT_DEF_ID
    );

    ---------------------------------------------------------------------------
    -- Preset timestamp value of timestamp agent
    --
    -- @param channel   Channel on which to send the request
    -- @param timestamp Timestamp value to be preset
    ---------------------------------------------------------------------------
    procedure timestamp_agent_timestamp_preset(
        signal      channel     : inout t_com_channel;
        constant    timestamp   : in    std_logic_vector(63 downto 0);
        constant    id          : in    natural := C_RESET_AGENT_DEF_ID
    );


    ---------------------------------------------------------------------------
    -- Gets current value of timestamp
    --
    -- @param channel   Channel on which to send the request
    -- @param timestamp Return value of timestamp
    ---------------------------------------------------------------------------
    procedure timestamp_agent_get_timestamp(
        signal      channel     : inout t_com_channel;
        variable    timestamp   : out   std_logic_vector(63 downto 0);
        constant    id          : in    natural := C_RESET_AGENT_DEF_ID
    );

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Private declarations
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------

    -- Supported commands
    constant TIMESTAMP_AGENT_CMD_START                  : integer := 0;
    constant TIMESTAMP_AGENT_CMD_STOP                   : integer := 1;
    constant TIMESTAMP_AGENT_CMD_STEP_SET               : integer := 2;
    constant TIMESTAMP_AGENT_CMD_PRESCALER_SET          : integer := 3;
    constant TIMESTAMP_AGENT_CMD_TIMESTAMP_PRESET       : integer := 4;
    constant TIMESTAMP_AGENT_CMD_GET_TIMESTAMP          : integer := 5;

    -- Tag for messages
    constant TIMESTAMP_AGENT_TAG : string := "Timestamp Agent: ";

end package;


package body timestamp_agent_pkg is


    ---------------------------------------------------------------------------
    -- Message print helpers
    ---------------------------------------------------------------------------
    procedure timestamp_agent_info_m(
        constant    id          : in    natural := C_TIMESTAMP_AGENT_DEF_ID;
        constant    msg         : in    string
    ) is
    begin
        info_m(TIMESTAMP_AGENT_TAG & "(" & natural'image(id) & "): " & msg);
    end procedure;

    procedure timestamp_agent_debug_m(
        constant    id          : in    natural := C_TIMESTAMP_AGENT_DEF_ID;
        constant    msg         : in    string
    )  is
    begin
        debug_m(TIMESTAMP_AGENT_TAG & "(" & natural'image(id) & "): " & msg);
    end procedure;

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Timestamp agent API
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------

    procedure timestamp_agent_start(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural := C_RESET_AGENT_DEF_ID
    ) is
    begin
        timestamp_agent_info_m(id, "Starting");
        send(channel, id, TIMESTAMP_AGENT_CMD_START);
        timestamp_agent_debug_m(id, "Started");
    end procedure;


    procedure timestamp_agent_stop(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural := C_RESET_AGENT_DEF_ID
    ) is
    begin
        timestamp_agent_info_m(id, "Stopping");
        send(channel, id, TIMESTAMP_AGENT_CMD_STOP);
        timestamp_agent_debug_m(id, "Stopped");
    end procedure;


    procedure timestamp_agent_set_step(
        signal      channel     : inout t_com_channel;
        constant    step        : in    natural;
        constant    id          : in    natural := C_RESET_AGENT_DEF_ID
    ) is
    begin
        timestamp_agent_info_m(id, "Setting step");
        com_channel_data.set_param(step);
        send(channel, id, TIMESTAMP_AGENT_CMD_STEP_SET);
        timestamp_agent_debug_m(id, "Step set");
    end procedure;


    procedure timestamp_agent_set_prescaler(
        signal      channel     : inout t_com_channel;
        constant    prescaler   : in    natural;
        constant    id          : in    natural := C_RESET_AGENT_DEF_ID
    ) is
    begin
        timestamp_agent_info_m(id, "Setting Prescaler");
        com_channel_data.set_param(prescaler);
        send(channel, id, TIMESTAMP_AGENT_CMD_PRESCALER_SET);
        timestamp_agent_debug_m(id, "Prescaler set");
    end procedure;


    procedure timestamp_agent_timestamp_preset(
        signal      channel     : inout t_com_channel;
        constant    timestamp   : in    std_logic_vector(63 downto 0);
        constant    id          : in    natural := C_RESET_AGENT_DEF_ID
    ) is
    begin
        timestamp_agent_info_m(id, "Presetting timestamp");
        com_channel_data.set_param(timestamp);
        send(channel, id, TIMESTAMP_AGENT_CMD_TIMESTAMP_PRESET);
        timestamp_agent_debug_m(id, "Timestamp preset");
    end procedure;

    procedure timestamp_agent_get_timestamp(
        signal      channel     : inout t_com_channel;
        variable    timestamp   : out   std_logic_vector(63 downto 0);
        constant    id          : in    natural := C_RESET_AGENT_DEF_ID
    ) is
        variable tmp : std_logic_vector(127 downto 0);
    begin
        timestamp_agent_info_m(id, "Reading timestamp");
        send(channel, id, TIMESTAMP_AGENT_CMD_GET_TIMESTAMP);
        tmp := com_channel_data.get_param;
        timestamp := tmp(63 downto 0);
        timestamp_agent_debug_m(id, "Timestamp read");
    end procedure;

end package body;
