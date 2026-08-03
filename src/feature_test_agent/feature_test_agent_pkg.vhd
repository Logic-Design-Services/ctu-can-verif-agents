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
--  Purpose:
--    Feature test agent package
--
--------------------------------------------------------------------------------
-- Revision History:
--    24.7.2026   Created file based on CTU CAN FD feature test package.
--                Removed all CTU CAN FD specific logic, kept only agent
--                control (bus forcing, signal delaying, etc...).
--------------------------------------------------------------------------------

Library ctu_can_agents;
context ctu_can_agents.ieee_context;
context ctu_can_agents.agents_deps_context;

package feature_test_agent_pkg is

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Communication constants
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------

    type t_feature_node is(
        DUT_NODE,
        TEST_NODE
    );

    -- Supported commands
    constant FEATURE_TEST_AGNT_FORCE_BUS                : integer := 0;
    constant FEATURE_TEST_AGNT_RELEASE_BUS              : integer := 1;
    constant FEATURE_TEST_AGNT_FORCE_CAN_RX             : integer := 2;
    constant FEATURE_TEST_AGNT_RELEASE_CAN_RX           : integer := 3;
    constant FEATURE_TEST_AGNT_SET_TRV_DELAY            : integer := 4;
    constant FEATURE_TEST_AGNT_CHECK_BUS_LEVEL          : integer := 5;
    constant FEATURE_TEST_AGNT_CHECK_CAN_TX             : integer := 6;
    constant FEATURE_TEST_AGNT_GET_CAN_TX               : integer := 7;
    constant FEATURE_TEST_AGNT_GET_CAN_RX               : integer := 8;
    constant FEATURE_TEST_AGNT_FLIP_BUS                 : integer := 10;

    -- Tag for messages
    constant FEATURE_TEST_AGENT_TAG : string := "Feature test Agent: ";

    ---------------------------------------------------------------------------
    -- Force bus level to given value. Applicable only in feature tests!
    --
    -- Arguments:
    --  bus_val     Value to be forced
    --  channel     Communication channel
    ---------------------------------------------------------------------------
    procedure feature_test_agent_force_bus_level(
        signal   channel                : inout t_com_channel;
                 id                     : in    natural;
                 value                  : in    std_logic

    );

    ---------------------------------------------------------------------------
    -- Flip bus level to opposite value than AND of DUT and Test Node CAN TX.
    -- Applicable only in feature tests!
    --
    -- Arguments:
    --  channel     Communication channel
    ---------------------------------------------------------------------------
    procedure feature_test_agent_flip_bus_level(
        signal   channel                : inout t_com_channel;
                 id                     : in    natural
    );

    ---------------------------------------------------------------------------
    -- Cancels the effect of "force_bus_level" and "flip_bus_level".
    -- Applicable only in feature tests.
    --
    -- Arguments:
    --  channel     Communication channel
    ---------------------------------------------------------------------------
    procedure feature_test_agent_release_bus_level(
        signal channel                  : inout t_com_channel;
               id                       : in    natural
    );

    ---------------------------------------------------------------------------
    -- Check bus level to be equal to a value.
    --
    -- Arguments:
    --  value       Expected value of bus
    --  channel     Communication channel
    ---------------------------------------------------------------------------
    procedure feature_test_agent_check_bus_level(
        signal   channel                  : inout t_com_channel;
                 id                       : in    natural;
        constant value                    : in    std_logic;
        constant msg                      : in    string
    );

    ---------------------------------------------------------------------------
    -- Force CAN RX of single controller to given value. This can be used when
    -- only RX value of single node shall be forced to different value
    --
    -- Applicable only in feature tests!
    --
    -- Arguments:
    --  value       Value to be forced
    --  node        Node on whose RX to force the value!
    --  channel     Communication channel
    ---------------------------------------------------------------------------
    procedure feature_test_agent_force_can_rx(
        signal   channel                  : inout t_com_channel;
                 id                       : in    natural;
        constant value                    : in    std_logic;
        constant node                     : in    t_feature_node
    );

    ---------------------------------------------------------------------------
    -- Release CAN_RX value. Applicable only in feature tests!
    --
    -- Arguments:
    --  channel     Communication channel
    ---------------------------------------------------------------------------
    procedure feature_test_agent_release_can_rx(
        signal   channel                  : inout t_com_channel;
                 id                       : in    natural
    );

    ---------------------------------------------------------------------------
    -- Checks value send on CAN_TX by a node.
    --
    -- Arguments:
    --  value       Expected value to be sent
    --  node        Node whose CAN_TX value ot check
    --  msg         Message to be printed
    --  channel     Communication channel
    ---------------------------------------------------------------------------
    procedure feature_test_agent_check_can_tx(
        signal   channel            : inout t_com_channel;
                 id                 : in    natural;
        constant value              : in    std_logic;
        constant node               : in    t_feature_node;
        constant msg                : in    string
    );

    ---------------------------------------------------------------------------
    -- Reads value send on CAN_TX by a node.
    --
    -- Arguments:
    --  node        Node whose CAN_TX value ot check
    --  channel     Communication channel
    --  value       Read value.
    ---------------------------------------------------------------------------
    procedure feature_test_agent_get_can_tx(
        signal   channel            : inout t_com_channel;
                 id                 : in    natural;
        constant node               : in    t_feature_node;
        variable value              : out   std_logic
    );

    ---------------------------------------------------------------------------
    -- Reads value received on CAN_RX by a node.
    --
    -- Arguments:
    --  node        Node whose CAN_TX value ot check
    --  channel     Communication channel
    --  value       Read value.
    ---------------------------------------------------------------------------
    procedure feature_test_agent_get_can_rx(
        signal   channel            : inout t_com_channel;
                 id                 : in    natural;
        constant node               : in    t_feature_node;
        variable value              : out   std_logic
    );

    ----------------------------------------------------------------------------
    -- Configure transmitter delay. Valid only in feature tests.
    --
    -- Arguments:
    --  tx_del          Delay to be set
    --  node            Node which shall be accessed (Test node or DUT).
    --  channel         Communication channel
    ----------------------------------------------------------------------------
    procedure feature_test_agent_set_transceiver_delay(
        signal   channel            : inout t_com_channel;
                 id                 : in    natural;
        constant tx_del             : in    time;
        constant node               : in    t_feature_node
    );

    ----------------------------------------------------------------------------
    ----------------------------------------------------------------------------
    -- Components declaration
    ----------------------------------------------------------------------------
    ----------------------------------------------------------------------------
    component feature_test_agent is
    generic (
        -- Addresss on communication channel
        G_COM_ID                    :     natural;

        -- Test details
        G_DUT_NAME                  :     string
    );
    port(
        -----------------------------------------------------------------------
        -- Test node connections
        -----------------------------------------------------------------------

        -- Clocking and Reset
        clk_sys                     : in  std_logic;
        clk_can                     : in  std_logic;
        rst_n                       : in  std_logic;

        -- Memory bus slave (both CTU CAN FD and CTU CAN XL)
        mbs_write_data              : in  std_logic_vector(31 downto 0);
        mbs_read_data               : out std_logic_vector(31 downto 0);
        mbs_adress                  : in  std_logic_vector(15 downto 0);
        mbs_scs                     : in  std_logic;
        mbs_srd                     : in  std_logic;
        mbs_swr                     : in  std_logic;
        mbs_sbe                     : in  std_logic_vector(3 downto 0);

        -- Memory bus master (only CTU CAN XL)
        mbm_read_data               : in  std_logic_vector(31 downto 0);
        mbm_write_data              : out std_logic_vector(31 downto 0);
        mbm_adress                  : out std_logic_vector(31 downto 0);
        mbm_scs                     : out std_logic;
        mbm_srd                     : out std_logic;
        mbm_swr                     : out std_logic;
        mbm_sbe                     : out std_logic_vector(3 downto 0);
        mbm_wait_request            : in  std_logic;
        mbm_read_data_valid         : in  std_logic;

        -- CAN bus from/to DUT
        dut_can_tx                  : in  std_logic;
        dut_can_rx                  : out std_logic;

        -- Test Nodes test probe output
        test_node_tp_rx_trigger_nbs : out std_logic;
        test_node_tp_rx_trigger_wbs : out std_logic;
        test_node_tp_tx_trigger     : out std_logic
    );
    end component;

end package;



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Package implementation
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

package body feature_test_agent_pkg is

    procedure feature_test_agent_force_bus_level(
        signal   channel                : inout t_com_channel;
                 id                     : in    natural;
                 value                  : in    std_logic
    ) is
    begin
        info_m(FEATURE_TEST_AGENT_TAG &
             "Forcing bus level to: " & std_logic'image(value));
        com_channel_data.set_param(value);
        send(channel, id, FEATURE_TEST_AGNT_FORCE_BUS);
        debug_m("Bus level forced");
    end procedure;

    procedure feature_test_agent_flip_bus_level(
        signal   channel            : inout t_com_channel;
                 id                 : in    natural
    ) is
    begin
        info_m(FEATURE_TEST_AGENT_TAG &
             "Flipping bus level value");
        send(channel, id, FEATURE_TEST_AGNT_FLIP_BUS);
        debug_m("Bus level flipped");
    end procedure;

    procedure feature_test_agent_release_bus_level(
        signal   channel            : inout t_com_channel;
                 id                 : in    natural
    ) is
    begin
        info_m(FEATURE_TEST_AGENT_TAG & "Releasing bus level");
        send(channel, id, FEATURE_TEST_AGNT_RELEASE_BUS);
        debug_m("Bus level released");
    end procedure;

    procedure feature_test_agent_check_bus_level(
        signal   channel            : inout t_com_channel;
                 id                 : in    natural;
        constant value              : in    std_logic;
        constant msg                : in    string
    ) is
    begin
        info_m(FEATURE_TEST_AGENT_TAG & msg);
        com_channel_data.set_param(value);
        send(channel, id, FEATURE_TEST_AGNT_CHECK_BUS_LEVEL);
        debug_m("Bus level checked");
    end procedure;

    procedure feature_test_agent_force_can_rx(
        signal   channel            : inout t_com_channel;
                 id                 : in    natural;
        constant value              : in    std_logic;
        constant node               : in    t_feature_node
    ) is
    begin
        info_m(FEATURE_TEST_AGENT_TAG &
             "Forcing CAN RX of: " & t_feature_node'image(node) &
             " to: " & std_logic'image(value));

        com_channel_data.set_param(value);
        if (node = DUT_NODE) then
            com_channel_data.set_param(0);
        else
            com_channel_data.set_param(1);
        end if;
        send(channel, id, FEATURE_TEST_AGNT_FORCE_CAN_RX);
        debug_m("CAN RX forced");
    end procedure;

    procedure feature_test_agent_release_can_rx(
        signal   channel            : inout t_com_channel;
                 id                 : in    natural
    ) is
    begin
        info_m(FEATURE_TEST_AGENT_TAG & "Releasing CAN RX");
        send(channel, id, FEATURE_TEST_AGNT_RELEASE_CAN_RX);
        debug_m("CAN RX released");
    end procedure;

    procedure feature_test_agent_check_can_tx(
        signal   channel            : inout t_com_channel;
                 id                 : in    natural;
        constant value              : in    std_logic;
        constant node               : in    t_feature_node;
        constant msg                : in    string
    ) is
    begin
        info_m(FEATURE_TEST_AGENT_TAG & msg);
        if (node = DUT_NODE) then
            com_channel_data.set_param(0);
        else
            com_channel_data.set_param(1);
        end if;
        com_channel_data.set_param(value);
        send(channel, id, FEATURE_TEST_AGNT_CHECK_CAN_TX);
        debug_m("CAN TX Checked");
    end procedure;

    procedure feature_test_agent_get_can_tx(
        signal   channel            : inout t_com_channel;
                 id                 : in    natural;
        constant node               : in    t_feature_node;
        variable value              : out   std_logic
    ) is
    begin
        if (node = DUT_NODE) then
            com_channel_data.set_param(0);
        else
            com_channel_data.set_param(1);
        end if;
        com_channel_data.set_param(value);
        send(channel, id, FEATURE_TEST_AGNT_GET_CAN_TX);
        value := com_channel_data.get_param;
    end procedure;

    procedure feature_test_agent_get_can_rx(
        signal   channel            : inout t_com_channel;
                 id                 : in    natural;
        constant node               : in    t_feature_node;
        variable value              : out   std_logic
    ) is
    begin
        if (node = DUT_NODE) then
            com_channel_data.set_param(0);
        else
            com_channel_data.set_param(1);
        end if;
        send(channel, id, FEATURE_TEST_AGNT_GET_CAN_RX);
        value := com_channel_data.get_param;
    end procedure;

    procedure feature_test_agent_set_transceiver_delay(
        signal   channel            : inout t_com_channel;
                 id                 : in    natural;
        constant tx_del             : in    time;
        constant node               : in    t_feature_node
    )is
    begin
        info_m(FEATURE_TEST_AGENT_TAG & " Setting transceiver delay");
        com_channel_data.set_param(tx_del);
        if (node = DUT_NODE) then
            com_channel_data.set_param(0);
        else
            com_channel_data.set_param(1);
        end if;
        send(channel, id, FEATURE_TEST_AGNT_SET_TRV_DELAY);
        debug_m(FEATURE_TEST_AGENT_TAG & " Transceiver delay set");
    end procedure;

end package body;
