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
--    Package with API for Memory model.
--
--------------------------------------------------------------------------------
-- Revision History:
--    20.7.2026   Created file
--------------------------------------------------------------------------------

library ctu_can_agents;
context ctu_can_agents.ieee_context;
context ctu_can_agents.agents_deps_context;

package mem_model_pkg is

    component mem_model is
    generic(
        G_COM_ID                : natural
    );
    end component;

    ---------------------------------------------------------------------------
    -- Message print helpers
    ---------------------------------------------------------------------------
    procedure mem_model_info_m(
        constant    id          : in    natural;
        constant    msg         : in    string
    );

    procedure mem_model_debug_m(
        constant    id          : in    natural;
        constant    msg         : in    string
    );


    ---------------------------------------------------------------------------
    -- Public API functions
    ---------------------------------------------------------------------------
    procedure mem_model_put_data(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
                    address     : in    integer;
                    data        : in    std_logic_vector
    );

    procedure mem_model_get_data(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
                    address     : in    integer;
        variable    data        : out   std_logic_vector;
        variable    initialized : out   boolean
    );

    type t_mem_model_init_mode is (
        MEM_MODEL_INIT_RANDOM,
        MEM_MODEL_INIT_ZERO,
        MEM_MODEL_INIT_X,
        MEM_MODEL_INIT_U
    );

    procedure mem_model_set_init_mode(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
                    init_mode   : in    t_mem_model_init_mode
    );

    ---------------------------------------------------------------------------
    -- Memory model API
    ---------------------------------------------------------------------------

    -- Supported commands for clock agent (sent as message types)
    constant MEM_MODEL_CMD_PUT_DATA                 : integer := 0;
    constant MEM_MODEL_CMD_GET_DATA                 : integer := 1;
    constant MEM_MODEL_CMD_SET_NON_INIT_MODE        : integer := 2;

    -- Tag for messages
    constant MEM_MODEL_TAG : string := "Memory Model tag ";

end package;


package body mem_model_pkg is

    procedure mem_model_info_m(
        constant    id          : in    natural;
        constant    msg         : in    string
    ) is
    begin
        info_m(MEM_MODEL_TAG & "(" & natural'image(id) & "): " & msg);
    end procedure;

    procedure mem_model_debug_m(
        constant    id          : in    natural;
        constant    msg         : in    string
    ) is
    begin
        debug_m(MEM_MODEL_TAG & "(" & natural'image(id) & "): " & msg);
    end procedure;

    procedure mem_model_put_data(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
                    address     : in    integer;
                    data        : in    std_logic_vector
    ) is
    begin
        mem_model_info_m(id, "Put Data: " & to_hstring(data) &
                             " to Address: " & integer'image(address));
        com_channel_data.set_param(data);
        com_channel_data.set_param(address);
        com_channel_data.set_param_2(data'length);
        send(channel, id, MEM_MODEL_CMD_PUT_DATA);
        mem_model_debug_m(id, "Data put");
    end procedure;

    procedure mem_model_get_data(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
                    address     : in    integer;
        variable    data        : out   std_logic_vector;
        variable    initialized : out   boolean
    ) is
    begin
        assert (data'length mod 8 = 0);
        mem_model_info_m(id, "Get " & integer'image(data'length / 8) & "Bytes " &
                             " from Address: " & integer'image(address));
        com_channel_data.set_param(address);
        com_channel_data.set_param_2(data'length);
        send(channel, id, MEM_MODEL_CMD_GET_DATA);
        data := com_channel_data.get_param(data'length - 1 downto 0);
        initialized := com_channel_data.get_param;
        mem_model_debug_m(id, "Data obtained: " & to_hstring(data));
    end procedure;

    procedure mem_model_set_init_mode(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
                    init_mode   : in    t_mem_model_init_mode
    ) is
    begin
        mem_model_info_m(id, "Set init mode to: " & t_mem_model_init_mode'image(init_mode));
        com_channel_data.set_param(t_mem_model_init_mode'pos(init_mode));
        send(channel, id, MEM_MODEL_CMD_SET_NON_INIT_MODE);
        mem_model_debug_m(id, "Init mode set");
    end procedure;

end package body;