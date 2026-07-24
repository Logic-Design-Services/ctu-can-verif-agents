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
--    Test controller agent - Controls rest of CTU CAN FD / XL VIPs
--
--------------------------------------------------------------------------------
-- Revision History:
--    12.3.2021   Created file
--    23.7.2026   Adapt for need of CTU CAN XL testbench.
--------------------------------------------------------------------------------

library ctu_can_agents;
context ctu_can_agents.ieee_context;
context ctu_can_agents.agents_deps_context;

use ctu_can_agents.test_controller_agent_pkg.all;
use ctu_can_agents.timestamp_agent_pkg.all;
use ctu_can_agents.mem_bus_master_agent_pkg.all;
use ctu_can_agents.mem_bus_slave_agent_pkg.all;
use ctu_can_agents.interrupt_agent_pkg.all;
use ctu_can_agents.clk_gen_agent_pkg.all;
use ctu_can_agents.reset_agent_pkg.all;
use ctu_can_agents.can_agent_pkg.all;

entity test_controller_agent is
    generic (
        G_COM_ID                : natural;

        -- Static configuration (resolved at elaboration)
        G_TEST_NAME             : string;
        G_TEST_TYPE             : string
    );
    port (
        -- VIP test control / status signals
        test_start              : in  std_logic;
        test_done               : out std_logic := '0';
        test_success            : out std_logic := '0';

        -- PLI interface for communication with compliance test library
        pli_clk                 : out std_logic;
        pli_req                 : in  std_logic;
        pli_ack                 : out std_logic := '0';
        pli_cmd                 : in  std_logic_vector(7 downto 0);
        pli_dest                : in  std_logic_vector(7 downto 0);
        pli_data_in             : in  std_logic_vector(63 downto 0);
        pli_data_in_2           : in  std_logic_vector(63 downto 0);
        pli_str_buf_in          : in  std_logic_vector(511 downto 0);
        pli_data_out            : out std_logic_vector(63 downto 0);

        -- PLI interface for giving test control to compliance test library
        pli_control_req         : out std_logic := '0';
        pli_control_gnt         : in  std_logic
    );
end entity;

architecture tb of test_controller_agent is

    signal seed_applied : boolean := false;

begin

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Main test process
    --
    -- Gives commands to other processes / agents like so:
    --
    -- Feature tests:
    --   Invoke Feature test top which runs the test and gives back result
    --
    -- Compliance tests and Reference tests:
    --   Pass control to ISO compliance library over PLI
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    p_main_test : process
        variable test_success_i : std_logic := '0';
        variable init_timestamp : std_logic_vector(63 downto 0);
    begin
        wait for 1 ns;
        wait until test_start = '1';

        -- Apply random seed, but only if it was not applied before.
        -- If there are multiple iterations, we want different random data
        -- to be used for each one!
        if (seed_applied = false) then
            apply_rand_seed(config_db.get("seed"));
            seed_applied <= true;
        end if;

        -----------------------------------------------------------------------
        -- Start the test (give command to corresponding test type agent)
        -----------------------------------------------------------------------
        if (G_TEST_TYPE = "compliance" or G_TEST_TYPE = "reference") then
            cosim_start <= '1';
            wait until cosim_done = '1';
            test_success_i := pli_test_result;

        elsif (G_TEST_TYPE = "feature") then
            feature_start <= '1';
            wait until feature_done = '1';
            test_success_i := feature_result;
        else
            error_m("Unknown test type!");
        end if;

        cosim_start <= '0';
        feature_start <= '0';
        wait for 5 ns;

        test_done <= '1';
        test_success <= test_success_i;

        info_m("******************************************");
        if (test_success_i = '1') then
            info_m("CTU CAN FD VIP: Test PASSED");
        else
            error_m("CTU CAN FD VIP: Test FAILED");
        end if;
        info_m("******************************************");

        wait until test_start = '0';
        test_done <= '0';

    end process;


    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Cosimulation (for compliance and reference tests)
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    g_cosimulation : if (G_TEST_TYPE = "compliance" or G_TEST_TYPE = "reference") generate

        ---------------------------------------------------------------------------
        -- Cosimulation handling process
        --
        -- Passes control to Cosimulation plugin linked to simulator.
        -- Communication with this plugin is done via PLI interface.
        ---------------------------------------------------------------------------
        p_cosimulation_control : process
        begin
            wait until cosim_start = '1';

            -----------------------------------------------------------------------
            -- Give control over the TB to Cosimulation plugin which runs the
            -- test and operates on other agents.
            -----------------------------------------------------------------------
            info_m("Requesting TB control from Cosimulation plugin via PLI...");
            pli_control_req <= '1';
            wait for 1 ns;

            if (pli_control_gnt /= '1') then
                wait until pli_control_gnt = '1' for 10 ns;
            end if;

            wait for 0 ns;
            check_m(pli_control_gnt = '1',
                    "Cosimulation plugin took over simulation control!");
            wait for 0 ns;

            info_m("Waiting till Cosimulation plugin is done running test...");
            wait until (pli_test_end = '1');
            cosim_done <= '1';
            info_m("Cosimulation plugin signals test has ended");

            wait for 50 ns;
            pli_control_req <= '0';
            cosim_done <= '0';
            wait for 50 ns;
        end process;

        -----------------------------------------------------------------------
        -- Listen on PLI commands and send them to individual agents!
        -----------------------------------------------------------------------
        p_pli_listener : process
            -- TODO: This is temporary hack just for the TB to compile !
            --       Must extend the PLI interface to provide the address of
            --       the agent that it wants to talk to !
            --       This could be somehow provided via generics of this
            --       module, but that is wrong! This information must be known
            --       by the test sequence (as it must be aware of agents mappings
            --       and connections to know what functionality to reach)!
            variable com_id : integer := 0;
        begin

            -------------------------------------------------------------------
            -- Poll on for pli_req = '1'
            -------------------------------------------------------------------
            wait until (pli_req = '1');
            wait for 1 ps;

            -------------------------------------------------------------------
            -- Process command (and get answer in case of read)
            -------------------------------------------------------------------
            case pli_dest is
            when PLI_DEST_RES_GEN_AGENT =>
                pli_process_rst_agnt(pli_cmd, pli_data_out, pli_data_in,
                                     default_channel, com_id);

            when PLI_DEST_CLK_GEN_AGENT =>
                pli_process_clk_agent(pli_cmd, pli_data_out, pli_data_in,
                                      default_channel, com_id);

            when PLI_DEST_MEM_BUS_MASTER_AGENT =>
                pli_process_mem_bus_master_agent(pli_cmd, pli_data_out, pli_data_in,
                                                 default_channel, com_id);

            when PLI_DEST_CAN_AGENT =>
                pli_process_can_agent(pli_cmd, pli_data_out, pli_data_in,
                    pli_data_in_2, pli_str_buf_in, default_channel, com_id);

            when PLI_DEST_TEST_CONTROLLER_AGENT =>
                pli_process_test_agent(pli_cmd, pli_data_out, pli_data_in,
                    pli_str_buf_in, pli_test_end, pli_test_result);

            -- TODO: Need to add Memory bus slave, DIO agent and Memory model!

            when OTHERS =>
                error_m("Unknown agent destination: " & to_hstring(pli_dest));
            end case;

            wait for 1 ps;

            -------------------------------------------------------------------
            -- Issue pli_ack = '1'
            -------------------------------------------------------------------
            pli_ack <= '1';
            wait for 1 ps;

            -------------------------------------------------------------------
            -- Finish the PLI handshake
            -------------------------------------------------------------------
            wait until (pli_req = '0');
            wait for 1 ps;
            pli_ack <= '0';
            wait for 1 ps;

        end process;


        -----------------------------------------------------------------------
        -- PLI clock generation
        --
        -- Create clock for synchronous communication over PLI interface.
        -- Although compliance test library executes test in different context,
        -- it needs to synchronize with simulator context. To do this,
        -- compliance test library passes all messages to TB via shared memory,
        -- which is read synchronously with PLI callbacks!
        -----------------------------------------------------------------------
        p_pli_clk_gen : process
        begin
            pli_clk <= '1';
            wait for 5 ns;
            pli_clk <= '0';
            wait for 5 ns;
        end process;

    end generate;

    ---------------------------------------------------------------------------
    -- Checks
    ---------------------------------------------------------------------------
    assert G_TEST_TYPE = "feature" or G_TEST_TYPE = "compliance" or G_TEST_TYPE = "reference"
        report "Unsupported test type: " & G_TEST_TYPE & ", choose one of: feature, compliance, reference"
        severity failure;

    ---------------------------------------------------------------------------
    -- Watchdog
    ---------------------------------------------------------------------------
    process
        -- TODO: Query from Config DB
        variable timeout : time := 10 ms;
    begin
        wait for 1 ns;
        wait for timeout - 1 ns;
        report "Timeout reached!" severity failure;
    end process;


end architecture;
