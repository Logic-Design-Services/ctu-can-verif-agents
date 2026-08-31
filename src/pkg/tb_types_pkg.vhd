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

library ctu_can_agents;
context ctu_can_agents.ieee_context;

package tb_types_pkg is

    -----------------------------------------------------------------------
    -- Max number of requests that can be simultaneously in flight
    -- (queued + being serviced) across the whole TB. Bump this if
    -- simulation reports "Mailbox full".
    -----------------------------------------------------------------------
    constant C_COM_MAILBOX_DEPTH : natural := 32;

    -----------------------------------------------------------------------
    -- Communication channel request / reply payload.
    --
    -- Each caller owns its own instance and passes it into
    -- send/receive_start/receive_finish.
    -----------------------------------------------------------------------
    type t_com_data is record
        par_logic_vect     : std_logic_vector(255 downto 0);
        par_logic_vect_2   : std_logic_vector(255 downto 0);
        par_logic_vect_3   : std_logic_vector(255 downto 0);
        par_logic          : std_logic;
        par_logic_2        : std_logic;
        par_logic_3        : std_logic;
        par_time           : time;
        par_time_2         : time;
        par_time_3         : time;
        par_int            : integer;
        par_int_2          : integer;
        par_int_3          : integer;
        par_bool           : boolean;
        par_bool_2         : boolean;
        par_bool_3         : boolean;
        par_string         : string(1 to 100);
        par_string_2       : string(1 to 100);
        par_string_3       : string(1 to 100);
    end record;

    constant C_COM_DATA_INIT : t_com_data := (
        par_logic_vect   => (others => '0'),
        par_logic_vect_2 => (others => '0'),
        par_logic_vect_3 => (others => '0'),
        par_logic        => 'U',
        par_logic_2      => 'U',
        par_logic_3      => 'U',
        par_time         => 0 ns,
        par_time_2       => 0 ns,
        par_time_3       => 0 ns,
        par_int          => 0,
        par_int_2        => 0,
        par_int_3        => 0,
        par_bool         => false,
        par_bool_2       => false,
        par_bool_3       => false,
        par_string       => (others => ' '),
        par_string_2     => (others => ' '),
        par_string_3     => (others => ' ')
    );

    procedure set_param(variable data : inout t_com_data; param : in std_logic_vector);
    procedure set_param_2(variable data : inout t_com_data; param : in std_logic_vector);
    procedure set_param_3(variable data : inout t_com_data; param : in std_logic_vector);

    procedure set_param(variable data : inout t_com_data; param : in std_logic);
    procedure set_param_2(variable data : inout t_com_data; param : in std_logic);
    procedure set_param_3(variable data : inout t_com_data; param : in std_logic);

    procedure set_param(variable data : inout t_com_data; param : in time);
    procedure set_param_2(variable data : inout t_com_data; param : in time);
    procedure set_param_3(variable data : inout t_com_data; param : in time);

    procedure set_param(variable data : inout t_com_data; param : in integer);
    procedure set_param_2(variable data : inout t_com_data; param : in integer);
    procedure set_param_3(variable data : inout t_com_data; param : in integer);

    procedure set_param(variable data : inout t_com_data; param : in boolean);
    procedure set_param_2(variable data : inout t_com_data; param : in boolean);
    procedure set_param_3(variable data : inout t_com_data; param : in boolean);

    procedure set_param(variable data : inout t_com_data; param : in string);
    procedure set_param_2(variable data : inout t_com_data; param : in string);
    procedure set_param_3(variable data : inout t_com_data; param : in string);

    function get_param(data : t_com_data)   return std_logic;
    function get_param_2(data : t_com_data) return std_logic;
    function get_param_3(data : t_com_data) return std_logic;

    function get_param(data : t_com_data)   return std_logic_vector;
    function get_param_2(data : t_com_data) return std_logic_vector;
    function get_param_3(data : t_com_data) return std_logic_vector;

    function get_param(data : t_com_data)   return time;
    function get_param_2(data : t_com_data) return time;
    function get_param_3(data : t_com_data) return time;

    function get_param(data : t_com_data)   return integer;
    function get_param_2(data : t_com_data) return integer;
    function get_param_3(data : t_com_data) return integer;

    function get_param(data : t_com_data)   return boolean;
    function get_param_2(data : t_com_data) return boolean;
    function get_param_3(data : t_com_data) return boolean;

    function get_param(data : t_com_data)   return string;
    function get_param_2(data : t_com_data) return string;
    function get_param_3(data : t_com_data) return string;

    -----------------------------------------------------------------------
    -- Communication mailbox
    --
    -- Bounded FIFO of pending requests. Any number of master processes
    -- may push (routed by "dest"); each destination agent pops only the
    -- oldest entry addressed to it, so requests to a given agent are
    -- served strictly in arrival order while requests to different
    -- agents don't block each other.
    -----------------------------------------------------------------------
    type t_com_slot_state is (
        SLOT_FREE,
        SLOT_PENDING,
        SLOT_IN_PROGRESS,
        SLOT_REPLIED
    );

    type t_com_mailbox is protected

        impure function push(
            constant dest     : natural;
            constant msg_code : integer;
            constant data     : t_com_data
        ) return natural;

        procedure try_pop(
            constant dest : in  natural;
            found         : out boolean;
            token         : out natural;
            msg_code      : out integer;
            variable data : out t_com_data
        );

        procedure post_reply(
            constant token      : in natural;
            constant reply_code : in natural;
            constant data       : in t_com_data
        );

        impure function reply_ready(token : natural) return boolean;

        procedure take_reply(
            token       : in  natural;
            reply_code  : out natural;
            variable data : out t_com_data
        );

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

end package;


package body tb_types_pkg is

    -----------------------------------------------------------------------
    -- t_com_data get_param / set_param
    -----------------------------------------------------------------------
    procedure set_param(
        variable    data    : inout t_com_data;
                    param   : in std_logic
    ) is
    begin
        data.par_logic := param;
    end procedure;

    procedure set_param_2(
        variable    data    : inout t_com_data;
                    param   : in    std_logic
    ) is
    begin
        data.par_logic_2 := param;
    end procedure;

    procedure set_param_3(
        variable    data    : inout t_com_data;
                    param   : in std_logic
    ) is
    begin
        data.par_logic_3 := param;
    end procedure;

    procedure set_param(
        variable    data    : inout t_com_data;
                    param   : in std_logic_vector
    ) is
    begin
        assert (param'length <= data.par_logic_vect'length);
        data.par_logic_vect := (others => '0');
        data.par_logic_vect(param'length - 1 downto 0) := param;
    end procedure;

    procedure set_param_2(
        variable    data    : inout t_com_data;
                    param   : in    std_logic_vector
    ) is
    begin
        assert (param'length <= data.par_logic_vect_2'length);
        data.par_logic_vect_2 := (others => '0');
        data.par_logic_vect_2(param'length - 1 downto 0) := param;
    end procedure;

    procedure set_param_3(
        variable    data    : inout t_com_data;
                    param   : in    std_logic_vector
    ) is
    begin
        assert (param'length <= data.par_logic_vect_3'length);
        data.par_logic_vect_3 := (others => '0');
        data.par_logic_vect_3(param'length - 1 downto 0) := param;
    end procedure;

    procedure set_param(
        variable    data    : inout t_com_data;
                    param   : in    time
    ) is
    begin
        data.par_time := param;
    end procedure;

    procedure set_param_2(
        variable    data    : inout t_com_data;
                    param   : in    time
    ) is
    begin
        data.par_time_2 := param;
    end procedure;

    procedure set_param_3(
        variable    data    : inout t_com_data;
                    param   : in    time
    ) is
    begin
        data.par_time_3 := param;
    end procedure;

    procedure set_param(
        variable    data    : inout t_com_data;
                    param   : in    integer
    ) is
    begin
        data.par_int := param;
    end procedure;

    procedure set_param_2(
        variable    data    : inout t_com_data;
                    param   : in    integer
    ) is
    begin
        data.par_int_2 := param;
    end procedure;

    procedure set_param_3(
        variable    data    : inout t_com_data;
                    param   : in    integer
    ) is
    begin
        data.par_int_3 := param;
    end procedure;

    procedure set_param(
        variable    data    : inout t_com_data;
                    param   : in boolean
    ) is
    begin
        data.par_bool := param;
    end procedure;

    procedure set_param_2(
        variable    data    : inout t_com_data;
                    param   : in    boolean
    ) is
    begin
        data.par_bool_2 := param;
    end procedure;

    procedure set_param_3(
        variable    data    : inout t_com_data;
                    param   : in    boolean
    ) is
    begin
        data.par_bool_3 := param;
    end procedure;

    procedure set_param(
        variable    data    : inout t_com_data;
                    param   : in    string
    ) is
    begin
        assert (param'length <= data.par_string'length);
        data.par_string := param;
    end procedure;

    procedure set_param_2(
        variable    data    : inout t_com_data;
                    param   : in    string
    ) is
    begin
        assert (param'length <= data.par_string_2'length);
        data.par_string_2 := param;
    end procedure;

    procedure set_param_3(
        variable    data    : inout t_com_data;
                    param   : in    string
    ) is
    begin
        assert (param'length <= data.par_string_3'length);
        data.par_string_3 := param;
    end procedure;


    function get_param(
        data : t_com_data
    ) return std_logic is
    begin
        return data.par_logic;
    end function;

    function get_param_2(
        data : t_com_data
    ) return std_logic is
    begin
        return data.par_logic_2;
    end function;

    function get_param_3(
        data : t_com_data
    ) return std_logic is
    begin
        return data.par_logic_3;
    end function;

    function get_param(
        data : t_com_data
    ) return std_logic_vector is
    begin
        return data.par_logic_vect;
    end function;

    function get_param_2(
        data : t_com_data
    ) return std_logic_vector is
    begin
        return data.par_logic_vect_2;
    end function;

    function get_param_3(
        data : t_com_data
    ) return std_logic_vector is
    begin
        return data.par_logic_vect_3;
    end function;

    function get_param(
        data : t_com_data
    ) return time is
    begin
        return data.par_time;
    end function;

    function get_param_2(
        data : t_com_data
    ) return time is
    begin
        return data.par_time_2;
    end function;

    function get_param_3(
        data : t_com_data
    ) return time is
    begin
        return data.par_time_3;
    end function;

    function get_param(
        data : t_com_data
    ) return integer is
    begin
        return data.par_int;
    end function;

    function get_param_2(
        data : t_com_data
    ) return integer is
    begin
        return data.par_int_2;
    end function;

    function get_param_3(
        data : t_com_data
    ) return integer is
    begin
        return data.par_int_3;
    end function;

    function get_param(
        data : t_com_data
    ) return string is
    begin
        return data.par_string;
    end function;

    function get_param_2(
        data : t_com_data
    ) return string is
    begin
        return data.par_string_2;
    end function;

    function get_param_3(
        data : t_com_data
    ) return string is
    begin
        return data.par_string_3;
    end function;

    function get_param(
        data : t_com_data
    ) return boolean is
    begin
        return data.par_bool;
    end function;

    function get_param_2(
        data : t_com_data
    ) return boolean is
    begin
        return data.par_bool_2;
    end function;

    function get_param_3(
        data : t_com_data
    ) return boolean is
    begin
        return data.par_bool_3;
    end function;

    -----------------------------------------------------------------------
    -- Communication mailbox
    -----------------------------------------------------------------------
    type t_com_mailbox is protected body

        type t_slot is record
            state      : t_com_slot_state;
            seq        : natural;
            dest       : natural;
            msg_code   : integer;
            reply_code : natural;
            data       : t_com_data;
        end record;

        type t_slot_array is array (0 to C_COM_MAILBOX_DEPTH - 1) of t_slot;

        variable slots    : t_slot_array := (others => (SLOT_FREE, 0, 0, 0, 0, C_COM_DATA_INIT));
        variable next_seq : natural := 0;

        impure function push(
            constant dest     : natural;
            constant msg_code : integer;
            constant data     : t_com_data
        ) return natural is
        begin
            for i in slots'range loop
                if slots(i).state = SLOT_FREE then
                    slots(i) := (SLOT_PENDING, next_seq, dest, msg_code, 0, data);
                    next_seq := next_seq + 1;
                    return i;
                end if;
            end loop;
            assert false
                report "Communication mailbox full - increase C_COM_MAILBOX_DEPTH"
                severity error;
            return 0;
        end function;

        procedure try_pop(
            constant dest       : in  natural;
                     found      : out boolean;
                     token      : out natural;
                     msg_code   : out integer;
            variable data       : out t_com_data
        ) is
            variable best     : integer := -1;
            variable best_seq : natural;
        begin
            for i in slots'range loop
                if slots(i).state = SLOT_PENDING and slots(i).dest = dest then
                    if best = -1 or slots(i).seq < best_seq then
                        best     := i;
                        best_seq := slots(i).seq;
                    end if;
                end if;
            end loop;

            found := (best /= -1);
            if found then
                slots(best).state := SLOT_IN_PROGRESS;
                token    := best;
                msg_code := slots(best).msg_code;
                data     := slots(best).data;
            else
                token    := 0;
                msg_code := 0;
                data     := C_COM_DATA_INIT;
            end if;
        end procedure;

        procedure post_reply(
            constant token      : in natural;
            constant reply_code : in natural;
            constant data       : in t_com_data
        ) is
        begin
            slots(token).state      := SLOT_REPLIED;
            slots(token).reply_code := reply_code;
            slots(token).data       := data;
        end procedure;

        impure function reply_ready(token : natural) return boolean is
        begin
            return slots(token).state = SLOT_REPLIED;
        end function;

        procedure take_reply(
            token       : in  natural;
            reply_code  : out natural;
            variable data : out t_com_data
        ) is
        begin
            reply_code := slots(token).reply_code;
            data       := slots(token).data;
            slots(token).state := SLOT_FREE;
        end procedure;

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

end package body;