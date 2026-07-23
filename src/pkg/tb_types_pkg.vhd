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
--    Package with common types
--
--------------------------------------------------------------------------------
-- Revision History:
--    20.7.2026   Created file
--------------------------------------------------------------------------------

Library ctu_can_agents;
context ctu_can_agents.ieee_context;

package tb_types_pkg is

    -----------------------------------------------------------------------
    -- Result of test
    -----------------------------------------------------------------------
    type t_ctu_test_result is protected
        procedure set_result(result : boolean);
        impure function get_result return boolean;
        impure function get_result return std_logic;
    end protected;

    -----------------------------------------------------------------------
    -- Communication channel data
    --
    -- Shared data structure used as buffer for passing data over
    -- communication channel. It is filled by sender always before issuing
    -- event on communication channel. Since VHDL should hold mutex over
    -- shared variable, it should be safe way to pass data between
    -- processes!
    -----------------------------------------------------------------------
    type t_com_channel_data is protected

        procedure set_dest_and_msg_code(
            dest        : in natural;
            msg_code    : in integer
        );

        impure function get_dest return integer;
        impure function get_msg_code return integer;

        procedure set_reply_code(reply_code  : in natural);
        impure function get_reply_code return natural;

        procedure set_param(param : in  std_logic_vector);
        procedure set_param_2(param : in  std_logic_vector);
        procedure set_param_3(param : in  std_logic_vector);

        procedure set_param(param  : in  std_logic);
        procedure set_param_2(param : in  std_logic);
        procedure set_param_3(param : in  std_logic);

        procedure set_param(param : in  time);
        procedure set_param_2(param : in  time);
        procedure set_param_3(param : in  time);

        procedure set_param(param : in  integer);
        procedure set_param_2(param : in  integer);
        procedure set_param_3(param : in  integer);

        procedure set_param(param : in  boolean);
        procedure set_param_2(param : in  boolean);
        procedure set_param_3(param : in  boolean);

        procedure set_param(param : in  string);
        procedure set_param_2(param : in  string);
        procedure set_param_3(param : in  string);

        impure function get_param   return std_logic;
        impure function get_param_2 return std_logic;
        impure function get_param_3 return std_logic;

        impure function get_param   return std_logic_vector;
        impure function get_param_2 return std_logic_vector;
        impure function get_param_3 return std_logic_vector;

        impure function get_param   return time;
        impure function get_param_2 return time;
        impure function get_param_3 return time;

        impure function get_param   return integer;
        impure function get_param_2 return integer;
        impure function get_param_3 return integer;

        impure function get_param   return boolean;
        impure function get_param_2 return boolean;
        impure function get_param_3 return boolean;

        impure function get_param   return string;
        impure function get_param_2 return string;
        impure function get_param_3 return string;

    end protected;

    -----------------------------------------------------------------------
    -- Protected variant of boolean
    -----------------------------------------------------------------------
    type t_prot_boolean is protected
        procedure set(new_val : boolean);
        impure function get return boolean;
    end protected;

    -----------------------------------------------------------------------
    -- Memory bus transfer
    -----------------------------------------------------------------------
    type t_mem_bus_transfer is record
        write                       :   boolean;
        address                     :   integer;
        byte_enable                 :   std_logic_vector(3 downto 0);
        write_data                  :   std_logic_vector(31 downto 0);
        read_data                   :   std_logic_vector(31 downto 0);
        wait_request_cycles         :   natural;
        read_data_valid_cycles      :   natural;
    end record;

    -----------------------------------------------------------------------
    -- Testbench configuration database
    -----------------------------------------------------------------------
    constant C_CONFIG_DB_MAX_ENTRIES : natural := 128;
    constant C_CONFIG_DB_STR_LEN     : natural := 64;

    subtype t_config_db_str is string(1 to C_CONFIG_DB_STR_LEN);

    type t_config_db_item is record
        name     : t_config_db_str;
        val_type : t_config_db_str;
        val      : t_config_db_str;
    end record;

    type t_config_db_array is array (0 to C_CONFIG_DB_MAX_ENTRIES - 1) of t_config_db_item;

    type t_config_db is protected

        procedure put(
            constant name     : in string;
            constant val_type : in string;
            constant val      : in string
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

    end protected;

end package;


package body tb_types_pkg is

    -----------------------------------------------------------------------
    -- Test result
    -----------------------------------------------------------------------
    type t_ctu_test_result is protected body

        variable result_i : boolean;

        procedure set_result(result : boolean) is
        begin
            result_i := result;
        end procedure;

        impure function get_result return boolean is
        begin
            return result_i;
        end function;

        impure function get_result return std_logic is
        begin
            if result_i then
                return '1';
            else
                return '0';
            end if;
        end function;

    end protected body;

    -----------------------------------------------------------------------
    -- Communication channel data
    -----------------------------------------------------------------------
    type t_com_channel_data is protected body

        variable dest_i             : natural;
        variable msg_code_i         : integer;

        variable reply_code_i       : integer;

        variable par_logic_vect     : std_logic_vector(255 downto 0);
        variable par_logic_vect_2   : std_logic_vector(255 downto 0);
        variable par_logic_vect_3   : std_logic_vector(255 downto 0);

        variable par_logic          : std_logic;
        variable par_logic_2        : std_logic;
        variable par_logic_3        : std_logic;

        variable par_time           : time;
        variable par_time_2         : time;
        variable par_time_3         : time;

        variable par_int            : integer;
        variable par_int_2          : integer;
        variable par_int_3          : integer;

        variable par_bool           : boolean;
        variable par_bool_2         : boolean;
        variable par_bool_3         : boolean;

        variable par_string         : string(1 to 100);
        variable par_string_2       : string(1 to 100);
        variable par_string_3       : string(1 to 100);

        procedure set_dest_and_msg_code(
            dest        : in natural;
            msg_code    : in integer
        ) is
        begin
            dest_i := dest;
            msg_code_i := msg_code;
        end procedure;


        procedure set_reply_code(
            reply_code  : in natural
        ) is
        begin
            reply_code_i := reply_code;
        end procedure;


        impure function get_reply_code return natural is
        begin
            return reply_code_i;
        end function;


        impure function get_dest return integer is
        begin
            return dest_i;
        end function;


        impure function get_msg_code return integer is
        begin
            return msg_code_i;
        end function;

        procedure set_param(
            param       : in  std_logic
        ) is
        begin
            par_logic := param;
        end procedure;

        procedure set_param_2(
            param       : in  std_logic
        ) is
        begin
            par_logic_2 := param;
        end procedure;

        procedure set_param_3(
            param       : in  std_logic
        ) is
        begin
            par_logic_3 := param;
        end procedure;

        procedure set_param(
            param       : in  std_logic_vector
        ) is
        begin
            assert (param'length <= par_logic_vect'length);
            par_logic_vect := (others => '0');
            par_logic_vect(param'length - 1 downto 0) := param;
        end procedure;

        procedure set_param_2(
            param       : in  std_logic_vector
        ) is
        begin
            assert (param'length <= par_logic_vect_2'length);
            par_logic_vect_2 := (others => '0');
            par_logic_vect_2(param'length - 1 downto 0) := param;
        end procedure;

        procedure set_param_3(
            param       : in  std_logic_vector
        ) is
        begin
            assert (param'length <= par_logic_vect_3'length);
            par_logic_vect_3 := (others => '0');
            par_logic_vect_3(param'length - 1 downto 0) := param;
        end procedure;

        procedure set_param(
            param       : in  time
        ) is
        begin
            par_time := param;
        end procedure;

        procedure set_param_2(
            param       : in  time
        ) is
        begin
            par_time_2 := param;
        end procedure;

        procedure set_param_3(
            param       : in  time
        ) is
        begin
            par_time_3 := param;
        end procedure;

        procedure set_param(
            param       : in  integer
        ) is
        begin
            par_int := param;
        end procedure;

        procedure set_param_2(
            param       : in  integer
        ) is
        begin
            par_int_2 := param;
        end procedure;

        procedure set_param_3(
            param       : in  integer
        ) is
        begin
            par_int_3 := param;
        end procedure;

        procedure set_param(
            param       : in  boolean
        ) is
        begin
            par_bool := param;
        end procedure;

        procedure set_param_2(
            param       : in  boolean
        ) is
        begin
            par_bool_2 := param;
        end procedure;

        procedure set_param_3(
            param       : in  boolean
        ) is
        begin
            par_bool_3 := param;
        end procedure;

        procedure set_param(
            param : in  string
        ) is
        begin
            assert (param'length <= par_string'length);
            par_string := param;
        end procedure;

        procedure set_param_2(
            param : in  string
        ) is
        begin
            assert (param'length <= par_string_2'length);
            par_string_2 := param;
        end procedure;

        procedure set_param_3(
            param : in  string
        ) is
        begin
            assert (param'length <= par_string_3'length);
            par_string_3 := param;
        end procedure;


        impure function get_param return std_logic
        is
        begin
            return par_logic;
        end function;

        impure function get_param_2 return std_logic
        is
        begin
            return par_logic_2;
        end function;

        impure function get_param_3 return std_logic
        is
        begin
            return par_logic_3;
        end function;

        impure function get_param return std_logic_vector
        is
        begin
            return par_logic_vect;
        end function;

        impure function get_param_2 return std_logic_vector
        is
        begin
            return par_logic_vect_2;
        end function;

        impure function get_param_3 return std_logic_vector
        is
        begin
            return par_logic_vect_3;
        end function;

        impure function get_param return time
        is
        begin
            return par_time;
        end function;

        impure function get_param_2 return time
        is
        begin
            return par_time_2;
        end function;

        impure function get_param_3 return time
        is
        begin
            return par_time_3;
        end function;

        impure function get_param return integer
        is
        begin
            return par_int;
        end function;

        impure function get_param_2 return integer
        is
        begin
            return par_int_2;
        end function;

        impure function get_param_3 return integer
        is
        begin
            return par_int_3;
        end function;

        impure function get_param return string
        is
        begin
            return par_string;
        end function;

        impure function get_param_2 return string
        is
        begin
            return par_string_2;
        end function;

        impure function get_param_3 return string
        is
        begin
            return par_string_3;
        end function;

        impure function get_param return boolean
        is
        begin
            return par_bool;
        end function;

        impure function get_param_2 return boolean
        is
        begin
            return par_bool_2;
        end function;

        impure function get_param_3 return boolean
        is
        begin
            return par_bool_3;
        end function;

    end protected body;

    -----------------------------------------------------------------------
    -- Protected variant of boolean
    -----------------------------------------------------------------------
    type t_prot_boolean is protected body

        variable val : boolean;

        procedure set(new_val : boolean) is
        begin
            val := new_val;
        end procedure;

        impure function get return boolean is
        begin
            return val;
        end function;

    end protected body;

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
                report "Configuration Database: string '" & s & "' exceeds max length!"
                severity failure;
            ret(1 to s'length) := s;
            return ret;
        end function;

        procedure put(
            constant name     : in string;
            constant val_type : in string;
            constant val      : in string
        ) is
        begin
            assert num_entries < C_CONFIG_DB_MAX_ENTRIES
                report "Configuration Database: capacity exceeded, cannot put '" & name & "'!"
                severity failure;

            entries(num_entries).name     := to_config_db_str(name);
            entries(num_entries).val_type := to_config_db_str(val_type);
            entries(num_entries).val      := to_config_db_str(val);

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

            report "Configuration Database: entry '" & name & "' not found!"
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

    end protected body;

end package body;