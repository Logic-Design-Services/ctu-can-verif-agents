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
--    Package with API for Memory bus slave agent.
--
--------------------------------------------------------------------------------
-- Revision History:
--    20.7.2026   Created file
--------------------------------------------------------------------------------

library ctu_can_agents;
context ctu_can_agents.ieee_context;
context ctu_can_agents.agents_deps_context;

package mem_bus_slave_agent_pkg is

    ---------------------------------------------------------------------------
    -- Memory bus slave agent component
    ---------------------------------------------------------------------------
    component mem_bus_slave_agent is
    generic(
        G_COM_ID                    : natural;
        G_WAIT_CYCLES_FIFO_DEPTH    : natural
    );
    port (
        -- Clock
        clk                 : in    std_logic;

        -- Memory interface (master)
        write_data          : in  std_logic_vector(31 downto 0);
        read_data           : out std_logic_vector(31 downto 0);
        adress              : in  std_logic_vector(31 downto 0);
        scs                 : in  std_logic;
        srd                 : in  std_logic;
        swr                 : in  std_logic;
        sbe                 : in  std_logic_vector(3 downto 0);
        wait_request        : out std_logic;
        read_data_valid     : out std_logic
    );
    end component;

    ---------------------------------------------------------------------------
    -- Message print helpers
    ---------------------------------------------------------------------------
    procedure mem_bus_slave_agent_info_m(
        constant    id          : in    natural;
        constant    msg         : in    string
    );

    procedure mem_bus_slave_agent_debug_m(
        constant    id          : in    natural;
        constant    msg         : in    string
    );

    procedure mem_bus_slave_agent_error_m(
        constant    id          : in    natural;
        constant    msg         : in    string
    );

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Memory bus slave agent API
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------

    ---------------------------------------------------------------------------
    -- Start memory bus slave agent.
    --
    -- @param channel   Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure mem_bus_slave_agent_start(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    );

    ---------------------------------------------------------------------------
    -- Stop memory bus slave agent.
    --
    -- @param channel   Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure mem_bus_slave_agent_stop(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    );

    ---------------------------------------------------------------------------
    -- Sets ID of memory model to communicate with
    --
    -- @param channel   Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure mem_bus_slave_agent_set_mem_id(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
                    mem_id      : in    integer
    );

    ---------------------------------------------------------------------------
    -- Adds Wait Request cycle
    --
    -- @param channel   Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure mem_bus_slave_agent_add_wait_request_cycles(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
                    cycles      : in    integer
    );

    ---------------------------------------------------------------------------
    -- Adds Read data valid cycles
    --
    -- @param channel   Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure mem_bus_slave_agent_add_read_data_valid_cycles(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
                    cycles      : in    integer
    );


    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Private declarations
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------

    -- Supported commands for clock agent (sent as message types)
    constant MEM_BUS_SLAVE_AGNT_CMD_START                       : integer := 0;
    constant MEM_BUS_SLAVE_AGNT_CMD_STOP                        : integer := 1;
    constant MEM_BUS_SLAVE_AGNT_CMD_SET_MEM_ID                  : integer := 2;
    constant MEM_BUS_SLAVE_AGNT_CMD_ADD_WAIT_REQUEST_CYCLES     : integer := 3;
    constant MEM_BUS_SLAVE_AGNT_CMD_ADD_READ_DATA_VALID_CYCLES  : integer := 4;

    -- Tag for messages
    constant MEM_BUS_SLAVE_AGENT_TAG : string := "Memory Bus Slave Agent: ";

end package;


package body mem_bus_slave_agent_pkg is

    ---------------------------------------------------------------------------
    -- Message print helpers
    ---------------------------------------------------------------------------
    procedure mem_bus_slave_agent_info_m(
        constant    id          : in    natural;
        constant    msg         : in    string
    ) is
    begin
        info_m(MEM_BUS_SLAVE_AGENT_TAG & "(" & natural'image(id) & "): " & msg);
    end procedure;

    procedure mem_bus_slave_agent_debug_m(
        constant    id          : in    natural;
        constant    msg         : in    string
    )  is
    begin
        debug_m(MEM_BUS_SLAVE_AGENT_TAG & "(" & natural'image(id) & "): " & msg);
    end procedure;

    procedure mem_bus_slave_agent_error_m(
        constant    id          : in    natural;
        constant    msg         : in    string
    )  is
    begin
        error_m(MEM_BUS_SLAVE_AGENT_TAG & "(" & natural'image(id) & "): " & msg);
    end procedure;

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Memory bus slave agent API
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    procedure mem_bus_slave_agent_start(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    ) is
    begin
        mem_bus_slave_agent_info_m(id, "Starting");
        send(channel, id, MEM_BUS_SLAVE_AGNT_CMD_START);
        mem_bus_slave_agent_debug_m(id, "Started");
    end procedure;

    procedure mem_bus_slave_agent_stop(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    ) is
    begin
        mem_bus_slave_agent_info_m(id, "Starting");
        send(channel, id, MEM_BUS_SLAVE_AGNT_CMD_STOP);
        mem_bus_slave_agent_debug_m(id, "Started");
    end procedure;

    procedure mem_bus_slave_agent_set_mem_id(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
                    mem_id      : in    integer
    ) is
    begin
        mem_bus_slave_agent_info_m(id, "Setting Memory model ID to: " & integer'image(mem_id));
        com_channel_data.set_param(mem_id);
        send(channel, id, MEM_BUS_SLAVE_AGNT_CMD_SET_MEM_ID);
        mem_bus_slave_agent_debug_m(id, "Memory model ID set");
    end procedure;

    procedure mem_bus_slave_agent_add_wait_request_cycles(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
                    cycles      : in    integer
    ) is
    begin
        mem_bus_slave_agent_info_m(id, "Setting " & integer'image(cycles) & " Wait Request cycles");
        com_channel_data.set_param(cycles);
        send(channel, id, MEM_BUS_SLAVE_AGNT_CMD_ADD_WAIT_REQUEST_CYCLES);
        mem_bus_slave_agent_debug_m(id, "Wait Request cycles added");
    end procedure;

    procedure mem_bus_slave_agent_add_read_data_valid_cycles(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
                    cycles      : in    integer
    )is
    begin
        mem_bus_slave_agent_info_m(id, "Setting " & integer'image(cycles) & " Read Data Valid cycles");
        com_channel_data.set_param(cycles);
        send(channel, id, MEM_BUS_SLAVE_AGNT_CMD_ADD_READ_DATA_VALID_CYCLES);
        mem_bus_slave_agent_debug_m(id, "Read Data Valid cycles added");
    end procedure;

end package body;