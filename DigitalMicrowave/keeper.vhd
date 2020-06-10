--  工作模块 --
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity keeper is
    port(
        -- in --
        clk: in std_logic; -- clk, 输入时钟脉冲
        rst: in std_logic; -- rst 异步复位
        confirm: in std_logic; -- confirm：按下时开始计时
        mode: in std_logic_vector(1 downto 0); -- 模式11下工作
        time_high: in std_logic_vector(3 downto 0); -- 倒计时开始的时间（十位）
        time_low: in std_logic_vector(3 downto 0); -- 倒计时开始的时间（个位）
        -- buffer --
        number_low: buffer std_logic_vector(3 downto 0); -- 剩余时间（个位）
        number_high: buffer std_logic_vector(3 downto 0) -- 剩余时间（十位）
    );
end keeper;

architecture bhv_kp of keeper is
    signal state: integer range 0 to 2 := 0; -- 状态机状态(0,1,2), 0:停止倒计时，1：开始倒计时
begin
    process(clk, rst, mode, time_low, time_high, number_low, number_high, confirm, state) begin
        if mode = "11" then -- 模式为11时
            if rst = '1' then -- rst切换模式，将剩余时间设置为实际时间， state=1进入工作循环
                state <= 1;
                number_low <= time_low; 
                number_high <= time_high;
            elsif clk'event and clk = '1' and confirm = '1' and state = 1 then -- confirm=1时，响应时钟，进行倒计时
                if number_low > "0000" then -- 个位-1
                    number_low <= number_low - 1;
                else -- 个位为0时，个位置9，十位-1.
                    number_low <= "1001"; 
                    if number_high > "0000" then
                        number_high <= number_high - 1;
                    else -- 倒计时到00之后结束，回到初始状态state=0
                        number_high <= "0000";
                        number_low <= "0000";
                        state <= 0;
                    end if;
                end if;
            end if;
        end if;
    end process;
end bhv_kp;
