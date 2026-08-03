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
--    Package body with CTU CAN FD TB communication routines between agents.
--
--------------------------------------------------------------------------------
-- Revision History:
--    28.2.2021   Created file
--    20.7.2026   Changed hard-coded addressing constants to "DEF" (default)
--                constants only
--------------------------------------------------------------------------------

library ctu_can_agents;
context ctu_can_agents.ieee_context;

use ctu_can_agents.tb_report_pkg.all;
use ctu_can_agents.tb_types_pkg.all;

package body tb_communication_pkg is

    procedure notify(
        signal channel      : inout t_com_channel
    ) is
    begin
        if channel /= C_COM_CHANNEL_ACTIVE then
            channel <= C_COM_CHANNEL_ACTIVE;
            wait until channel = C_COM_CHANNEL_ACTIVE;
            channel <= C_COM_CHANNEL_INACTIVE;
            wait until channel = C_COM_CHANNEL_INACTIVE;
        else
            error_m(COM_PKG_TAG & "Attempting to notify over active channel!");
        end if;
    end procedure;


    procedure send(
        signal   channel    : inout t_com_channel;
        constant dest       : in    integer;
        constant msg_code   : in    integer
    ) is
    begin
        com_channel_data.set_dest_and_msg_code(dest, msg_code);
        wait for 0 ns;

        -- Send over the channel
        notify(channel);

        -- Wait for response back. Agents should satisfy that only one agent
        -- will process sent message (thanks to dest), and therefore we
        -- are guaranteed to get ACK only from one agent back.
        wait until channel = C_COM_CHANNEL_ACTIVE;

        -- Check reply code
        if com_channel_data.get_reply_code /= C_REPLY_CODE_OK then
            error_m(COM_PKG_TAG & "Reply code error from " & integer'image(dest));
        end if;

        wait until channel = C_COM_CHANNEL_INACTIVE;

    end procedure;


    procedure receive_start(
        signal   channel     : inout  t_com_channel;
        constant dest        : in     integer
    ) is
    begin
        -- Poll till there is request on the channel
        while true loop
            wait until channel = C_COM_CHANNEL_ACTIVE;
            if (com_channel_data.get_dest = dest) then
                exit;
            end if;
        end loop;
    end procedure;


    procedure receive_finish(
        signal   channel     : inout  t_com_channel;
        constant reply_code  : in     natural
    ) is
    begin
        com_channel_data.set_reply_code(reply_code);
        wait for 0 ns;
        notify(channel);
    end procedure;

end package body;
