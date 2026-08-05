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
--    Memory Model
--
--    TODO: Description
--
--------------------------------------------------------------------------------
-- Revision History:
--    23.7.2026   Created file
--------------------------------------------------------------------------------

library ctu_can_agents;
context ctu_can_agents.ieee_context;
context ctu_can_agents.agents_deps_context;

use ctu_can_agents.mem_model_pkg.all;

entity mem_model is
    generic(
        G_COM_ID                : natural
    );
end entity;

architecture tb of mem_model is

    -----------------------------------------------------------------------
    -----------------------------------------------------------------------
    -----------------------------------------------------------------------
    -- Memory model type
    -----------------------------------------------------------------------
    -----------------------------------------------------------------------
    -----------------------------------------------------------------------

    -----------------------------------------------------------------------
    -----------------------------------------------------------------------
    -- Declaration
    -----------------------------------------------------------------------
    -----------------------------------------------------------------------
    type t_mem_model_map is protected

        -- Initialize the data structure (not the memory itself)
        procedure init;

        -- Configure initialization mode of the memory model
        procedure set_init_mode(
            im : t_mem_model_init_mode
        );

        -- Put data to the memory
        procedure put(
            address     : in  integer;
            data        : in  std_logic_vector
        );

        -- Get data from memory
        procedure get(
            address     : in  integer;
            data_ok     : out boolean;
            data        : out std_logic_vector
        );

        -- Dump memory contents
        procedure dump;

    end protected t_mem_model_map;

    -----------------------------------------------------------------------
    -----------------------------------------------------------------------
    -- Helpers
    -----------------------------------------------------------------------
    -----------------------------------------------------------------------
    type val_node_t;
    type val_node_ptr is access val_node_t;
    type val_node_t is record
        address     : integer;
        data        : std_logic_vector(7 downto 0);
        next_val    : val_node_ptr;
    end record;

    -- Hash bucket node for key storage
    type key_node_t;
    type key_node_ptr is access key_node_t;
    type key_node_t is record
        val_head    : val_node_ptr; -- FIFO head (Read/Pop location)
        val_tail    : val_node_ptr; -- FIFO tail (Write/Push location)
    end record;

    constant C_HASH_BUCKETS : integer := 512;
    type table_array_t is array (0 to C_HASH_BUCKETS - 1) of key_node_ptr;

    -----------------------------------------------------------------------
    -----------------------------------------------------------------------
    -- Type implementation
    -----------------------------------------------------------------------
    -----------------------------------------------------------------------
    type t_mem_model_map is protected body

        -----------------------------------------------------------------------
        -- Variables
        -----------------------------------------------------------------------
        variable table      : table_array_t := (others => null);
        variable init_mode  : t_mem_model_init_mode;

        -----------------------------------------------------------------------
        -- Local functions
        -----------------------------------------------------------------------
        function hash(
            address : integer
        ) return integer is
        begin
            return (address mod C_HASH_BUCKETS);
        end function;

        procedure find_key_node(
            address     : in  integer;
            rv          : out key_node_ptr
        ) is
            variable idx  : integer := hash(address);
            variable curr : key_node_ptr := table(idx);
        begin
            rv := table(hash(address));
        end procedure;

        procedure get_uninited_byte(
            rv      : out std_logic_vector(7 downto 0)
        ) is
        begin
            case init_mode is
            when MEM_MODEL_INIT_RANDOM =>
                rand_logic_vect_v(rv, 0.5);
            when MEM_MODEL_INIT_ZERO =>
                rv := (others => '0');
            when MEM_MODEL_INIT_X =>
                rv := (others => 'X');
            when MEM_MODEL_INIT_U =>
                rv := (others => 'U');
            end case;
        end procedure;

        -----------------------------------------------------------------------
        -- Public API
        -----------------------------------------------------------------------
        procedure init is
            variable k_node : key_node_ptr;
        begin
            for i in 0 to C_HASH_BUCKETS - 1 loop
                k_node          := new key_node_t;
                k_node.val_head := null;
                k_node.val_tail := null;
                table(i)        := k_node;
            end loop;
        end procedure;

        procedure set_init_mode(
            im : t_mem_model_init_mode
        ) is
        begin
            init_mode := im;
        end procedure;

        procedure put(
            address     : in  integer;
            data        : in  std_logic_vector
        ) is
            variable n_bytes    : integer;
            variable k_node     : key_node_ptr;
            variable v_node     : val_node_ptr;
        begin
            assert (data'length mod 8 = 0)
                report "Only multiples of 8 are supported";

            n_bytes := data'length / 8;
            byte_loop : for i in 0 to n_bytes - 1 loop
                find_key_node(address + i, k_node);

                v_node := k_node.val_head;
                if (v_node = null) then
                    v_node := new val_node_t;
                    v_node.address := address + i;
                    if (i = n_bytes - 1) then
                        v_node.data := data(data'length - 1 downto i * 8);
                    else
                        v_node.data := data(((i + 1) * 8) - 1 downto i * 8);
                    end if;
                    v_node.next_val := null;
                    k_node.val_head := v_node;
                    k_node.val_tail := v_node;
                    next;
                end if;

                key_loop: loop
                    -- Overwrite the address if it exists
                    if (v_node.address = address) then
                        v_node.data := data;
                        exit key_loop;
                    -- Append if at the end
                    elsif (v_node.next_val = null) then
                        v_node := new val_node_t;
                        v_node.address := address + i;
                        if (i = n_bytes - 1) then
                            v_node.data := data(data'length - 1 downto i * 8);
                        else
                            v_node.data := data(((i + 1) * 8) - 1 downto i * 8);
                        end if;
                        v_node.next_val := null;
                        k_node.val_tail.next_val := v_node;
                        k_node.val_tail := v_node;
                        exit key_loop;
                    -- Look at next simply
                    else
                        v_node := v_node.next_val;
                    end if;
                end loop;
            end loop;
        end procedure;

        procedure get(
            address     : in  integer;
            data_ok     : out boolean;
            data        : out std_logic_vector
        )is
            variable n_bytes    : integer;
            variable k_node     : key_node_ptr;
            variable v_node     : val_node_ptr;
            variable rv         : std_logic_vector(data'length - 1 downto 0);
            variable tmp_byte   : std_logic_vector(7 downto 0);
        begin
            assert (data'length mod 8 = 0)
                report "Only multiples of 8 are supported";

            n_bytes := data'length / 8;
            data_ok := true;

            byte_loop : for i in 0 to n_bytes - 1 loop
                find_key_node(address + i, k_node);

                if (k_node = null or k_node.val_head = null) then
                    get_uninited_byte(tmp_byte);
                    data_ok := false;
                else
                    v_node := k_node.val_head;
                    key_loop: loop
                        if (v_node.address = address + i) then
                            tmp_byte := v_node.data;
                            exit key_loop;
                        elsif (v_node.next_val = null) then
                            get_uninited_byte(tmp_byte);
                            data_ok := false;
                            exit key_loop;
                        else
                            v_node := v_node.next_val;
                        end if;
                    end loop;
                end if;
                rv(((i + 1) * 8) - 1 downto i * 8) := tmp_byte;
            end loop;
            data := rv;
        end procedure;

        procedure dump is
            variable k_node     : key_node_ptr;
            variable v_node     : val_node_ptr;
        begin
            -- TODO: Sort dumped contents!
            mem_model_info_m(G_COM_ID, "Memory Model content (unsorted):");

            for i in 0 to C_HASH_BUCKETS - 1 loop
                k_node := table(i);
                v_node := k_node.val_head;
                while (v_node /= null) loop
                    mem_model_info_m(G_COM_ID,
                                     "Address: 0x" & to_hstring(to_unsigned(v_node.address, 32)) &
                                     " Data: 0x" & to_hstring(v_node.data));
                    v_node := v_node.next_val;
                end loop;
            end loop;

        end procedure;

    end protected body t_mem_model_map;

    shared variable mem : t_mem_model_map;

begin

    --------------------------------------------------------------------------
    -- Initialization process
    --------------------------------------------------------------------------
    process
    begin
        mem.init;
        wait;
    end process;

    --------------------------------------------------------------------------
    -- Comunication receiver process
    ---------------------------------------------------------------------------
    p_receiver : process
        variable cmd            : integer;
        variable reply_code     : integer;
        variable size           : integer;
        variable data_ok        : boolean;
        -- TODO: Max length set to the same as in communication channel.
        --       This may need some more generic approach
        variable tmp_data       : std_logic_vector(255 downto 0);
        variable tmp_int        : integer;
    begin
        receive_start(default_channel, G_COM_ID);

        -- Command is sent as message type
        cmd := com_channel_data.get_msg_code;
        reply_code := C_REPLY_CODE_OK;

        case cmd is
        when MEM_MODEL_CMD_PUT_DATA =>
            size := com_channel_data.get_param_2;
            mem.put(
                com_channel_data.get_param,
                com_channel_data.get_param(size - 1 downto 0)
            );

        when MEM_MODEL_CMD_GET_DATA =>
            size := com_channel_data.get_param_2;
            mem.get(
                com_channel_data.get_param,
                data_ok,
                tmp_data(size - 1 downto 0)
            );
            com_channel_data.set_param(tmp_data);
            com_channel_data.set_param(data_ok);

        when MEM_MODEL_CMD_SET_NON_INIT_MODE =>
            tmp_int := com_channel_data.get_param;
            mem.set_init_mode(t_mem_model_init_mode'val(tmp_int));

        when MEM_MODEL_CMD_DUMP =>
            mem.dump;

        when others =>
            info_m("Invalid message type: " & integer'image(cmd));
            reply_code := C_REPLY_CODE_ERR;
        end case;

        receive_finish(default_channel, reply_code);
    end process;


end architecture;