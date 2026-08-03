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
--  Purpose:
--    Package with the pseudo random number functions. Functions with postix
--    "_v" return variables, functions with postfix "_s" return signals.
--
--    For simulation only.
--
--    Random object (numbers, bits, vectors...) are generated from Random pool.
--    Random pool has uniform distribution.
--
--    Pointer to the pool must be provided before each generation. Pointer is
--    incremented inside each function to manage avoid repetitive values and
--    simplify application code.
--
--    Additional functions for generation of real numbers based on selected
--    distribution are implemented.
--
--    DEVELOPER WARNING:
--      Note that variable and signal versions of functions are implemented
--      separately on purpose! Incrementing pointer to random pool is not
--      implemented in separate function on purpose! This increases code size,
--      but it provides performance benefits which are markable!!!
--
--------------------------------------------------------------------------------
-- Revision History:
--
--    30.5.2016   Created file
--     2.5.2018   Updated function descriptions. Added "refresh" option to
--                signal versions of functions. Added probability distributions.
--    13.3.2021   Modify to shared variable implementation, not needing to
--                pass the rand_ctr signal.
--------------------------------------------------------------------------------

library ctu_can_agents;
context ctu_can_agents.ieee_context;

use ctu_can_agents.tb_report_pkg.all;

package body tb_random_pkg is

    type t_rand_ctr is protected body

        variable counter : natural range 0 to RAND_POOL_SIZE := 0;

        impure function get return natural is
        begin
            return counter;
        end function;

        procedure set(
            value         : in    natural range 0 to RAND_POOL_SIZE
        ) is
        begin
            counter := value;
        end procedure;

        procedure increment is
        begin
            counter := (counter + 1) mod RAND_POOL_SIZE;
        end procedure;

    end protected body;

	shared variable rand_ctr : t_rand_ctr;


    procedure apply_rand_seed(
        constant seed            : in   natural
    ) is
    begin
        info_m("Random initialized with seed " & natural'image(seed));
        rand_ctr.set(seed mod RAND_POOL_SIZE);
    end procedure;


    -- variation of above, only returns the seed value
    impure function apply_rand_seed(
        constant seed            : in   natural
    ) return natural is
    begin
        info_m("Random initialized with seed " & natural'image(seed));
        rand_ctr.set(seed);
        return seed;
    end function;


    procedure rand_real_s(
        signal   retval           : out   real;
        constant refresh          : in    boolean := true
    ) is
    begin
        rand_ctr.increment;

        retVal <= randomLibData(rand_ctr.get);
        if (refresh) then
            wait for 0 ns;
        end if;
    end procedure;


    procedure rand_real_v(
        variable retval         : out   real
    ) is
    begin
        rand_ctr.increment;

        retVal := randomLibData(rand_ctr.get);
    end procedure;

	impure function rand_real return real
	is begin
		rand_ctr.increment;
		return randomLibData(rand_ctr.get);
	end function;


    procedure rand_int_s(
        constant max            : in    natural;
        signal   retval         : out   natural;
        constant refresh        : in    boolean := true
    )is
        variable tmp            :       real;
    begin
        rand_ctr.increment;

        tmp := randomLibData(rand_ctr.get);
        retval <= natural(tmp * real(max));

        if (refresh) then
            wait for 0 ns;
        end if;
    end procedure;


    procedure rand_int_v(
        constant max            : in    natural;
        variable retval         : out   natural
    ) is
        variable tmp            :       real;
    begin
        rand_ctr.increment;

        tmp := randomLibData(rand_ctr.get);
        retval := natural(tmp * real(max));
    end procedure;

	impure function rand_int(
		constant max            : in    natural
	) return integer is
	begin
		rand_ctr.increment;
		return integer(randomLibData(rand_ctr.get) * real(max));
	end function;

    procedure rand_logic_s(
        signal   retval         : out 	std_logic;
        constant chances        : in 	real;
        constant refresh        : in    boolean := true
    )is
    begin
        rand_ctr.increment;

        if (randomLibData(rand_ctr.get) < chances) then
            retVal <= '1';
        else
            retVal <= '0';
        end if;

        if (refresh) then
            wait for 0 ns;
        end if;
    end procedure;


    procedure rand_logic_v(
        variable retval         : out   std_logic;
        constant chances        : in    real
    ) is
    begin
        rand_ctr.increment;
        wait for 0 ns;

        if (randomLibData(rand_ctr.get) < chances) then
            retVal := '1';
        else
            retVal := '0';
        end if;
    end procedure;


	impure function rand_logic(
		constant chances        : in    real
	) return std_logic is
	begin
		rand_ctr.increment;
		if (randomLibData(rand_ctr.get) < chances) then
            return '1';
        else
            return '0';
        end if;
	end function;


    procedure rand_logic_vect_s(
        signal   retVal         : out   std_logic_vector;
        constant chances        : in    real;
        constant refresh        : in    boolean := true
    ) is
    begin
        for i in 0 to retVal'length - 1 loop
            rand_ctr.increment;
            wait for 0 ns;

            if (randomLibData(rand_ctr.get) < chances) then
                retVal(i) <= '1';
            else
                retVal(i) <= '0';
            end if;
        end loop;

        if (refresh) then
            wait for 0 ns;
        end if;
    end procedure;


    procedure rand_logic_vect_v(
        variable retVal         : out   std_logic_vector;
        constant chances        : in    real
    ) is
    begin
        for i in 0 to retVal'length - 1 loop
            rand_ctr.increment;

            wait for 0 ns;

            if (randomLibData(rand_ctr.get) < chances) then
                retVal(i) := '1';
            else
                retVal(i) := '0';
            end if;

        end loop;
    end procedure;


    procedure rand_logic_vect_cons_s(
        signal   retVal         : inout std_logic_vector;
        constant cons_chance    : in    real
    ) is
        variable tmp            :       std_logic;
        variable tmp_real       :       real;
    begin
        rand_logic_v(tmp, 0.5);
        retVal(0) <= tmp;

        for i in 1 to retVal'length - 1 loop

            -- Swap value with "p(1 - cons_chance)"
            rand_real_v(tmp_real);
            wait for 0 ns;
            if (tmp_real > cons_chance) then
                tmp := not tmp;
            end if;

            retVal(i) <= tmp;
        end loop;

        wait for 0 ns;
    end procedure;


    procedure rand_logic_vect_cons_v(
        variable retVal         : inout std_logic_vector;
        constant cons_chance    : in    real
    ) is
        variable tmp            :       std_logic;
        variable tmp_real       :       real;
    begin
        rand_logic_v(tmp, 0.5);
        retVal(0) := tmp;

        for i in 1 to retVal'length - 1 loop

            -- Swap value with "p(1 - cons_chance)"
            rand_real_v(tmp_real);
            wait for 0 ns;
            if (tmp_real > cons_chance) then
                tmp := not tmp;
            end if;

            retVal(i) := tmp;
        end loop;
    end procedure;


    procedure rand_logic_vect_bt_s(
        signal   retVal         : inout std_logic_vector;
        constant bt             : in    integer;
        constant chances        : in    real;
        constant refresh        : in    boolean := true
    )is
    begin
        for i in 0 to retVal'length - 1 loop
            rand_ctr.increment;
            wait for 0 ns;

            if (randomLibData(rand_ctr.get) < chances) then
                retVal(i) <= '1';
            else
                retVal(i) <= '0';
            end if;

        end loop;

        if (unsigned(retVal) <= bt) then
          retval <= std_logic_vector(to_unsigned(bt + 1, retval'length));
        end if;

        if (refresh) then
            wait for 0 ns;
        end if;
    end procedure;


    procedure wait_rand_cycles(
        signal   clk            : in    std_logic;
        constant min            : in    integer;
        constant max            : in    integer
    )is
        variable rand_val       :       natural;
    begin
        if (max < min) then
            report "Invalid input parameters, MAX lower than MIN" severity
            error;
        else
            rand_int_v(max - min, rand_val);
            rand_val := rand_val + min;

            for i in 0 to rand_val loop
                wait until rising_edge(clk);
            end loop;
        end if;
    end procedure;


    procedure rand_logic_vect_bt_v(
        variable retVal         : inout std_logic_vector;
        constant bt             : in    integer;
        constant chances        : in    real
    )is
    begin
        for i in 0 to retVal'length - 1 loop

            rand_ctr.increment;
            wait for 0 ns;

            if (randomLibData(rand_ctr.get) < chances) then
                retVal(i) := '1';
            else
                retVal(i) := '0';
            end if;

        end loop;

        if (unsigned(retVal) <= bt) then
          retval := std_logic_vector(to_unsigned(bt + 1, retval'length));
        end if;
    end procedure;


    procedure rand_gauss(
        constant iter_amount       : in    natural;
        constant mean              : in    real;
        constant variance          : in    real;
        variable retVal            : out   real
    ) is
        variable accum             :       real := 0.0;
        variable aux               :       real;
    begin
        accum := 0.0;

        -- Sum up "iter_amount" numbers which have uniform distribution
        -- from (0,1) interval with 1/12 variance.
        for i in 0 to iter_amount - 1 loop
            rand_real_v(aux);
            accum := accum + aux;
        end loop;

        -- Now accum has mean equal to iter_amount/2. Variance is now
        -- "sqrt(1/12) / iter_amount". Transform it to mean equal zero.
        accum := accum - (real(iter_amount) / 2.0);
        accum := accum / SQRT (real(iter_amount) / 12.0);

        -- Now we have standard normal distribution we just scale it to the
        -- given mean and variance.
        accum := accum * variance;
        accum := accum + mean;

        if (accum < 0.0) then
            accum   := 0.0;
        end if;
        retVal      := accum;
    end procedure;


    procedure rand_exponential(
        constant scale              : in    real;
        variable retVal             : out   real
    ) is
        variable scale_pos          :       real;
        variable tmp                :       real;
    begin
        scale_pos := scale * (-1.0);
        rand_real_v(tmp);
        retVal := scale_pos *  LOG (tmp);
    end procedure;


    procedure rand_real_distr_v(
        variable retVal             : out   real;
        constant distribution	    : in	rand_distribution_type;
        constant parameters		    : in 	rand_distribution_par_type
    ) is
    begin
        case distribution is

        when GAUSS =>
            rand_gauss(integer(parameters(GAUSS_iterations)),
                       parameters(GAUSS_mean),
                       parameters(GAUSS_variance),
                       retVal);

        when EXPONENTIAL =>
            rand_exponential(parameters(EXPONENTIAL_mean), retVal);

        when others =>
            report "Unsupported probability distribution" severity warning;
            retVal := 0.0;

        end case;
    end procedure;


end package body;
