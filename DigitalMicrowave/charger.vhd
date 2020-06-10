-- 充值模块 --
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- 充值模块 --
entity charger is
    port(
        -- in --
        confirm: in std_logic; -- 确认键，用于输入一位数字之后确定该位
        rst: in std_logic; -- rst复位
        mode: in std_logic_vector(1 downto 0); -- 模式10时才使用该模块
        number: in std_logic_vector(3 downto 0); -- 输入的一位数
        -- out --
        number_low: out std_logic_vector(3 downto 0); -- 充值金额的个位
        number_high: out std_logic_vector(3 downto 0) -- 充值金额的十位
    );
end charger;

architecture bhv_ch of charger is
    signal state: integer range 0 to 2 := 0; -- 状态机状态(0,1,2)，0：初始状态，1：输入十位，2：输入个位
begin
    -- 'mode changed to 10 -> rst -> number set -> confirm -> number set -> confirm' --
    process(confirm, rst, mode) begin
        if mode = "10" then -- 模式10 时
            if rst = '1' then -- 复位置零 --
                state <= 1; -- rst切换模式后进入等待状态 state=1
                number_high <= "0000";
                number_low <= "0000";
            elsif confirm'event and confirm = '1' then -- 按下confirm之后读入一位，并将状态转换到下一个
                case state is
                when 1 => -- state=1: 输入十位
                    number_high <= number;
                    state <= 2;
                when 2 => -- state=2: 输入个位
                    number_low <= number;
                    state <= 0; -- 回到初始状态
                when others => null;
                end case;
            end if;
        end if;
    end process;
end bhv_ch;