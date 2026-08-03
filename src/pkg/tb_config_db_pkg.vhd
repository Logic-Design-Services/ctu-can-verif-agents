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
--    Configuration database package.
--
--------------------------------------------------------------------------------
-- Revision History:
--    20.7.2026   Created file
--------------------------------------------------------------------------------

library ctu_can_agents;
context ctu_can_agents.ieee_context;

package tb_config_db_pkg is

    constant C_CONFIG_DB_MAX_ENTRIES : natural := 128;
    constant C_CONFIG_DB_STR_LEN     : natural := 64;

    subtype t_config_db_str is string(1 to C_CONFIG_DB_STR_LEN);

    type t_config_db_item is record
        name        : t_config_db_str;
        val_type    : t_config_db_str;
        val         : t_config_db_str;
        randomize   : boolean;
        range_low   : t_config_db_str;
        range_high  : t_config_db_str;
    end record;

    type t_config_db_array is array (0 to C_CONFIG_DB_MAX_ENTRIES - 1) of t_config_db_item;

    type t_config_db is protected

        procedure put(
            constant name       : in string;
            constant val_type   : in string;
            constant val        : in string;
            constant randomize  : in boolean := false;
            constant range_low  : in string := "0";
            constant range_high : in string := "1"
        );

        impure function get(
            constant name : in string
        ) return t_config_db_item;

        impure function get(
            constant name : in string
        ) return integer;

        impure function get(
            constant name : in string
        ) return boolean;

        impure function get(
            constant name : in string
        ) return time;

        impure function get(
            constant name : in string
        ) return string;

        procedure randomize;
        procedure print;

    end protected;

    constant C_CONFIG_DB_TAG : string := "Configuration Database: ";

end package;