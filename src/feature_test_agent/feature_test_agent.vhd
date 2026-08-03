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
--    Feature test agent. Executes a VHDL feature tests. Contains another
--    instance of DUT that is used to communicate with real DUT.
--
--------------------------------------------------------------------------------
-- Revision History:
--    11.3.2021   Created file
--    24.7.2022   Migrate to common repository, abstract away config function.
--                Add support for CTU CAN XL DUT.
--------------------------------------------------------------------------------

Library ctu_can_agents;
context ctu_can_agents.ieee_context;
context ctu_can_agents.agents_deps_context;

use ctu_can_agents.feature_test_agent_pkg.all;
use ctu_can_agents.test_controller_agent_pkg.all;
use ctu_can_agents.feature_test_agent_api_pkg.all;

entity feature_test_agent is
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
end entity;


architecture tb of feature_test_agent is

    signal bus_level                    : std_logic;

    -- Test node signals
    signal test_node_can_tx             : std_logic;
    signal test_node_can_rx             : std_logic;

    -- Signals with 1 ps delay (close to delta celay only)
    signal dut_can_tx_delta_delay       : std_logic;
    signal test_node_can_tx_delta_delay : std_logic;

    -- Delayed CAN bus signals
    signal dut_can_tx_delayed           : std_logic := '1';
    signal test_node_can_tx_delayed     : std_logic := '1';

    -- Forcing bus level value (ANDed bus level)
    signal force_bus_level_i            : boolean := false;
    signal force_bus_level_value        : std_logic := '0';

    -- Inverting bus value compared
    signal flip_bus_level_i             : boolean := false;

    -- Forcing CAN RX of only single node
    signal force_can_rx_dut             : boolean := false;
    signal force_can_rx_test_node       : boolean := false;
    signal force_can_rx_value           : std_logic := '0';

    -- Transceiver delays (on can_tx signal)
    signal can_tx_delay_dut             : time := 1 ns;
    signal can_tx_delay_test_node       : time := 1 ns;

    -- ANDed TX (expected bus level upon regular transmission)
    signal anded_tx                     : std_logic;

    component ctu_can_fd_top is
    generic (
        G_RX_BUF_SIZE           : natural range 32 to 4096  := 32;
        G_TXT_BUF_COUNT         : natural range 2 to 8      := 4;
        G_FILT_A_EN             : boolean                   := false;
        G_FILT_B_EN             : boolean                   := false;
        G_FILT_C_EN             : boolean                   := false;
        G_FILT_RANGE_EN         : boolean                   := false;
        G_TEST_REGS_EN          : boolean                   := true;
        G_TRAFFIC_CTRS_EN       : boolean                   := false;
        G_PARITY_EN             : boolean                   := false;
        G_ACTIVE_TS_BITS        : natural range 0 to 63     := 63;
        G_RESET_BUF_RAMS        : boolean                   := false;
        G_TECHNOLOGY            : natural                   := 0
    );
    port(
        -- Clock and Asynchronous reset
        clk_sys             : in std_logic;
        rst_n               : in std_logic;
        rst_n_out           : out std_logic;

        -- DFT support
        scan_mode           : in std_logic;

        -- Memory interface
        data_in             : in  std_logic_vector(31 downto 0);
        data_out            : out std_logic_vector(31 downto 0);
        adress              : in  std_logic_vector(15 downto 0);
        scs                 : in  std_logic;
        srd                 : in  std_logic;
        swr                 : in  std_logic;
        sbe                 : in  std_logic_vector(3 downto 0);

        -- Interrupt Interface
        int                 : out std_logic;

        -- CAN Bus Interface
        can_tx              : out std_logic;
        can_rx              : in  std_logic;

        -- Debug signals for testbench
        tp_rx_trigger_nbs   : out std_logic;
        tp_rx_trigger_wbs   : out std_logic;
        tp_tx_trigger       : out std_logic;

        -- Timestamp for time based transmission / reception
        timestamp           : in std_logic_vector(63 downto 0)
    );
    end component ctu_can_fd_top;

    component ctu_can_xl_top is
    generic (
        G_TX_FRAME_SLOT_CNT     : natural range 1 to 16     := 8;
        G_RX_FRAME_SLOT_CNT     : natural range 1 to 16     := 8;
        G_RX_CACHE_DEPTH        : natural                   := 4;
        G_TX_CACHE_DEPTH        : natural                   := 4;
        G_ACTIVE_TS_BITS        : natural range 0 to 63     := 63
    );
    port(
        -- Clock and Asynchronous reset
        clk_sys             : in std_logic;
        clk_can             : in std_logic;
        rst_n               : in std_logic;

        -- DFT support
        scan_mode           : in  std_logic;

        -- Memory interface (slave)
        mbs_write_data      : in  std_logic_vector(31 downto 0);
        mbs_data_out        : out std_logic_vector(31 downto 0);
        mbs_adress          : in  std_logic_vector(15 downto 0);
        mbs_scs             : in  std_logic;
        mbs_srd             : in  std_logic;
        mbs_swr             : in  std_logic;
        mbs_sbe             : in  std_logic_vector(3 downto 0);

        -- Memory interface (master)
        mbm_read_data       : in  std_logic_vector(31 downto 0);
        mbm_write_data      : out std_logic_vector(31 downto 0);
        mbm_adress          : out std_logic_vector(31 downto 0);
        mbm_scs             : out std_logic;
        mbm_srd             : out std_logic;
        mbm_swr             : out std_logic;
        mbm_sbe             : out std_logic_vector(3 downto 0);
        mbm_wait_request    : in  std_logic;
        mbm_read_data_valid : in  std_logic;

        -- Interrupt
        int                 : out std_logic;

        -- CAN Bus Interface
        can_tx              : out std_logic;
        can_rx              : in  std_logic;

        -- Timestamp for time based transmission / reception
        timestamp           : in std_logic_vector(63 downto 0)
    );
    end component ctu_can_xl_top;

begin

    ---------------------------------------------------------------------------
    -- Test node
    ---------------------------------------------------------------------------
    g_dut : if (G_DUT_NAME = "ctu_can_fd_top") generate

        i_test_node : ctu_can_fd_top
        generic map(
            -- Keep config hard-coded, it is enough that DUT is configurable!
            -- Everything is tested at the "DUT" instance!
            G_RX_BUF_SIZE        => 256,
            G_TXT_BUF_COUNT      => 4,
            G_FILT_A_EN          => false,
            G_FILT_B_EN          => false,
            G_FILT_C_EN          => false,
            G_FILT_RANGE_EN      => false,
            G_TRAFFIC_CTRS_EN    => true,
            G_PARITY_EN          => false,
            G_TECHNOLOGY         => 0
        )
        port map(
            -- Clock and Asynchronous reset
            clk_sys             => clk_sys,
            rst_n               => rst_n,

            -- DFT support
            scan_mode           => '0',

            -- Memory interface
            data_in             => mbs_write_data,
            data_out            => mbs_read_data,
            adress              => mbs_adress,
            scs                 => mbs_scs,
            srd                 => mbs_srd,
            swr                 => mbs_swr,
            sbe                 => mbs_sbe,

            -- Interrupt Interface - not needed for test node
            int                 => open,

            -- CAN Bus Interface
            can_tx              => test_node_can_tx,
            can_rx              => test_node_can_rx,

            -- Test probe, timestamp, not needed for test node!
            tp_rx_trigger_nbs   => test_node_tp_rx_trigger_nbs,
            tp_rx_trigger_wbs   => test_node_tp_rx_trigger_wbs,
            tp_tx_trigger       => test_node_tp_tx_trigger,

            timestamp           => (others => '1')
        );

    elsif (G_DUT_NAME = "ctu_can_xl_top") generate

        i_test_node : ctu_can_xl_top
        generic map (
            G_TX_FRAME_SLOT_CNT => 8,
            G_RX_FRAME_SLOT_CNT => 8,
            G_RX_CACHE_DEPTH    => 4,
            G_TX_CACHE_DEPTH    => 4,
            G_ACTIVE_TS_BITS    => 63
        )
        port map(
            -- Clock and Asynchronous reset
            clk_sys             => clk_sys,
            clk_can             => clk_can,
            rst_n               => rst_n,

            -- DFT support
            scan_mode           => '0',

            -- Memory interface (slave)
            mbs_write_data      => mbs_write_data,
            mbs_data_out        => mbs_read_data,
            mbs_adress          => mbs_adress,
            mbs_scs             => mbs_scs,
            mbs_srd             => mbs_srd,
            mbs_swr             => mbs_swr,
            mbs_sbe             => mbs_sbe,

            -- Memory interface (master)
            mbm_read_data       => mbm_read_data,
            mbm_write_data      => mbm_write_data,
            mbm_adress          => mbm_adress,
            mbm_scs             => mbm_scs,
            mbm_srd             => mbm_srd,
            mbm_swr             => mbm_swr,
            mbm_sbe             => mbm_sbe,
            mbm_wait_request    => mbm_wait_request,
            mbm_read_data_valid => mbm_read_data_valid,

            -- Interrupt
            int                 => open,

            -- CAN Bus Interface
            can_tx              => test_node_can_tx,
            can_rx              => test_node_can_rx,

            -- Timestamp for time based transmission / reception
            timestamp           => (others => '0')
        );

    else generate

        process
        begin
            report "Unsupported G_DUT_NAME: " & G_DUT_NAME severity failure;
            wait;
        end process;

    end generate;

    ---------------------------------------------------------------------------
    -- Comunication receiver process
    ---------------------------------------------------------------------------
    p_receiver : process
        variable cmd        : integer;
        variable reply_code : integer;
        variable tmp        : integer;
        variable tmp_logic  : std_logic;
    begin
        receive_start(default_channel, G_COM_ID);

        -- Command is sent as message type
        cmd := com_channel_data.get_msg_code;
        reply_code := C_REPLY_CODE_OK;

        case cmd is
        when FEATURE_TEST_AGNT_FORCE_BUS =>
            force_bus_level_value <= com_channel_data.get_param;
            force_bus_level_i <= true;

        when FEATURE_TEST_AGNT_RELEASE_BUS =>
            force_bus_level_i <= false;
            flip_bus_level_i <= false;

        when FEATURE_TEST_AGNT_FORCE_CAN_RX =>
            tmp := com_channel_data.get_param;
            force_can_rx_value <= com_channel_data.get_param;
            if (tmp = 0) then
                force_can_rx_dut <= true;
            else
                force_can_rx_test_node <= true;
            end if;

        when FEATURE_TEST_AGNT_RELEASE_CAN_RX =>
            force_can_rx_dut <= false;
            force_can_rx_test_node <= false;

        when FEATURE_TEST_AGNT_SET_TRV_DELAY =>
            tmp := com_channel_data.get_param;
            if (tmp = 0) then
                can_tx_delay_dut <= com_channel_data.get_param;
            else
                can_tx_delay_test_node <= com_channel_data.get_param;
            end if;

        when FEATURE_TEST_AGNT_CHECK_BUS_LEVEL =>
            tmp_logic := com_channel_data.get_param;
            check_m(tmp_logic = bus_level, FEATURE_TEST_AGENT_TAG &
                    "Bus level value shoul be:" & std_logic'image(tmp_logic));

        when FEATURE_TEST_AGNT_CHECK_CAN_TX =>
            tmp := com_channel_data.get_param;
            tmp_logic := com_channel_data.get_param;
            if (tmp = 0) then
                check_m(tmp_logic = dut_can_tx, "DUT CAN TX");
            else
                check_m(tmp_logic = test_node_can_tx, "Test node CAN TX");
            end if;

        when FEATURE_TEST_AGNT_GET_CAN_TX =>
            tmp := com_channel_data.get_param;
            if (tmp = 0) then
                com_channel_data.set_param(dut_can_tx);
            else
                com_channel_data.set_param(test_node_can_tx);
            end if;

        when FEATURE_TEST_AGNT_GET_CAN_RX =>
            tmp := com_channel_data.get_param;
            if (tmp = 0) then
                com_channel_data.set_param(dut_can_rx);
            else
                com_channel_data.set_param(test_node_can_rx);
            end if;

        when FEATURE_TEST_AGNT_FLIP_BUS =>
            flip_bus_level_i <= true;

        when others =>
            info_m("Invalid message type: " & integer'image(cmd));
            reply_code := C_REPLY_CODE_ERR;

        end case;
        receive_finish(default_channel, reply_code);
    end process;

    ---------------------------------------------------------------------------
    -- Signal delaying
    ---------------------------------------------------------------------------
    i_tx_delay_dut : entity ctu_can_agents.feature_test_agent_signal_delayer
    generic map (
        NSAMPLES    => 32
    )
    port map (
        input       => dut_can_tx_delta_delay,
        delay       => can_tx_delay_dut,
        delayed     => dut_can_tx_delayed
    );

    i_tx_delay_test_node : entity ctu_can_agents.feature_test_agent_signal_delayer
    generic map (
        NSAMPLES    => 32
    )
    port map (
        input       => test_node_can_tx_delta_delay,
        delay       => can_tx_delay_test_node,
        delayed     => test_node_can_tx_delayed
    );

    ---------------------------------------------------------------------------
    -- On RTL, can_tx is 'U' at time zero, and it gets defined value when
    -- rst_n is asserted. Thus 'U' -> 1 event occurs in non-zero time.
    -- On Xilinx gate level sims, having rst_n = 'U' first few nanoseconds of
    -- simulation does cause output of flop in reset synchronizer to be '0',
    -- not 'U'. Thus synchronized reset is '0' from time 0, and there is no
    -- event on it when rst_n input gets asserted non-'U' value! This causes
    -- can_tx to be set to '1' from time 0 of simulation. As consequence of
    -- this, signal delayer will ignore the first event on can_tx in time 0,
    -- and will keep its output at 0!
    ---------------------------------------------------------------------------
    dut_can_tx_delta_delay <= dut_can_tx after 1 ps;
    test_node_can_tx_delta_delay <= test_node_can_tx after 1 ps;

    ---------------------------------------------------------------------------
    -- Bus level and RX signal of each node
    ---------------------------------------------------------------------------
    anded_tx <= dut_can_tx_delayed and test_node_can_tx_delayed;

    bus_level <= force_bus_level_value when force_bus_level_i else
                        not (anded_tx) when flip_bus_level_i else
                             anded_tx;

    dut_can_rx <= force_can_rx_value when force_can_rx_dut else
                  bus_level;

    test_node_can_rx <= force_can_rx_value when force_can_rx_test_node else
                        bus_level;

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Test control process
    --
    -- Waits on start request from Test controller agent and runs a test.
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    p_test : process
    begin
        wait until feature_start = '1';

        -- Pre-set test to be "passed", any error will make it fail
        ctu_vip_test_result.set(true);

        -- Initialize and execute feature test
        init_feature_test(default_channel);
        exec_feature_test(config_db.get("TEST_NAME"), default_channel);

        -- Signal test is done.
        if (ctu_vip_test_result.get) then
            feature_result <= '1';
        else
            feature_result <= '0';
        end if;

        wait for 0 ns;
        feature_done <= '1';
        wait until feature_start = '0';
        feature_done <= '0';
        wait for 0 ns;

    end process;

end architecture;