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
--    Memory bus slave agent.
--
--    TODO: Description
--
--------------------------------------------------------------------------------
-- Revision History:
--    20.7.2026   Created file
--------------------------------------------------------------------------------

library ctu_can_agents;
context ctu_can_agents.ieee_context;
context ctu_can_agents.agents_deps_context;

use ctu_can_agents.mem_bus_slave_agent_pkg.all;
use ctu_can_agents.mem_model_pkg.all;

entity mem_bus_slave_agent is
    generic(
        G_COM_ID                    : natural;
        G_WAIT_CYCLES_FIFO_DEPTH    : natural
    );
    port (
        -- Clock
        clk                 : in    std_logic;

        -- Memory interface (master)
        write_data          : in  std_logic_vector(31 downto 0);
        read_data           : out std_logic_vector(31 downto 0) := (others => 'X');
        adress              : in  std_logic_vector(31 downto 0);
        scs                 : in  std_logic;
        srd                 : in  std_logic;
        swr                 : in  std_logic;
        sbe                 : in  std_logic_vector(3 downto 0);
        wait_request        : out std_logic := '0';
        read_data_valid     : out std_logic := '0'
    );
end entity;

architecture tb of mem_bus_slave_agent is

    signal agent_enabled            : boolean := false;
    signal mem_id                   : integer := 0;

    type t_transfer_fifo is
        array (0 to G_WAIT_CYCLES_FIFO_DEPTH - 1) of integer;

    signal wrq_fifo             : t_transfer_fifo;
    signal wrq_wp               : integer range 0 to G_WAIT_CYCLES_FIFO_DEPTH - 1 := 0;
    signal wrq_rp               : integer range 0 to G_WAIT_CYCLES_FIFO_DEPTH - 1 := 0;

    signal rdw_fifo             : t_transfer_fifo;
    signal rdw_wp               : integer range 0 to G_WAIT_CYCLES_FIFO_DEPTH - 1 := 0;
    signal rdw_rp               : integer range 0 to G_WAIT_CYCLES_FIFO_DEPTH - 1 := 0;

    procedure put_to_fifo(
               cycles          : in    integer;
        signal fifo            : out   t_transfer_fifo;
        signal wp              : inout integer range 0 to G_WAIT_CYCLES_FIFO_DEPTH - 1;
        signal rp              : in    integer range 0 to G_WAIT_CYCLES_FIFO_DEPTH - 1
    ) is
    begin
        if (wp mod G_WAIT_CYCLES_FIFO_DEPTH = (rp - 1) mod G_WAIT_CYCLES_FIFO_DEPTH) then
            report MEM_BUS_SLAVE_AGENT_TAG & "(" & natural'image(G_COM_ID) & "): " &
                   "FIFO overflow !" severity failure;
        end if;

        fifo(wp) <= cycles;
        wp <= (wp + 1) mod G_WAIT_CYCLES_FIFO_DEPTH;
        wait for 0 ns;
    end procedure;

    procedure pop_from_fifo(
               cycles          : out   integer;
        signal fifo            : in    t_transfer_fifo;
        signal wp              : in    integer range 0 to G_WAIT_CYCLES_FIFO_DEPTH - 1;
        signal rp              : inout integer range 0 to G_WAIT_CYCLES_FIFO_DEPTH - 1
    ) is
    begin
        if (wp = rp) then
            report MEM_BUS_SLAVE_AGENT_TAG & "(" & natural'image(G_COM_ID) & "): " &
                   "FIFO underflow !" severity failure;
        end if;

        cycles := fifo(rp);
        rp <= (rp + 1) mod G_WAIT_CYCLES_FIFO_DEPTH;
        wait for 0 ns;
    end procedure;

begin

    --------------------------------------------------------------------------
    -- Slave response handling
    ---------------------------------------------------------------------------
    p_slave_response : process
        variable tmp_rdata      : std_logic_vector(31 downto 0);
        variable initialized    : boolean;
    begin
        if (not agent_enabled) then
            wait until agent_enabled;
        end if;

        wait until rising_edge(clk);
        wait for 1 ps;
        wait_request <= '0';
        read_data_valid <= '0';
        read_data <= (others => 'X');

        -- TODO: Implement controlled and randomized stall insertion to the
        --       on wait_request and readdatavalid !
        if (scs = '1') then
            if (swr = '1') then
                wait for 1 ps;
                mem_model_put_data(
                    default_channel,
                    mem_id,
                    to_integer(unsigned(adress)),
                    write_data
                );
            elsif (srd = '1') then
                mem_model_get_data(
                    default_channel,
                    mem_id,
                    to_integer(unsigned(adress)),
                    tmp_rdata,
                    initialized
                );

                if (not initialized) then
                    mem_model_dump(default_channel, mem_id);
                    mem_bus_slave_agent_error_m(G_COM_ID,
                        "Read undefined data (0x" & to_hstring(tmp_rdata) & ") from address: 0x" &
                        to_hstring(adress));
                end if;
                wait until rising_edge(clk);
                wait for 1 ps;
                read_data <= tmp_rdata;
                read_data_valid <= '1';
            end if;
        end if;

    end process;


    --------------------------------------------------------------------------
    -- Comunication receiver process
    ---------------------------------------------------------------------------
    p_receiver : process
        variable cmd            : integer;
        variable reply_code     : integer;
        variable transfer       : t_mem_bus_transfer;
    begin
        receive_start(default_channel, G_COM_ID);

        -- Command is sent as message type
        cmd := com_channel_data.get_msg_code;
        reply_code := C_REPLY_CODE_OK;

        case cmd is
        when MEM_BUS_SLAVE_AGNT_CMD_START =>
            agent_enabled <= true;

        when MEM_BUS_SLAVE_AGNT_CMD_STOP =>
            agent_enabled <= false;

        when MEM_BUS_SLAVE_AGNT_CMD_SET_MEM_ID =>
            mem_id <= com_channel_data.get_param;

        when MEM_BUS_SLAVE_AGNT_CMD_ADD_WAIT_REQUEST_CYCLES =>
            put_to_fifo(com_channel_data.get_param, wrq_fifo, wrq_wp, wrq_rp);

        when MEM_BUS_SLAVE_AGNT_CMD_ADD_READ_DATA_VALID_CYCLES =>
            put_to_fifo(com_channel_data.get_param, rdw_fifo, rdw_wp, rdw_rp);

        when others =>
            info_m("Invalid message type: " & integer'image(cmd));
            reply_code := C_REPLY_CODE_ERR;

        end case;

        receive_finish(default_channel, reply_code);
    end process;


end architecture;