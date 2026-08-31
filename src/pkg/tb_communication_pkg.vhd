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
--    Package with CTU CAN FD TB communication routines between agents.
--
--------------------------------------------------------------------------------
-- Revision History:
--    28.2.2021   Created file
--    20.7.2026   Changed hard-coded addressing constants to "DEF" (default)
--                constants only
--------------------------------------------------------------------------------

library ctu_can_agents;
context ctu_can_agents.ieee_context;

use ctu_can_agents.tb_types_pkg.all;

package tb_communication_pkg is

    -- Default Agent ID
    constant C_RESET_AGENT_DEF_ID               : natural := 0;
    constant C_CLOCK_AGENT_DEF_ID               : natural := 1;
    constant C_MEM_BUS_AGENT_DEF_ID             : natural := 2;
    constant C_CAN_AGENT_DEF_ID                 : natural := 3;
    constant C_FEATURE_TEST_AGENT_DEF_ID        : natural := 4;
    constant C_INTERRUPT_AGENT_DEF_ID           : natural := 5;
    constant C_TIMESTAMP_AGENT_DEF_ID           : natural := 6;
    constant C_TEST_PROBE_AGENT_DEF_ID          : natural := 7;

    constant COM_PKG_TAG                        : string := "Communication PKG: ";

    -----------------------------------------------------------------------
    -- Communication channel primitive.
    --
    -- A single shared broadcast wake-up signal, that means "mailbox state
    -- changed, go re-check it".
    --
    -- Any number of masters/agents may pulse it concurrently (wired-OR,
    -- safe thanks to std_logic resolution with 'Z' idle); every waiter
    -- re-evaluates its own condition against com_mailbox on every edge,
    -- so a "merged" edge from overlapping concurrent pulses only costs
    -- latency, never correctness.
    -----------------------------------------------------------------------
    subtype t_com_channel is std_logic;

    constant C_COM_CHANNEL_ACTIVE               : t_com_channel := '1';
    constant C_COM_CHANNEL_INACTIVE             : t_com_channel := 'Z';

    signal default_channel                      : t_com_channel := C_COM_CHANNEL_INACTIVE;

    shared variable com_mailbox                 : t_com_mailbox;

    -- Reply codes
    constant C_REPLY_CODE_OK                    : natural := 0;
    constant C_REPLY_CODE_ERR                   : natural := 1;

    -----------------------------------------------------------------------
    -- Sends request "msg_code" to agent "dest", carrying "data" as
    -- request payload. Blocks until the target agent replies; on return,
    -- "data" holds the reply payload (overwritten in place).
    --
    -- Safe to call from any number of concurrent master processes,
    -- targeting the same or different destinations. Requests to the
    -- same destination are served strictly in arrival order.
    --
    -- @param channel   Pass default_channel
    -- @param dest      Target agent
    -- @param msg_code  Message code to send
    -- @param data      Request payload in, reply payload out
    -----------------------------------------------------------------------
    procedure send(
        signal   channel    : inout t_com_channel;
        constant dest       : in    integer;
        constant msg_code   : in    integer;
        variable data       : inout t_com_data
    );


    -----------------------------------------------------------------------
    -- Start receiving (used by agent). Blocks until a request for "dest"
    -- is available, then pops the oldest one.
    --
    -- @param channel   Pass default_channel
    -- @param dest      Agent's destination (unique per agent)
    -- @param token     Returned handle - must be passed to receive_finish
    -- @param msg_code  Returned message code of the popped request
    -- @param data      Returned request payload
    -----------------------------------------------------------------------
    procedure receive_start(
        signal   channel     : inout  t_com_channel;
        constant dest        : in     integer;
        variable token       : out    natural;
        variable msg_code    : out    integer;
        variable data        : out    t_com_data
    );


    -----------------------------------------------------------------------
    -- Finishes receiving (used by agent). Posts reply code/payload for
    -- "token" and wakes waiting masters (they check their own token).
    --
    -- @param channel       Pass default_channel
    -- @param token         Handle obtained from receive_start
    -- @param reply_code    Reply code to set
    -- @param data          Reply payload
    -----------------------------------------------------------------------
    procedure receive_finish(
        signal   channel     : inout  t_com_channel;
        constant token       : in     natural;
        constant reply_code  : in     natural;
        variable data        : in     t_com_data
    );

end package;