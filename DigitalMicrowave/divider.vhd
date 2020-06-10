-- 分频器，产生秒表序列(时钟频率1MHz: 产生1s的周期序列) --
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity divider is
    port(
        -- in --
        clk: in std_logic; -- clk, 输入时钟
        rst: in std_logic; -- rst, 异步复位
        -- out --
        clk_out: out std_logic -- 输出1s为周期的时钟
    );
end divider;

architecture bhv of divider is
    signal outclk: std_logic := '0';
    signal count: integer range 0 to 500010:= 0; -- 内部计数器
    constant FREQUENCY: integer := 500000;--设置时钟频率1MHz
    --constant FREQUENCY: integer := 2;--设置时钟频率(for simulation)
begin
    clk_out <= outclk;
    process(clk, rst) begin
        if rst = '1' then
            count <= 0;
            outclk <= '0';
        elsif clk'event and clk = '1' then 
            if count < FREQUENCY then -- 一个上升沿计数器+1
                count <= count + 1;
            else -- 达到预设频率之后输出一个脉冲
                count <= 0; 
                outclk <= (not outclk); --跳变
            end if;
        end if;
    end process;
end bhv;