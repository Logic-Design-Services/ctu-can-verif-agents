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

use ctu_can_agents.tb_report_pkg.all;
use ctu_can_agents.tb_random_pkg.all;

package body tb_config_db_pkg is

    -----------------------------------------------------------------------
    -- Configuration database
    -----------------------------------------------------------------------

    type t_config_db is protected body

        variable entries     : t_config_db_array;
        variable num_entries : natural := 0;

        function to_config_db_str(
            constant s : string
        ) return t_config_db_str is
            variable ret : t_config_db_str := (others => ' ');
        begin
            assert s'length <= C_CONFIG_DB_STR_LEN
                report C_CONFIG_DB_TAG & "string '" & s & "' exceeds max length!"
                severity failure;
            ret(1 to s'length) := s;
            return ret;
        end function;

        procedure put(
            constant name       : in string;
            constant val_type   : in string;
            constant val        : in string;
            constant randomize  : in boolean := false;
            constant range_low  : in string := "0";
            constant range_high : in string := "1"
        ) is
        begin
            assert num_entries < C_CONFIG_DB_MAX_ENTRIES
                report C_CONFIG_DB_TAG & "capacity exceeded, cannot put '" & name & "'!"
                severity failure;

            assert val_type = "string" or
                   val_type = "integer" or
                   val_type = "boolean" or
                   val_type = "time"
            report
                   C_CONFIG_DB_TAG & "invalid type: " & val_type &
                   ". Shall be one of string, integer, boolean, time";

            if (randomize) then
                assert (val_type = "integer" or val_type = "boolean" or val_type = "time")
                report C_CONFIG_DB_TAG & "invalid type for randomization. Shall be one of: integer, boolean or time.";
            end if;

            entries(num_entries).name       := to_config_db_str(name);
            entries(num_entries).val_type   := to_config_db_str(val_type);
            entries(num_entries).val        := to_config_db_str(val);
            entries(num_entries).randomize  := randomize;
            entries(num_entries).range_low  := range_low;
            entries(num_entries).range_high := range_high;

            num_entries := num_entries + 1;
        end procedure;

        impure function get(
            constant name : in string
        ) return t_config_db_item is
            variable cmp_name : t_config_db_str := to_config_db_str(name);
        begin
            for i in 0 to num_entries - 1 loop
                if (entries(i).name = cmp_name) then
                    return entries(i);
                end if;
            end loop;

            report C_CONFIG_DB_TAG & "entry '" & name & "' not found!"
                severity failure;

            return entries(0);
        end function;

        impure function get(
            constant name : in string
        ) return integer is
            variable item : t_config_db_item := get(name);
        begin
            assert item.val_type(1 to 7) = "integer";
            return integer'value(item.val);
        end function;

        impure function get(
            constant name : in string
        ) return boolean is
            variable item : t_config_db_item := get(name);
        begin
            assert item.val_type(1 to 7) = "boolean";
            return boolean'value(item.val);
        end function;

        impure function get(
            constant name : in string
        ) return string is
            variable item : t_config_db_item := get(name);
        begin
            assert item.val_type(1 to 6) = "string";
            return item.val;
        end function;

        impure function get(
            constant name : in string
        ) return time is
            variable item : t_config_db_item := get(name);
        begin
            assert item.val_type(1 to 4) = "time";
            return time'value(item.val);
        end function;

        procedure randomize is
            variable min_int, max_int : integer;
            variable min_time, max_time : time;
        begin
            for i in 0 to num_entries - 1 loop
                if (entries(i).randomize) then
                    if (entries(i).val_type(1 to 7) = "boolean") then
                        if (rand_real > 0.5) then
                            entries(i).val := to_config_db_str("TRUE");
                        else
                            entries(i).val := to_config_db_str("FALSE");
                        end if;

                    elsif (entries(i).val_type(1 to 7) = "integer") then
                        min_int := integer'value(entries(i).range_low);
                        max_int := integer'value(entries(i).range_high);
                        entries(i).val := to_config_db_str(
                                        integer'image(min_int + rand_int(max_int - min_int)));

                    elsif (entries(i).val_type(1 to 4) = "time") then
                        min_time := time'value(entries(i).range_low);
                        max_time := time'value(entries(i).range_high);
                        entries(i).val := time'image(rand_real * (max_time - min_time));
                    end if;
                end if;

            end loop;
        end procedure;

        procedure print is
        begin
            info_m("*********************************************************************");
            info_m(C_CONFIG_DB_TAG & " Content");
            info_m("*********************************************************************");
            for i in 0 to num_entries - 1 loop
                info_m("    " & entries(i).name & ":" & entries(i).val);
            end loop;
            info_m("*********************************************************************");
        end procedure;

    end protected body;

end package body;