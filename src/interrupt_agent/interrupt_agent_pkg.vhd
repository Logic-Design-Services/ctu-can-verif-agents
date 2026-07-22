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
--    Package with API for Interrupt agent.
--
--------------------------------------------------------------------------------
-- Revision History:
--    12.3.2021   Created file
--    20.7.2026   Added configurable ID.
--------------------------------------------------------------------------------

library ctu_can_agents;
context ctu_can_agents.ieee_context;
context ctu_can_agents.agents_deps_context;

package interrupt_agent_pkg is

    ---------------------------------------------------------------------------
    -- Interrupt agent component
    ---------------------------------------------------------------------------
    component interrupt_agent is
    generic (
        G_COM_ID        :      natural := C_INTERRUPT_AGENT_DEF_ID
    );
    port (
        int   :   in std_logic
    );
    end component;

    ---------------------------------------------------------------------------
    -- Message print helpers
    ---------------------------------------------------------------------------
    procedure interrupt_agent_info_m(
        constant    id          : in    natural := C_CAN_AGENT_DEF_ID;
        constant    msg         : in    string
    );

    procedure interrupt_agent_debug_m(
        constant    id          : in    natural := C_CAN_AGENT_DEF_ID;
        constant    msg         : in    string
    );

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Interrupt agent API
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------

    ---------------------------------------------------------------------------
    -- Set polarity of active Interrupt value.
    --
    -- @param channel   Channel on which to send the request
    -- @param polarity  Polarity to be set.
    ---------------------------------------------------------------------------
    procedure interrupt_agent_polarity_set(
        signal      channel     : inout t_com_channel;
        constant    polarity    : in    std_logic;
        constant    id          : in    natural := C_INTERRUPT_AGENT_DEF_ID
    );

    ---------------------------------------------------------------------------
    -- Get polarity of Interrupt value
    --
    -- @param channel   Channel on which to send the request
    -- @param polarity  Obtained polarity.
    ---------------------------------------------------------------------------
    procedure interrupt_agent_polarity_get(
        signal      channel     : inout t_com_channel;
        variable    polarity    : out   std_logic;
        constant    id          : in    natural := C_INTERRUPT_AGENT_DEF_ID
    );

    ---------------------------------------------------------------------------
    -- Checks if interrupt is asserted
    --
    -- @param channel   Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure interrupt_agent_check_asserted(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural := C_INTERRUPT_AGENT_DEF_ID
    );

    ---------------------------------------------------------------------------
    -- Checks if interrupt is not asserted
    --
    -- @param channel   Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure interrupt_agent_check_not_asserted(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural := C_INTERRUPT_AGENT_DEF_ID
    );

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Private declarations
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------

    -- Supported commands
    constant INTERRUPT_AGNT_CMD_POLARITY_SET            : integer := 0;
    constant INTERRUPT_AGNT_CMD_POLARITY_GET            : integer := 1;
    constant INTERRUPT_AGNT_CMD_CHECK_ASSERTED          : integer := 2;
    constant INTERRUPT_AGNT_CMD_CHECK_NOT_ASSERTED      : integer := 3;

    -- Tag for messages
    constant INTERRUPT_AGENT_TAG : string := "Interrupt Agent: ";

end package;


package body interrupt_agent_pkg is

    ---------------------------------------------------------------------------
    -- Message print helpers
    ---------------------------------------------------------------------------
    procedure interrupt_agent_info_m(
        constant    id          : in    natural := C_CAN_AGENT_DEF_ID;
        constant    msg         : in    string
    ) is
    begin
        info_m(INTERRUPT_AGENT_TAG & "(" & natural'image(id) & "): " & msg);
    end procedure;

    procedure interrupt_agent_debug_m(
        constant    id          : in    natural := C_CAN_AGENT_DEF_ID;
        constant    msg         : in    string
    )  is
    begin
        debug_m(INTERRUPT_AGENT_TAG & "(" & natural'image(id) & "): " & msg);
    end procedure;

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Interrupt agent API
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------

    procedure interrupt_agent_polarity_set(
        signal      channel     : inout t_com_channel;
        constant    polarity    : in    std_logic;
        constant    id          : in    natural := C_INTERRUPT_AGENT_DEF_ID
    ) is
    begin
        interrupt_agent_info_m(id,  "Setting polarity");
        com_channel_data.set_param(polarity);
        send(channel, id, INTERRUPT_AGNT_CMD_POLARITY_SET);
        interrupt_agent_debug_m(id, "Polarity set");
    end procedure;


    procedure interrupt_agent_polarity_get(
        signal      channel     : inout t_com_channel;
        variable    polarity    : out   std_logic;
        constant    id          : in    natural := C_INTERRUPT_AGENT_DEF_ID
    )is
    begin
        interrupt_agent_info_m(id,  "Getting polarity");
        send(channel, id, INTERRUPT_AGNT_CMD_POLARITY_GET);
        polarity := com_channel_data.get_param;
        interrupt_agent_debug_m(id, "Polarity got");
    end procedure;


    procedure interrupt_agent_check_asserted(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural := C_INTERRUPT_AGENT_DEF_ID
    )is
    begin
        interrupt_agent_info_m(id,  "Checking asserted");
        send(channel, id, INTERRUPT_AGNT_CMD_CHECK_ASSERTED);
        interrupt_agent_debug_m(id, "Asserted checked");
    end procedure;


    procedure interrupt_agent_check_not_asserted(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural := C_INTERRUPT_AGENT_DEF_ID
    )is
    begin
        interrupt_agent_info_m(id,  "Checking not asserted");
        send(channel, id, INTERRUPT_AGNT_CMD_CHECK_NOT_ASSERTED);
        interrupt_agent_debug_m(id, "Not asserted checked");
    end procedure;

end package body;
