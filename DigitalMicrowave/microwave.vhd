-- 模拟计费微波炉 --
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity microwave is
    port(
        -- in --
        clk: in std_logic; --输入的时钟，1MHz
        rst: in std_logic; --RST复位按钮，同时用于确认模式
        confirm: in std_logic; --确认键，用于确认每一位的输入，或者开始倒计时
        mode: in std_logic_vector(1 downto 0); --模式选择：10充值，01定时，11工作
        number: in std_logic_vector(3 downto 0); --输入的4bit二进制数，表示个位或十位
        -- out --
        alarm: out std_logic; --余额不足的提示灯
        display_low: out std_logic_vector(3 downto 0); --用于数码管显示个位，4bit，显示余额或时间
        display_high: out std_logic_vector(3 downto 0) --用于数码管显示十位，4bit，显示余额或时间
    );
end microwave;

architecture bhv_top of microwave is
    component divider
        port(
            -- in --
            clk: in std_logic; -- clk, 输入时钟
            rst: in std_logic; -- rst, 异步复位
            -- out --
            clk_out: out std_logic -- 输出1s为周期的时钟
        );
    end component;
    component charger
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
    end component;
    component setter
        port(
            -- in --
            confirm: in std_logic; -- 确认键，用于输入一位数字之后确定该位
            rst: in std_logic; -- rst复位
            mode: in std_logic_vector(1 downto 0);  -- 模式01时才使用该模块
            number: in std_logic_vector(3 downto 0); -- 输入的一位数
            -- out --
            number_low: out std_logic_vector(3 downto 0); -- 充值金额的个位
            number_high: out std_logic_vector(3 downto 0) -- 充值金额的十位
        );
    end component;
    component keeper
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
    end component;
    -- time set --
    signal time_low_buffer: std_logic_vector(3 downto 0) := "0000"; -- “定时”模式下设定的时间（个位）
    signal time_high_buffer: std_logic_vector(3 downto 0) := "0000"; -- “定时”模式下设定的时间（十位）
    signal time_low_real: std_logic_vector(3 downto 0) := "0000"; -- “实际时间”=min(设定时间，充值金额)（个位）
    signal time_high_real: std_logic_vector(3 downto 0) := "0000"; -- “实际时间”=min(设定时间，充值金额)（十位）
    -- money charged --
    signal money_low_buffer: std_logic_vector(3 downto 0) := "0000"; -- 充值金额（个位）
    signal money_high_buffer: std_logic_vector(3 downto 0) := "0000"; -- 充值金额（十位）
    -- time left -- 
    signal time_low_left: std_logic_vector(3 downto 0) := "0000"; -- 剩余时间（个位）
    signal time_high_left: std_logic_vector(3 downto 0) := "0000"; -- 剩余时间（十位）
    -- clock --
    signal clk_per_second: std_logic; -- T=1s clock --
    -- money --
    signal m_alarm: std_logic := '0'; -- 提示灯 --
    signal m_charge: integer range 0 to 99 := 0; -- 充值金额 --
    signal m_time: integer range 0 to 99 := 0; -- 设定的时间 --
begin
    -- 输出提示信息 --
    alarm <= m_alarm;
    -- 模块化映射 --
    m_clk_divider: divider port map(clk => clk,
                                    rst => rst, 
                                    clk_out => clk_per_second);
    m_charger: charger port map(confirm => confirm, 
                                rst => rst, 
                                mode => mode, 
                                number => number,
                                number_low => money_low_buffer, 
                                number_high => money_high_buffer);
    m_setter: setter port map(confirm => confirm, 
                              rst => rst, 
                              mode => mode, 
                              number => number,
                              number_low => time_low_buffer, 
                              number_high => time_high_buffer);
    m_keeper: keeper port map(clk => clk_per_second, 
                              rst => rst, 
                              mode => mode,
                              confirm => confirm,
                              time_high => time_high_real,
                              time_low => time_low_real,
                              number_low => time_low_left, 
                              number_high => time_high_left);
    -- 控制进程，用于 余额不足、显示数字 等功能 --
    process(rst, mode, time_low_left, time_high_left,
            money_low_buffer, money_high_buffer, 
            time_low_buffer, time_high_buffer,
            m_time, m_charge) begin
        if rst = '1' then -- 异步复位 --
            m_alarm  <= '0';
        end if;
        -- 对不同模式做不同处理 --
        case mode is
        when "01" => -- setter --
            if rst = '1' then -- rst清零 --
                time_high_real <= "0000";
                time_low_real <= "0000";
            end if; 
            -- 计算设定的时间 --
            m_time <= CONV_INTEGER(time_high_buffer)* 10 + CONV_INTEGER(time_low_buffer);
            if m_time > m_charge then -- 若金额 < 设定时间，将实际时间设定为金额，并alarm置1
                m_alarm <= '1';
                time_low_real <= money_low_buffer;
                time_high_real <= money_high_buffer;
            else -- 否则实际时间 = 设定时间
                time_low_real <= time_low_buffer;
                time_high_real <= time_high_buffer;  
            end if;
            -- 数码管显示设定的时间
            display_low <= time_low_buffer;
            display_high <= time_high_buffer;
        when "10" => -- charger --
            -- 数码管显示充值金额 --
            display_low <= money_low_buffer;
            display_high <= money_high_buffer;
            -- 计算充值金额 --
            m_charge <= CONV_INTEGER(money_high_buffer) * 10 + CONV_INTEGER(money_low_buffer);
        when "11" => -- keeper --
            -- 数码管显示剩余时间 --
            display_low <= time_low_left;
            display_high <= time_high_left;
        when others => null;
        end case;
    end process;
end bhv_top;