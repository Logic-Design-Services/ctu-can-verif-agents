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
--    Package with API for CAN bus agent.
--
--------------------------------------------------------------------------------
-- Revision History:
--    26.1.2020   Created file
--    04.2.2021   Adjusted to work without Vunits COM library.
--    20.7.2026   Added configurable ID.
--------------------------------------------------------------------------------

library ctu_can_agents;
context ctu_can_agents.ieee_context;
context ctu_can_agents.agents_deps_context;

package can_agent_pkg is

    ---------------------------------------------------------------------------
    -- CAN agent component
    ---------------------------------------------------------------------------
    component can_agent is
    generic(
        G_DRIVER_FIFO_DEPTH     : natural := 128;
        G_MONITOR_FIFO_DEPTH    : natural := 128;
        G_COM_ID                : natural := C_CAN_AGENT_DEF_ID
    );
    port (
        -- CAN bus connections
        can_tx   :   in     std_logic;
        can_rx   :   out    std_logic := '1'
    );
    end component;

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- CAN agent API
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------

    constant C_MAX_MSG_LENGTH : natural := 100;
    constant C_EMPTY_STRING : string(1 to C_MAX_MSG_LENGTH) := (OTHERS => ' ');

    -- Driver FIFO entry
    type t_can_driver_entry is record

        -- Value to be driven
        value           :   std_logic;

        -- Time for which to drive this value
        drive_time      :   time;

        -- Print message when driving of this item starts
        print_msg       :   boolean;

        -- Message to print
        msg             :   string(1 to C_MAX_MSG_LENGTH);
    end record;

    -- Simple driver entry (no message)
    type t_can_driver_entry_simple is record

        -- Value to be driven
        value           :   std_logic;

        -- Time for which to drive this value
        drive_time      :   time;
    end record;

    -- Monitor FIFO entry
    type t_can_monitor_entry is record

        -- Value to be monitored
        value           :   std_logic;

        -- Time for which to monitor this value
        monitor_time    :   time;

        -- Sample time after which the value is sampled. This must be lower than
        -- monitor time!
        sample_rate     :   time;

        -- Print message when monitoring of this item starts
        print_msg       :   boolean;

        -- Message which to print
        msg             :   string(1 to C_MAX_MSG_LENGTH);
    end record;

    -- Trigger type for monitor (when will monitor start monitoring)
    type t_can_monitor_trigger is (
        trig_immediately,
        trig_can_rx_rising_edge,
        trig_can_rx_falling_edge,
        trig_can_tx_rising_edge,
        trig_can_tx_falling_edge,
        trig_time_elapsed,
        trig_driver_start,
        trig_driver_stop
    );

    -- Current monitor state
    type t_can_monitor_state is(
        mon_disabled,
        mon_waiting_for_trigger,
        mon_running,
        mon_passed,
        mon_failed
    );

    ---------------------------------------------------------------------------
    -- Message print helpers
    ---------------------------------------------------------------------------
    procedure can_agent_info_m(
        constant    id          : in    natural;
        constant    msg         : in    string
    );
    procedure can_agent_debug_m(
        constant    id          : in    natural;
        constant    msg         : in    string
    );

    ---------------------------------------------------------------------------
    -- Start CAN Agent driver.
    --
    -- @param channel       Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure can_agent_driver_start(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    );

    ---------------------------------------------------------------------------
    -- Stop CAN Agent driver. If driving of an item is in progress, this item
    -- is finished first and driver stops only then.
    --
    -- @param channel       Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure can_agent_driver_stop(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    );

    ---------------------------------------------------------------------------
    -- Flush CAN Agent driver FIFO. All items which remain to be driven will
    -- be effectively erased from FIFO
    --
    -- @param channel       Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure can_agent_driver_flush(
         signal     channel     : inout t_com_channel;
         constant   id          : in    natural
    );

    ---------------------------------------------------------------------------
    -- Check if driving of items is in progress.
    --
    -- @param channel       Channel on which to send the request
    -- @param progress  True when driving is in progres, false if not.
    ---------------------------------------------------------------------------
    procedure can_agent_driver_get_progress(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    progress    : out   boolean
    );

    ---------------------------------------------------------------------------
    -- Get actually driven value by driver.
    --
    -- @param channel       Channel on which to send the request
    -- @param driven_val    Currently driven value by driver.
    ---------------------------------------------------------------------------
    procedure can_agent_driver_get_driven_val(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    driven_val  : out   std_logic
    );

    ---------------------------------------------------------------------------
    -- Push item into driver FIFO.
    --
    -- @param channel       Channel on which to send the request
    -- @param item          Item to be pushed.
    ---------------------------------------------------------------------------
    procedure can_agent_driver_push_item(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    item        : in    t_can_driver_entry
    );

    ---------------------------------------------------------------------------
    -- Wait till driver finishes driving of all items. If timeout is reached
    -- before all items are driven, this function returns.
    --
    -- @param channel       Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure can_agent_driver_wait_finish(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    );

    ---------------------------------------------------------------------------
    -- Set timeout for waiting till driver finishes driving of all items.
    --
    -- @param channel       Channel on which to send the request
    -- @param timeout       Timeout value to set.
    ---------------------------------------------------------------------------
    procedure can_agent_driver_set_wait_timeout(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    timeout     : in    time
    );

    ---------------------------------------------------------------------------
    -- Push value into driver FIFO.
    --
    -- @param channel       Channel on which to send the request
    -- @param value         Value to be driven.
    -- @param time          Time for which drive this value.
    ---------------------------------------------------------------------------
    procedure can_agent_driver_push_value(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    value       : in    std_logic;
        constant    time        : in    time
    );

    ---------------------------------------------------------------------------
    -- Push value into driver FIFO.
    --
    -- @param channel       Channel on which to send the request
    -- @param value         Value to be driven.
    -- @param time          Time for which drive this value.
    -- @param msg           Message to be printed when driving of this value
    --                      starts.
    ---------------------------------------------------------------------------
    procedure can_agent_driver_push_value(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    value       : in    std_logic;
        constant    time        : in    time;
        constant    msg         : in    string
    );

    ---------------------------------------------------------------------------
    -- Drive single item. This producedure will push the item into driver FIFO,
    -- enable the driver and wait until this item is driven. If other items
    -- are present in driver FIFO, these items will be driven first.
    --
    -- @param channel       Channel on which to send the request
    -- @param item          Item to be driven.
    ---------------------------------------------------------------------------
    procedure can_agent_driver_drive_single_item(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    item        : in    t_can_driver_entry
    );

    ---------------------------------------------------------------------------
    -- Drive all items from driver FIFO. This procedure will enable driver and
    -- wait until all items in driver FIFO are driven.
    --
    -- @param channel       Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure can_agent_driver_drive_all_items(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    );

    ---------------------------------------------------------------------------
    -- Configure waiting of driver for monitor. If enabled, when driver is
    -- enabled, driving first item from driver FIFO does not start immediately,
    -- but only when monitor starts running. This allows synchronisation of
    -- driver/monitor when DUT is transmitter!
    --
    -- @param channel       Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure can_agent_driver_set_wait_for_monitor(
        signal      channel         : inout t_com_channel;
        constant    id              : in    natural;
        constant    wait_for_mon    : in    boolean
    );

    ---------------------------------------------------------------------------
    -- Drive single value. This producedure will push the item into driver FIFO,
    -- enable the driver and wait until this item is driven. If other items
    -- are present in driver FIFO, these items will be driven first.
    --
    -- @param channel       Channel on which to send the request
    -- @param value         Value to be driven.
    -- @param time          Time for which to drive this value.
    ---------------------------------------------------------------------------
    procedure can_agent_driver_drive_value(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    value       : in    std_logic;
        constant    time        : in    time
    );

    ---------------------------------------------------------------------------
    -- Drive single value. This producedure will push the item into driver FIFO,
    -- enable the driver and wait until this item is driven. If other items
    -- are present in driver FIFO, these items will be driven first.
    --
    -- @param channel       Channel on which to send the request
    -- @param value         Value to be driven.
    -- @param time          Time for which to drive this value.
    -- @param msg           Message to be printed when driving of this value
    --                      starts.
    ---------------------------------------------------------------------------
    procedure can_agent_driver_drive_value(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    value       : in    std_logic;
        constant    time        : in    time;
        constant    msg         : in    string
    );

    ---------------------------------------------------------------------------
    -- Start Can agent monitor.
    --
    -- @param channel       Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure can_agent_monitor_start(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    );

    ---------------------------------------------------------------------------
    -- Stop Can agent monitor.
    --
    -- @param channel       Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure can_agent_monitor_stop(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    );

    ---------------------------------------------------------------------------
    -- Flush monitor FIFO. All item in Monitor FIFO which were not monitored
    -- will be effectively erased.
    --
    -- @param channel       Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure can_agent_monitor_flush(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    );

    --------------------------------------------------------------------------
    -- Get state of Monitor. Monitor can be in one of following states:
    --  Idle
    --  Waiting for trigger
    --  Running
    --  Passed
    --  Failed
    --
    -- @param channel       Channel on which to send the request
    -- @param state         State of the monitor.
    ---------------------------------------------------------------------------
    procedure can_agent_monitor_get_state(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    state       : out   t_can_monitor_state
    );

    --------------------------------------------------------------------------
    -- Get currently monitored value.
    --
    -- @param channel       Channel on which to send the request
    -- @param monitored_val Value which is being monitored.
    ---------------------------------------------------------------------------
    procedure can_agent_monitor_get_monitored_val(
        signal      channel        : inout t_com_channel;
        constant    id             : in    natural;
        variable    monitored_val  : out   std_logic
    );

    --------------------------------------------------------------------------
    -- Push item into Monitor FIFO.
    --
    -- @param channel       Channel on which to send the request
    -- @param item          Item to be pushed into monitor FIFO.
    ---------------------------------------------------------------------------
    procedure can_agent_monitor_push_item(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    item        : in    t_can_monitor_entry
    );

    --------------------------------------------------------------------------
    -- Set wait timeout for driver.
    --
    -- @param channel       Channel on which to send the request
    -- @param timeout       Timeout to be set on CAN driver.
    ---------------------------------------------------------------------------
    procedure can_agent_monitor_set_wait_timeout(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    timeout     : in    time
    );

    --------------------------------------------------------------------------
    -- If timeout is reached before all items are monitored, this function
    -- returns.
    --
    -- @param channel       Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure can_agent_monitor_wait_finish(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    );

    --------------------------------------------------------------------------
    -- Monitor single item. This function pushes item into monitor FIFO and it
    -- waits until this item is monitored. If other items are in monitor FIFO,
    -- these will be monitored first. If timeout occurs before this item is
    -- monitored, this function returns.
    --
    -- @param channel       Channel on which to send the request
    -- @param item          Item to be monitored.
    ---------------------------------------------------------------------------
    procedure can_agent_monitor_single_item(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    item        : in    t_can_monitor_entry
    );

    --------------------------------------------------------------------------
    -- Enable monitor (Move it from "Idle" to "Waiting for trigger") and wait
    -- until it monitors all items. If timeout occurs before all items were
    -- monitored, this function returns.
    --
    -- @param channel       Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure can_agent_monitor_all_items(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    );

    --------------------------------------------------------------------------
    -- Configure Monitor trigger. Trigger CAN be one of following sources:
    --   Trigger immediately (Go from Idle right to Running)
    --   Trigger on rising edge on can_rx
    --   Trigger on falling edge on can_rx
    --   Trigger on rising edge on can_tx
    --   Trigger on falling edge on can_tx
    --   Trigger after time (configurable by TODO) elapsed.
    --   Trigger when driver starts driving
    --   Trigger when driver stops driving.
    --
    -- @param channel       Channel on which to send the request
    -- @param trigger       Trigger to configure
    ---------------------------------------------------------------------------
    procedure can_agent_monitor_set_trigger(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    trigger     : in    t_can_monitor_trigger
    );

    --------------------------------------------------------------------------
    -- Get trigger which is configured in CAN agent monitor.
    --
    -- @param channel       Channel on which to send the request
    -- @param trigger       Trigger to obtain
    ---------------------------------------------------------------------------
    procedure can_agent_monitor_get_trigger(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    trigger     : out   t_can_monitor_trigger
    );

    --------------------------------------------------------------------------
    -- Set sample rate for CAN agent monitor. With this sample rate, monitor
    -- samples can_tx during monitoring of an item from monitor FIFO. Time for
    -- which each item from monitor FIFO is monitored must be a multiple of
    -- monitor sample rate.
    --
    -- @param channel       Channel on which to send the request
    -- @param sample_rate   Sample rate to set
    ---------------------------------------------------------------------------
    procedure can_agent_monitor_set_sample_rate(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    sample_rate : in    time
    );

    --------------------------------------------------------------------------
    -- Get CAN agent monitor sample rate.
    --
    -- @param channel       Channel on which to send the request
    -- @param sample_rate   Obtained sample rate
    ---------------------------------------------------------------------------
    procedure can_agent_monitor_get_sample_rate(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    sample_rate : out   time
    );

    --------------------------------------------------------------------------
    -- Push value into CAN agent monitor FIFO.
    --
    -- @param channel       Channel on which to send the request
    -- @param value         Value to be monitored
    -- @param mon_time      Time for which to monitor this value.
    ---------------------------------------------------------------------------
    procedure can_agent_monitor_push_value(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    value       : in    std_logic;
        constant    mon_time    : in    time
    );

    --------------------------------------------------------------------------
    -- Push value into CAN agent monitor FIFO.
    --
    -- @param channel       Channel on which to send the request
    -- @param value         Value to be monitored
    -- @param mon_time      Time for which to monitor this value.
    -- @param msg           Message to be printed when monitoring of this
    --                      value starts.
    ---------------------------------------------------------------------------
    procedure can_agent_monitor_push_value(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    value       : in    std_logic;
        constant    mon_time    : in    time;
        constant    msg         : in    string
    );

    ---------------------------------------------------------------------------
    -- Monitor single value by CAN agent monitor. If other values are in
    -- monitor FIFO, these will be monitored first. If timeout elapses, then
    -- this function will return immediately.
    --
    -- @param channel       Channel on which to send the request
    -- @param value         Value to be monitored
    -- @param mon_time      Time for which to monitor this value.
    ---------------------------------------------------------------------------
    procedure can_agent_monitor_monitor_value(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    value       : in    std_logic;
        constant    mon_time    : in    time
    );

    ---------------------------------------------------------------------------
    -- Monitor single value by CAN agent monitor. If other values are in
    -- monitor FIFO, these will be monitored first. If timeout elapses, then
    -- this function will return immediately.
    --
    -- @param channel       Channel on which to send the request
    -- @param value         Value to be monitored
    -- @param mon_time      Time for which to monitor this value.
    -- @param msg           Message to be printed when monitoring starts.
    ---------------------------------------------------------------------------
    procedure can_agent_monitor_monitor_value(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    value       : in    std_logic;
        constant    mon_time    : in    time;
        constant    msg         : in    string
    );

    ---------------------------------------------------------------------------
    -- Check result of previous monitoring run (Idle, Waiting For Trigger,
    -- Passed/Failed transition). Reports error if monitor ended in "Failed"
    -- state.
    --
    -- @param channel       Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure can_agent_monitor_check_result(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    );


    ---------------------------------------------------------------------------
    -- Set monitor delay. When monitor trigger occurs and its operation starts,
    -- monitor waits additional delay before driving first item.
    --
    -- This delay should correspond to input delay of CAN node and can be
    -- used to correct shift of sequence on can_tx and can_rx. Input delay of
    -- CAN node is caused by resynchronisation of input signal!
    --
    -- @param channel       Channel on which to send the request
    ---------------------------------------------------------------------------
    procedure can_agent_monitor_set_input_delay(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    input_delay : in    time
    );


    ---------------------------------------------------------------------------
    -- Enable/Disable feedback from can_tx to can_rx. This allows DUT to see
    -- its own transmitted error/overload frames without necessity to insert
    -- error frames also to driver!
    --
    -- @param channel       Channel on which to send the request
    -- @param enable        Enable/Disable feedback.
    ---------------------------------------------------------------------------
    procedure can_agent_configure_tx_to_rx_feedback(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    enable      : in    boolean
    );

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Private declarations
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------

    -- Supported commands for CAN agent (sent as message types)
    constant CAN_AGNT_CMD_DRIVER_START                  : integer := 0;
    constant CAN_AGNT_CMD_DRIVER_STOP                   : integer := 1;
    constant CAN_AGNT_CMD_DRIVER_FLUSH                  : integer := 2;
    constant CAN_AGNT_CMD_DRIVER_GET_PROGRESS           : integer := 3;
    constant CAN_AGNT_CMD_DRIVER_GET_DRIVEN_VAL         : integer := 4;
    constant CAN_AGNT_CMD_DRIVER_PUSH_ITEM              : integer := 5;
    constant CAN_AGNT_CMD_DRIVER_SET_WAIT_TIMEOUT       : integer := 6;
    constant CAN_AGNT_CMD_DRIVER_WAIT_FINISH            : integer := 7;
    constant CAN_AGNT_CMD_DRIVER_DRIVE_SINGLE_ITEM      : integer := 8;
    constant CAN_AGNT_CMD_DRIVER_DRIVE_ALL_ITEMS        : integer := 9;

    constant CAN_AGNT_CMD_MONITOR_START                 : integer := 10;
    constant CAN_AGNT_CMD_MONITOR_STOP                  : integer := 11;
    constant CAN_AGNT_CMD_MONITOR_FLUSH                 : integer := 12;
    constant CAN_AGNT_CMD_MONITOR_GET_STATE             : integer := 13;
    constant CAN_AGNT_CMD_MONITOR_GET_MONITORED_VAL     : integer := 14;
    constant CAN_AGNT_CMD_MONITOR_PUSH_ITEM             : integer := 15;
    constant CAN_AGNT_CMD_MONITOR_SET_WAIT_TIMEOUT      : integer := 16;
    constant CAN_AGNT_CMD_MONITOR_WAIT_FINISH           : integer := 17;
    constant CAN_AGNT_CMD_MONITOR_MONITOR_SINGLE_ITEM   : integer := 18;
    constant CAN_AGNT_CMD_MONITOR_MONITOR_ALL_ITEMS     : integer := 19;

    constant CAN_AGNT_CMD_MONITOR_SET_TRIGGER           : integer := 20;
    constant CAN_AGNT_CMD_MONITOR_GET_TRIGGER           : integer := 21;

    constant CAN_AGNT_CMD_MONITOR_SET_SAMPLE_RATE       : integer := 22;
    constant CAN_AGNT_CMD_MONITOR_GET_SAMPLE_RATE       : integer := 23;

    constant CAN_AGNT_CMD_MONITOR_CHECK_RESULT          : integer := 24;

    constant CAN_AGNT_CMD_MONITOR_SET_INPUT_DELAY       : integer := 25;

    constant CAN_AGNT_CMD_TX_RX_FEEDBACK_ENABLE         : integer := 26;
    constant CAN_AGNT_CMD_TX_RX_FEEDBACK_DISABLE        : integer := 27;

    constant CAN_AGNT_CMD_SET_WAIT_FOR_MONITOR          : integer := 28;

    -- Tag for messages
    constant CAN_AGENT_TAG : string := "CAN Agent: ";

end package;


package body can_agent_pkg is

    ---------------------------------------------------------------------------
    -- Message print helpers
    ---------------------------------------------------------------------------
    procedure can_agent_info_m(
        constant    id          : in    natural;
        constant    msg         : in    string
    ) is begin
        info_m(CAN_AGENT_TAG & "(" & natural'image(id) & "): " & msg);
    end procedure;

    procedure can_agent_debug_m(
        constant    id          : in    natural;
        constant    msg         : in    string
    ) is begin
        debug_m(CAN_AGENT_TAG & "(" & natural'image(id) & "): " & msg);
    end procedure;


    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- CAN generator agent API implementation
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------

    procedure can_agent_driver_start(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    ) is
    begin
        can_agent_info_m(id, "Starting driver");
        send(channel, id, CAN_AGNT_CMD_DRIVER_START);
        can_agent_debug_m(id, " Driver started");
    end procedure;


    procedure can_agent_driver_stop(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    ) is
    begin
        can_agent_info_m(id, "Stopping driver");
        send(channel, id, CAN_AGNT_CMD_DRIVER_STOP);
        can_agent_debug_m(id, "Driver stopped");
    end procedure;


    procedure can_agent_driver_flush(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    ) is
    begin
        can_agent_info_m(id, "Flushing driver FIFO");
        send(channel, id, CAN_AGNT_CMD_DRIVER_FLUSH);
        can_agent_debug_m(id, "CAN agent driver FIFO flushed");
    end procedure;


    procedure can_agent_driver_get_progress(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    progress    : out   boolean
    ) is
    begin
        can_agent_info_m(id, "Getting driver progress");
        send(channel, id, CAN_AGNT_CMD_DRIVER_GET_PROGRESS);
        progress := com_channel_data.get_param;
        wait for 0 ns;
        can_agent_debug_m(id, "Driver progress got");
    end procedure;


    procedure can_agent_driver_get_driven_val(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    driven_val  : out   std_logic
    ) is
    begin
        can_agent_info_m(id, "Getting driven value");
        send(channel, id, CAN_AGNT_CMD_DRIVER_GET_DRIVEN_VAL);
        driven_val := com_channel_data.get_param;
        can_agent_debug_m(id, "Driven value got:");
    end procedure;


    procedure can_agent_driver_push_item(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    item        : in    t_can_driver_entry
    ) is
    begin
        -- Debug also upon start since pushing single frame generates
        -- way too many logs
        can_agent_debug_m(id, "Pushing item into driver FIFO (" &
                                std_logic'image(item.value) & ", " &
                                time'image(item.drive_time) & ")");

        com_channel_data.set_param(item.value);
        com_channel_data.set_param(item.drive_time);
        com_channel_data.set_param(item.print_msg);
        if (item.print_msg) then
            com_channel_data.set_param(item.msg);
        end if;
        send(channel, id, CAN_AGNT_CMD_DRIVER_PUSH_ITEM);

        can_agent_debug_m(id, "Item pushed into driver FIFO");
    end procedure;


    procedure can_agent_driver_set_wait_timeout(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    timeout     : in    time
    ) is
    begin
        -- Debug also upon start since pushing single frame generates
        -- way too many logs
        can_agent_info_m(id, "Setting wait timeout for driver");
        com_channel_data.set_param(timeout);
        send(channel, id, CAN_AGNT_CMD_DRIVER_SET_WAIT_TIMEOUT);
        can_agent_debug_m(id, "Wait timeout for driver set");
    end procedure;


    procedure can_agent_driver_wait_finish(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    ) is
    begin
        can_agent_info_m(id, "Waiting for driver to finish");
        send(channel, id, CAN_AGNT_CMD_DRIVER_WAIT_FINISH);
        can_agent_debug_m(id, "Driver finished");
    end procedure;


    procedure can_agent_driver_push_value(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    value       : in    std_logic;
        constant    time        : in    time
    ) is
        variable item           : t_can_driver_entry;
    begin
        item.value := value;
        item.print_msg := false;
        item.drive_time := time;
        can_agent_driver_push_item(channel, id, item);
    end procedure;


    procedure can_agent_driver_push_value(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    value       : in    std_logic;
        constant    time        : in    time;
        constant    msg         : in    string
    ) is
        variable item           : t_can_driver_entry;
    begin
        item.value := value;
        item.print_msg := true;
        item.drive_time := time;
        item.msg := (OTHERS => ' ');
        item.msg(1 to msg'length) := msg;
        can_agent_driver_push_item(channel, id, item);
    end procedure;


    procedure can_agent_driver_drive_single_item(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    item        : in    t_can_driver_entry
    ) is
    begin
        can_agent_info_m(id, "Driving single item");

        com_channel_data.set_param(item.value);
        com_channel_data.set_param(item.drive_time);
        com_channel_data.set_param(item.print_msg);
        if (item.print_msg) then
            com_channel_data.set_param(item.msg);
        end if;
        send(channel, id, CAN_AGNT_CMD_DRIVER_DRIVE_SINGLE_ITEM);

        can_agent_debug_m(id, "Single item driven");
    end procedure;


    procedure can_agent_driver_drive_all_items(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    ) is
    begin
        can_agent_info_m(id, "Driving all items in driver FIFO");
        send(channel, id, CAN_AGNT_CMD_DRIVER_DRIVE_ALL_ITEMS);
        can_agent_info_m(id, "All items driven from driver FIFO driven");
    end procedure;

    procedure can_agent_driver_set_wait_for_monitor(
        signal      channel         : inout t_com_channel;
        constant    id              : in    natural;
        constant    wait_for_mon    : in    boolean
    ) is
    begin
        can_agent_info_m(id, "Setting driver wait for monitor to: " &
             boolean'image(wait_for_mon));

        com_channel_data.set_param(wait_for_mon);
        send(channel, id, CAN_AGNT_CMD_SET_WAIT_FOR_MONITOR);

        can_agent_debug_m(id, "Driver wait for monitor set");
    end procedure;


    procedure can_agent_driver_drive_value(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    value       : in    std_logic;
        constant    time        : in    time
    ) is
        variable item                   : t_can_driver_entry;
    begin
        item.value := value;
        item.drive_time := time;
        item.print_msg := false;
        can_agent_driver_drive_single_item(channel, id, item);
    end procedure;


    procedure can_agent_driver_drive_value(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    value       : in    std_logic;
        constant    time        : in    time;
        constant    msg         : in    string
    ) is
        variable item                   : t_can_driver_entry;
    begin
        item.value := value;
        item.drive_time := time;
        item.print_msg := true;
        item.msg := (OTHERS => ' ');
        item.msg(1 to msg'length) := msg;
        can_agent_driver_drive_single_item(channel, id, item);
    end procedure;


    procedure can_agent_monitor_start(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    ) is
    begin
        can_agent_info_m(id, "Starting monitor");
        send(channel, id, CAN_AGNT_CMD_MONITOR_START);
        can_agent_info_m(id, " Monitor started");
    end procedure;


    procedure can_agent_monitor_stop(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    ) is
    begin
        can_agent_info_m(id, "Stopping monitor");
        send(channel, id, CAN_AGNT_CMD_MONITOR_STOP);
        can_agent_debug_m(id, " Monitor stopped");
    end procedure;


    procedure can_agent_monitor_flush(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    ) is
    begin
        can_agent_info_m(id, "Flushing monitor FIFO");
        send(channel, id, CAN_AGNT_CMD_MONITOR_FLUSH);
        can_agent_debug_m(id, " Monitor FIFO flushed");
    end procedure;


    procedure can_agent_monitor_get_state(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    state       : out   t_can_monitor_state
    ) is
        variable rec_int : integer;
    begin
        can_agent_info_m(id, "Getting monitor state");
        send(channel, id, CAN_AGNT_CMD_MONITOR_GET_STATE);
        wait for 0 ns;
        rec_int := com_channel_data.get_param;
        state := t_can_monitor_state'val(rec_int);
        can_agent_debug_m(id, " Monitor state got");
    end procedure;


    procedure can_agent_monitor_get_monitored_val(
        signal      channel         : inout t_com_channel;
        constant    id              : in    natural;
        variable    monitored_val   : out   std_logic
    ) is
    begin
        can_agent_info_m(id, "Getting monitored value");
        send(channel, id, CAN_AGNT_CMD_MONITOR_GET_MONITORED_VAL);
        wait for 0 ns;
        monitored_val := com_channel_data.get_param;
        can_agent_debug_m(id, " Monitor value got");
    end procedure;


    procedure can_agent_monitor_push_item(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    item        : in    t_can_monitor_entry
    ) is
    begin
        can_agent_debug_m(id, "Pushing item to monitor FIFO (" &
                                std_logic'image(item.value) & ", " &
                                time'image(item.monitor_time) & ")");

        com_channel_data.set_param(item.value);
        com_channel_data.set_param(item.monitor_time);
        com_channel_data.set_param(item.print_msg);
        if (item.print_msg) then
            com_channel_data.set_param(item.msg);
        end if;

        com_channel_data.set_param_2(item.sample_rate);

        send(channel, id, CAN_AGNT_CMD_MONITOR_PUSH_ITEM);
        can_agent_debug_m(id, " Monitor item pushed");
    end procedure;


    procedure can_agent_monitor_set_wait_timeout(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    timeout     : in    time
    ) is
    begin
        can_agent_info_m(id, "Setting wait timeout");
        com_channel_data.set_param(timeout);
        send(channel, id, CAN_AGNT_CMD_MONITOR_SET_WAIT_TIMEOUT);
        can_agent_debug_m(id, " wait timeout set");
    end procedure;


    procedure can_agent_monitor_wait_finish(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    )is
    begin
        can_agent_info_m(id, "Waiting for monitor finish");
        send(channel, id, CAN_AGNT_CMD_MONITOR_WAIT_FINISH);
        can_agent_debug_m(id, " monitor finished");
    end procedure;


    procedure can_agent_monitor_single_item(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    item        : in    t_can_monitor_entry
    ) is
    begin
        can_agent_debug_m(id, "Monitoring single item");

        com_channel_data.set_param(item.value);
        com_channel_data.set_param(item.monitor_time);
        com_channel_data.set_param(item.print_msg);
        if (item.print_msg) then
            com_channel_data.set_param(item.msg);
        end if;
        com_channel_data.set_param_2(item.sample_rate);

        send(channel, id, CAN_AGNT_CMD_MONITOR_MONITOR_SINGLE_ITEM);

        can_agent_debug_m(id, " Single item monitored");
    end procedure;


    procedure can_agent_monitor_all_items(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    )is
    begin
        can_agent_info_m(id, "Waiting till all items will be monitored");
        send(channel, id, CAN_AGNT_CMD_MONITOR_MONITOR_ALL_ITEMS);
        can_agent_info_m(id, " all items monitored");
    end procedure;


    procedure can_agent_monitor_set_trigger(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    trigger     : in    t_can_monitor_trigger
    ) is
    begin
        can_agent_info_m(id, "Setting monitor trigger to: " &
             t_can_monitor_trigger'image(trigger));
        com_channel_data.set_param(t_can_monitor_trigger'pos(trigger));
        send(channel, id, CAN_AGNT_CMD_MONITOR_SET_TRIGGER);
        can_agent_debug_m(id, " Monitor trigger set");
    end procedure;


    procedure can_agent_monitor_get_trigger(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    trigger     : out   t_can_monitor_trigger
    ) is
        variable rec_int : integer;
    begin
        can_agent_info_m(id, "Getting monitor trigger");
        send(channel, id, CAN_AGNT_CMD_MONITOR_GET_TRIGGER);
        wait for 0 ns;
        rec_int := com_channel_data.get_param;
        trigger := t_can_monitor_trigger'val(rec_int);
        can_agent_debug_m(id, " Monitor trigger got");
    end procedure;


    procedure can_agent_monitor_set_sample_rate(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    sample_rate : in    time
    ) is
    begin
        can_agent_info_m(id, "Setting monitor sample rate to: " &
             time'image(sample_rate));
        com_channel_data.set_param(sample_rate);
        send(channel, id, CAN_AGNT_CMD_MONITOR_SET_SAMPLE_RATE);
        can_agent_debug_m(id, " monitor sample rate set");
    end procedure;


    procedure can_agent_monitor_get_sample_rate(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        variable    sample_rate : out   time
    ) is
    begin
        can_agent_info_m(id, "Getting monitor sample rate.");
        send(channel, id, CAN_AGNT_CMD_MONITOR_GET_SAMPLE_RATE);
        wait for 0 ns;
        sample_rate := com_channel_data.get_param;
        can_agent_debug_m(id, " monitor sample rate got");
    end procedure;


    procedure can_agent_monitor_push_value(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    value       : in    std_logic;
        constant    mon_time    : in    time
    ) is
        variable item                   : t_can_monitor_entry;
    begin
        item.value := value;
        item.monitor_time := mon_time;
        item.print_msg := false;
        can_agent_monitor_push_item(channel, id, item);
    end procedure;


    procedure can_agent_monitor_push_value(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    value       : in    std_logic;
        constant    mon_time    : in    time;
        constant    msg         : in    string
    ) is
        variable item                   : t_can_monitor_entry;
    begin
        item.value := value;
        item.monitor_time := mon_time;
        item.print_msg := true;
        item.msg := (OTHERS => ' ');
        item.msg(1 to msg'length) := msg;
        can_agent_monitor_push_item(channel, id, item);
    end procedure;


    procedure can_agent_monitor_monitor_value(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    value       : in    std_logic;
        constant    mon_time    : in    time
    ) is
        variable item                   : t_can_monitor_entry;
    begin
        item.value := value;
        item.monitor_time := mon_time;
        item.print_msg := false;
        can_agent_monitor_single_item(channel, id, item);
    end procedure;


    procedure can_agent_monitor_monitor_value(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    value       : in    std_logic;
        constant    mon_time    : in    time;
        constant    msg         : in    string
    )is
        variable item                   : t_can_monitor_entry;
    begin
        item.value := value;
        item.monitor_time := mon_time;
        item.print_msg := true;
        item.msg := (OTHERS => ' ');
        item.msg(1 to msg'length) := msg;
        can_agent_monitor_single_item(channel, id, item);
    end procedure;


    procedure can_agent_monitor_check_result(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural
    ) is
    begin
        can_agent_info_m(id, "Checking monitor result!");
        send(channel, id, CAN_AGNT_CMD_MONITOR_CHECK_RESULT);
        can_agent_debug_m(id, " Monitor result checked");
    end procedure;


    procedure can_agent_monitor_set_input_delay(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    input_delay : in    time
    ) is
    begin
        can_agent_info_m(id, "Settting input delay");
        com_channel_data.set_param(input_delay);
        send(channel, id, CAN_AGNT_CMD_MONITOR_SET_INPUT_DELAY);
        can_agent_debug_m(id, " Monitor input delay set");
    end procedure;


    procedure can_agent_configure_tx_to_rx_feedback(
        signal      channel     : inout t_com_channel;
        constant    id          : in    natural;
        constant    enable      : in    boolean
    ) is
    begin
        can_agent_info_m(id, "Configuring can_tx to can_rx feedback!");
        if (enable) then
            send(channel, id, CAN_AGNT_CMD_TX_RX_FEEDBACK_ENABLE);
        else
            send(channel, id, CAN_AGNT_CMD_TX_RX_FEEDBACK_DISABLE);
        end if;
        can_agent_debug_m(id, " Monitor can_tx to can_rx feedback configured!");
    end procedure;

end package body;
