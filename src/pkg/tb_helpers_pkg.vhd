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
--    Helper functions for CTU CAN testbench
--------------------------------------------------------------------------------
-- Revision History:
--    23.7.2026   Created file
--------------------------------------------------------------------------------

library ctu_can_agents;
context ctu_can_agents.ieee_context;

use ctu_can_agents.tb_report_pkg.all;

package tb_helpers_pkg is

    ---------------------------------------------------------------------------
    --
    ---------------------------------------------------------------------------
    procedure pli_str_to_logic_vector(
               input       : in   string;
        signal output      : out  std_logic_vector
    );


    ---------------------------------------------------------------------------
    --
    ---------------------------------------------------------------------------
    procedure pli_logic_vector_to_str(
                input       : in   std_logic_vector;
       variable output      : out  string
    );


    ---------------------------------------------------------------------------
    --
    ---------------------------------------------------------------------------
    procedure pli_time_to_logic_vector(
                 input       : in  time;
        variable output      : out std_logic_vector(63 downto 0)
    );


    ---------------------------------------------------------------------------
    --
    ---------------------------------------------------------------------------
    procedure pli_logic_vector_to_time(
                 input       : in  std_logic_vector(63 downto 0);
        variable output      : out time
    );

    ---------------------------------------------------------------------------
    --
    ---------------------------------------------------------------------------
    procedure check_access_size(
        address     : in    integer;
        size        : in    natural
    );

    ---------------------------------------------------------------------------
    --
    ---------------------------------------------------------------------------
    procedure convert_be_and_write_data(
                 address     : in    natural;
                 data_in     : in    std_logic_vector;
        variable be          : out   std_logic_vector(3 downto 0);
        variable write_data  : out   std_logic_vector(31 downto 0)
    );

    ---------------------------------------------------------------------------
    --
    ---------------------------------------------------------------------------
    procedure convert_be(
                 address     : in    natural;
                 data_in     : in    std_logic_vector;
        variable be          : out   std_logic_vector(3 downto 0)
    );

    ---------------------------------------------------------------------------
    --
    ---------------------------------------------------------------------------
    procedure convert_read_data(
                 address             : in    natural;
                 size                : in    natural;
                 data_in             : in    std_logic_vector(31 downto 0);
        variable data_out            : out   std_logic_vector
    );

end package;


package body tb_helpers_pkg is


    procedure pli_str_to_logic_vector(
               input       : in   string;
        signal output      : out  std_logic_vector
    ) is
        variable cropped_length : integer := input'length;
    begin
        -- By default null everywhere, no string character
        output(output'length - 1 downto 0) <= (OTHERS => '0');

        -- Crop if string is longer
        if (output'length < cropped_length * 8) then
            cropped_length := output'length / 8;
        end if;

        -- Convert as if ASCII
        for i in 0 to cropped_length - 1 loop
            output(i * 8 + 7 downto i * 8) <= std_logic_vector(to_unsigned(
                    character'pos(input(input'length - i)), 8));
        end loop;
    end procedure;


    procedure pli_logic_vector_to_str(
                input       : in   std_logic_vector;
       variable output      : out  string
    ) is
        variable cropped_length : integer := input'length / 8;
    begin
        -- By default null everywhere, no string character
        output(1 to output'high) := (OTHERS => ' ');

        -- Crop if vector is longer than output string
        if (cropped_length > output'length) then
            cropped_length := output'length;
        end if;

        -- Convert as if ASCII
        for i in 0 to cropped_length - 1 loop
            output(cropped_length - i) := character'val(to_integer(unsigned(
                            input(i * 8 + 7 downto i * 8))));
        end loop;
    end procedure;



    procedure pli_time_to_logic_vector(
                 input       : in  time;
        variable output      : out std_logic_vector(63 downto 0)
    ) is
        variable low       : integer;
        variable high      : integer;
    begin
        high := input / (integer'high * 1 fs);

        -- If input is higher than integer'high, it will overflow automatically
        --  performing needed modulo operation.
        low := input / 1 fs;

        output := (others => '0');
        output(30 downto 0) := std_logic_vector(to_unsigned(low, 31));
        output(61 downto 31) := std_logic_vector(to_unsigned(high, 31));

        -- Note: Positive integer is up to 2^31 - 1, convert to two integers
        --       and crop highest two bits. This will effectively overflow
        --       all time values above 2^62 * 1 fs, but we don't care!
    end procedure;


    procedure pli_logic_vector_to_time(
                 input       : in  std_logic_vector(63 downto 0);
        variable output      : out time
    ) is
        variable low       : integer;
        variable high      : integer;
    begin
        low := to_integer(unsigned(input(30 downto 0)));
        high := to_integer(unsigned(input(61 downto 31)));

        output := (low * 1 fs) + (high * (integer'high * 1 fs + 1 fs));
    end;

    ---------------------------------------------------------------------------
    -- 8, 16 and 32 bits accesses are supported. Also bursts of multiples of
    -- 32 bits. Unaligned accesses are not supported (e.g. writing 4 byte buffer
    -- to address 0x2).
    ---------------------------------------------------------------------------
    procedure check_access_size(
        address     : in    integer;
        size        : in    natural
    ) is
    begin
        if ((size /= 8) and (size /= 16) and ((size mod 32) /= 0)) then
            report "Access size shall be either 8, 16 or divisible by 32 (burst)." &
                   "access size " & integer'image(size) & "is not supported!" severity failure;
        end if;

        -- Half-word unaligned access
        if ((size = 16) and ((address mod 2) /= 0)) then
            report "2 byte access shall have address 2 bytes aligned" severity failure;
        end if;

        -- Word unaligned access
        if ((size mod 32) = 0) and ((address mod 4) /= 0) then
            report "4 x N byte access or shall have address 4 bytes aligned" severity failure;
        end if;

    end procedure;


    procedure convert_be_and_write_data(
                 address     : in    natural;
                 data_in     : in    std_logic_vector;
        variable be          : out   std_logic_vector(3 downto 0);
        variable write_data  : out   std_logic_vector(31 downto 0)
    ) is
    begin
        write_data := (OTHERS => '0');
        case data_in'length is
        when 8 =>
            case (address mod 4) is
            when 0 =>
                be := "0001";
                write_data(7 downto 0) := data_in;
            when 1 =>
                be := "0010";
                write_data(15 downto 8) := data_in;
            when 2 =>
                be := "0100";
                write_data(23 downto 16) := data_in;
            when 3 =>
                be := "1000";
                write_data(31 downto 24) := data_in;
            when others =>
                error_m("Unreachable code -> Simulator bug?");
            end case;
        when 16 =>
            case (address mod 4) is
            when 0 =>
                be := "0011";
                write_data(15 downto 0) := data_in;
            when 2 =>
                be := "1100";
                write_data(31 downto 16) := data_in;
            when others =>
                error_m("Unsupported 16 bit write at addr: " & to_string(address));
            end case;
        when others =>
            be := "1111";
            write_data(31 downto 0) := data_in;
        end case;
    end procedure;


    procedure convert_be(
                 address     : in    natural;
                 data_in     : in    std_logic_vector;
        variable be          : out   std_logic_vector(3 downto 0)
    )is
    begin

        case data_in'length is
        when 8 =>
            case (address mod 4) is
            when 0 =>
                be := "0001";
            when 1 =>
                be := "0010";
            when 2 =>
                be := "0100";
            when 3 =>
                be := "1000";
            when others =>
                error_m("Unreachable code -> Simulator bug?");
            end case;
        when 16 =>
            case (address mod 4) is
            when 0 =>
                be := "0011";
            when 2 =>
                be := "1100";
            when others =>
                error_m("16 bit access must be half-word aligned!");
            end case;
        when others =>
            be := "1111";
        end case;
    end procedure;

    procedure convert_read_data(
                 address             : in    natural;
                 size                : in    natural;
                 data_in             : in    std_logic_vector(31 downto 0);
        variable data_out            : out   std_logic_vector
    )is
    begin
        case size is
        when 8 =>
            case (address mod 4) is
            when 0 =>
                data_out(7 downto 0) := data_in(7 downto 0);
            when 1 =>
                data_out(7 downto 0) := data_in(15 downto 8);
            when 2 =>
                data_out(7 downto 0) := data_in(23 downto 16);
            when 3 =>
                data_out(7 downto 0) := data_in(31 downto 24);
            when others =>
                error_m("Invalid 32 bit access!");
            end case;
        when 16 =>
            case (address mod 4) is
            when 0 =>
                data_out(15 downto 0) := data_in(15 downto 0);
            when 2 =>
                data_out(15 downto 0) := data_in(31 downto 16);
            when others =>
                error_m("Invalid address for 16 bit access!");
            end case;
        when 32 =>
            data_out := data_in;
        when others =>
            error_m("Unknown access size: " & integer'image(size));
        end case;
    end;


end package body;
