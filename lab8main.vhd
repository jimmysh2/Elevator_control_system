--CREATED BY:
-- HARSHIT GOEL (2016CS10319)

---------------------------------------------------------------------------------------
---- BRIEF DESCRIPTION OF ALL THE ENTITIES AND SIGNALS
----
--   ENTITY 1: REQUEST_HANDLER
--           this component takes requests (from outside the lift) from each floor for going up or down.
--           then it assigns each request to resp. lift acc. to the lift_status and outputs these requests to be displayed on LEDS.
--           (reset is just to start the whole system from a known base state)
--   ENTITY 2&3 : LIFT_CONTROLLERS
--              these take input from user inside the lift and also from request handler (which gives the request of users outside the lift)
--              then the controller processes these requests and determines the behaviour and future(next) status of the lift.
--              the lift_status signal contains information about :
--              1.the floor of the lift & 2.the status of the lift(up, down, idle->(door open/close))
--              (reset is just to start the whole system from a known base state which is floor=0 & door=open)
--   ENTITY 4 : STATUS_DISPLAY_BLOCK
--            this block receives the status of both the lifts and also the requests from users outside the lift(through request_handler)
--            then it simply displays the results on the LEDs and SSD accordingly.  

----- FSM ---
-----possible changes:
---  1. Allow to open the door when it is closing
---  2. Initialize e1,e2,e3,e4 inside delay element if count is going much high bcuz this means that delay was interrupted
-----------------------------------------------------------------------------------------
----- TOP LEVEL ENTITY
library ieee;
use ieee.std_logic_1164.all;

entity lab8_elevator_control is
port(clk,reset:in std_logic; up_request, down_request: in std_logic_vector(3 downto 0);
     lift1_floor, lift2_floor : in std_logic_vector(3 downto 0); door_open,door_close: in std_logic_vector(1 downto 0);
     led_outputs :out std_logic_vector(15 downto 0); anode: out std_logic_vector(3 downto 0); cathode:out std_logic_vector(6 downto 0));
end entity;
-------------
----REQUEST HANDLER----
library ieee;
use ieee.std_logic_1164.all;

entity request_handler is
port(clk,reset: in std_logic; up_request,down_request: in std_logic_vector(3 downto 0);lift1_status, lift2_status : in std_logic_vector(3 downto 0);
     up_lift1,down_lift1, up_lift2,down_lift2: out std_logic_vector(3 downto 0); to_sdb: out std_logic_vector(7 downto 0));
end entity;
--------------
----LIFT_CONTROLLER----
library ieee;
use ieee.std_logic_1164.all;

entity lift_controller is
port (clk:in std_logic; lift_floor : in std_logic_vector(3 downto 0) ; door_open,door_close: in std_logic; up_request_rh,down_request_rh : in std_logic_vector(3 downto 0); reset : in std_logic;
      lift_status : out std_logic_vector(3 downto 0);req_indicator:out std_logic_vector(3 downto 0); door:out std_logic);
end entity;
-----------
-----STATUS_DISPLAY_BLOCK----
library ieee;
use ieee.std_logic_1164.all;
entity sdb is
port(clock:in std_logic; lift1_status,lift1_req_indicator,lift2_status,lift2_req_indicator : in std_logic_vector(3 downto 0);from_rh: in std_logic_vector(7 downto 0);
    led_outputs :out std_logic_vector(15 downto 0); anode: out std_logic_vector(3 downto 0); cathode:out std_logic_vector(6 downto 0); 
    lift1_door, lift2_door: in std_logic);
end entity;

----CLOCK SETTER
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_unsigned.all;

entity clock_set is
    port(b,clock_in : in std_logic; display_clock,work_clock : out std_logic);
end entity;
-----
-------DELAY CREATOR
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity delay is
--port(clk,e1,e2,e3,e4: in std_logic; d1,d2,d3,d4: out std_logic);
port(clk,e: in std_logic; d: out std_logic);
end entity;
---
---------END OF ENTITIES

------ ARCHITECTURE of TOP LEVEL ENTITY
architecture behav of lab8_elevator_control is

signal lift1_status : std_logic_vector(3 downto 0);
signal lift2_status : std_logic_vector(3 downto 0);
signal up_lift1: std_logic_vector(3 downto 0);
signal down_lift1: std_logic_vector(3 downto 0);
signal up_lift2: std_logic_vector(3 downto 0);
signal down_lift2: std_logic_vector(3 downto 0);
signal to_sdb: std_logic_vector(7 downto 0);
signal lift1_req_indicator : std_logic_vector(3 downto 0);
signal lift2_req_indicator : std_logic_vector(3 downto 0);
SIGNAL display_clock: std_logic;
SIGNAL work_clock: std_logic;
signal lift1_door : std_logic;
signal lift2_door : std_logic;

begin
    --entity request_handler is
    --port(clk,reset: in std_logic; up_request,down_request: in std_logic_vector(3 downto 0);lift1_status, lift2_status : in std_logic_vector(3 downto 0);
        -- up_lift1,down_lift1, up_lift2,down_lift2: out std_logic_vector(3 downto 0); to_sdb: out std_logic_vector(7 downto 0));
    --end entity;
    x1: entity work.request_handler(behav)
        port map(work_clock,reset,up_request,down_request,lift1_status, lift2_status,up_lift1, down_lift1, up_lift2,down_lift2, to_sdb);
    
    --entity lift_controller is
    --port (clk, lift_floor , door_open,door_close , up_request_rh,down_request_rh : in std_logic_vector(3 downto 0); reset : in std_logic;
        --  lift_status : out std_logic_vector(3 downto 0);req_indicator:out std_logic_vector(3 downto 0) ); -- door:out std_logic);
    --end entity;
    x2: entity work.lift_controller(behav)
        port map(work_clock,lift1_floor , door_open(0) , door_close(0) ,up_lift1,down_lift1, reset , lift1_status , lift1_req_indicator,lift1_door);
    
    x3: entity work.lift_controller(behav)
        port map(work_clock,lift2_floor , door_open(1) , door_close(1) ,up_lift2,down_lift2, reset , lift2_status , lift2_req_indicator,lift2_door);
    
    --entity sdb is
    --port(clk:in std_logic; lift1_status,lift1_req_indicator,lift2_status,lift2_req_indicator : in std_logic_vector(3 downto 0);from_rh: in std_logic_vector(7 downto 0);
        --led_outputs :out std_logic_vector(15 downto 0); anode: out std_logic_vector(3 downto 0); cathode:out std_logic_vector(6 downto 0));
    --end entity;
    x4: entity work.sdb(behav)
        port map(display_clock, lift1_status, lift1_req_indicator, lift2_status, lift2_req_indicator ,to_sdb,led_outputs, anode, cathode,lift1_door,lift2_door);
    x5: entity work.clock_set(behav)
        port map('1',clk,display_clock,work_clock);
end architecture;
-----------------------------------------------------------
-----------------------------------------------------------
architecture behav of lift_controller is

    signal idle : std_logic:='1';
    signal dir : std_logic:='1';
    signal state : std_logic_vector(2 downto 0):="000";
    ---
    signal target : std_logic_vector(3 downto 0);
    signal up_request : std_logic_vector(3 downto 0);
    signal down_request : std_logic_vector(3 downto 0);
    ---
    signal e1 : std_logic:='0';
    signal e2 : std_logic:='0';
    signal e3 : std_logic:='0';
    signal e4 : std_logic:='0';
    signal d1 : std_logic:='0';
    signal d2 : std_logic:='0';
    signal d3 : std_logic:='0';
    signal d4 : std_logic:='0';
    signal doreq : std_logic:='0';
    signal dcreq : std_logic:='0';
    
    begin
        delay_element1: entity work.delay(behav)
                       port map(clk,e1,d1);
        delay_element2: entity work.delay(behav)
                       port map(clk,e2,d2);
        delay_element3: entity work.delay(behav)
                       port map(clk,e3,d3);
        delay_element4: entity work.delay(behav)
                       port map(clk,e4,d4);
        -------             
        idle<='1' when target="0000" and up_request="0000" and down_request="0000" else '0';
        door<= state(0);
        
        ---now assign lift_status based on state, dir and idle values
        lift_status(3 downto 2)<= state(2 downto 1);
        lift_status(1 downto 0) <=  
                                    "11" when idle='1' and state(0)='1' else
                                    "00" when idle='1' and state(0)='0' else
                                    "10" when idle='0' and dir='1' else
                                    "01" when idle='0' and dir='0' ;                
        req_indicator<=target;
        ----MAIN PROCESS--
        process(clk,reset,up_request_rh,down_request_rh,door_open,door_close)
        begin
            if reset='1'then
               target<="0000"; up_request<="0000"; down_request<="0000";
               e1<='0';e2<='0';e3<='0';e4<='0';dir<='1';state<="000";doreq<='0';dcreq<='0';
            
            else if up_request_rh>"0000" or down_request_rh>"0000" or lift_floor>"0000" then
                target<= target or lift_floor;
                up_request <= up_request or up_request_rh;
                down_request<= down_request or down_request_rh;
                else if door_open='1' or door_close='1' then
                        doreq<=doreq or door_open;
                        dcreq<=dcreq or door_close;
                    
                    else
                        if clk='0' and clk'event then
                            case state is
                                ------ F_0 close
                                when "001" =>
                                    dir<='1';
                                    if target(0)='1' or up_request(0)='1' then ------open the door after 0.1 or 0.5 sec depending on door request
                                    
                                        if doreq='1' then --delay of 0.1 sec
                                            e1<='1';
                                            if d1='1' then
                                                state<="000"; target(0)<='0'; up_request(0)<='0'; doreq<='0'; e1<='0'; end if;
                                        
                                        else --delay of 0.5 sec
                                            e2<='1';
                                            if d2='1' then
                                                state<="000"; target(0)<='0'; up_request(0)<='0'; e2<='0'; end if;
                                        end if;
                                    
                                    else if target(3 downto 1)>"000" or up_request(2 downto 1)>"00" or down_request(3 downto 1)>"000" then ---after 2 sec delay change state to 011
                                            e4<='1';
                                            if d4='1' then
                                                state<="011"; e4<='0'; end if; ---modified for testing and found problem = no delay created!!
                                        
                                        else ----this means that the door is closed but the lift is idle
                                            if doreq='1' then ---open the door after 0.1 sec
                                                e1<='1';
                                                if d1='1' then
                                                    state<="000"; doreq<='0'; e1<='0'; end if;
                                            else ---open the door after 0.5 sec
                                                e2<='1';
                                                if d2='1' then
                                                    state<="000"; e2<='0'; end if;
                                            end if;
                                        end if;
                                    end if;
                                    --state<="001"; ---testing purpose
                                ------
                                ------ F_1 close
                                when "011" =>
                                    if idle='1' then dir<='1'; end if;
                                    
                                    if target(1)='1' or up_request(1)='1' or down_request(1)='1' then ------open the door after 0.1 or 0.5 sec
                                    
                                        if doreq='1' then --delay of 0.1 sec
                                            e1<='1';
                                            if d1='1' then
                                                state<="010"; target(1)<='0'; up_request(1)<='0'; down_request(1)<='0'; doreq<='0'; e1<='0'; end if;
                                        
                                        else --delay of 0.5 sec
                                            e2<='1';
                                            if d2='1' then
                                                state<="010"; target(1)<='0'; up_request(1)<='0'; down_request(1)<='0'; e2<='0'; end if; --tested by modifying
                                        end if;
                                    
                                    else
                                        if dir='1' then
                                            if target(3 downto 2)>"00" or up_request(2)='1' or down_request(3 downto 2)>"00" then ---after 2 sec delay, change state to 101
                                                e4<='1';
                                                if d4='1' then
                                                    state<="101"; e4<='0';end if;
                                            else
                                                if target(0)='1' or up_request(0)='1' then --- change dir to 0
                                                    dir<='0';
                                                    
                                                else --- this means that lift is close but idle, => same code as for F_0 close
                                                    if doreq='1' then ---open the door after 0.1 sec
                                                        e1<='1';
                                                        if d1='1' then
                                                            state<="010"; doreq<='0'; e1<='0'; end if;
                                                    else ---open the door after 0.5 sec
                                                        e2<='1';
                                                        if d2='1' then
                                                            state<="010"; e2<='0'; end if;
                                                    end if;
                                                end if;
                                            end if;
                                        else
                                            if target(0)='1' or up_request(0)='1' then ---after 2 sec delay, change state to 001
                                                e4<='1';
                                                if d4='1' then
                                                    state<="001"; e4<='0';end if;
                                                    
                                            else dir<='1';
                                            end if;
                                        end if;
                                    end if;
                                    --state<="011"; ---testing purpose
                                --------
                                ------- F_2 close
                                when "101" =>
                                    if idle='1' then dir<='1'; end if;
                                    
                                    if target(2)='1' or up_request(2)='1' or down_request(2)='1' then ------open the door after 0.1 or 0.5 sec
                                    
                                        if doreq='1' then --delay of 0.1 sec
                                            e1<='1';
                                            if d1='1' then
                                                state<="100"; target(2)<='0'; up_request(2)<='0'; down_request(2)<='0'; doreq<='0'; e1<='0'; end if;
                                        
                                        else --delay of 0.5 sec
                                            e2<='1';
                                            if d2='1' then
                                                state<="100"; target(2)<='0'; up_request(2)<='0'; down_request(2)<='0'; e2<='0'; end if;
                                        end if;
                                    
                                    else
                                        if dir='1' then
                                            if target(3)='1' or down_request(3)='1' then ---after 2 sec delay, change state to 111
                                                e4<='1';
                                                if d4='1' then
                                                    state<="111"; e4<='0';end if;
                                            else
                                                if target(1 downto 0)>"00" or up_request(1 downto 0)>"00" or down_request(1)='1' then --- change dir to 0
                                                    dir<='0';
                                                    
                                                else --- this means that lift is close but idle, => same code as for F_0 close
                                                    if doreq='1' then ---open the door after 0.1 sec
                                                        e1<='1';
                                                        if d1='1' then
                                                            state<="100"; doreq<='0'; e1<='0'; end if;
                                                    else ---open the door after 0.5 sec
                                                        e2<='1';
                                                        if d2='1' then
                                                            state<="100"; e2<='0'; end if;
                                                    end if;
                                                end if;
                                            end if;
                                        else
                                            if target(1 downto 0)>"00" or up_request(1 downto 0)>"00" or down_request(1)='1' then ---after 2 sec delay, change state to 011
                                                e4<='1';
                                                if d4='1' then
                                                    state<="011"; e4<='0';end if;
                                                    
                                            else dir<='1';
                                            end if;
                                        end if;
                                    end if;
                                -----
                                ------ F_3 close
                                when "111" =>
                                    dir<='0';
                                    if target(3)='1' or down_request(3)='1' then ------open the door after 0.1 or 0.5 sec depending on door request
                                    
                                        if doreq='1' then --delay of 0.1 sec
                                            e1<='1';
                                            if d1='1' then
                                                state<="110"; target(3)<='0'; down_request(3)<='0'; doreq<='0'; e1<='0'; end if;
                                        
                                        else --delay of 0.5 sec
                                            e2<='1';
                                            if d2='1' then
                                                state<="110"; target(3)<='0'; down_request(3)<='0'; e2<='0'; end if;
                                        end if;
                                    
                                    else if target(2 downto 0)>"000" or up_request(2 downto 0)>"000" or down_request(2 downto 1)>"00" then ---after 2 sec delay change state to 101
                                            e4<='1';
                                            if d4='1' then
                                                state<="101"; e4<='0'; end if;
                                        
                                        else ----this means that the door is closed but the lift is idle
                                            if doreq='1' then ---open the door after 0.1 sec
                                                e1<='1';
                                                if d1='1' then
                                                    state<="110"; doreq<='0'; e1<='0'; end if;
                                            else ---open the door after 0.5 sec
                                                e2<='1';
                                                if d2='1' then
                                                    state<="110"; e2<='0'; end if;
                                            end if;
                                        end if;
                                    end if;
                                -------
                                ----- F_0 open
                                when "000" =>
                                    if target(0)='1' or up_request(0)='1' or down_request(0)='1' then
                                        target(0)<='0'; up_request(0)<='0'; down_request(0)<='0';
                                        
                                    ----if there are pending requests then close the door after delay depending on door_close request
                                    else if target>"0000" or up_request(2 downto 0)>"000" or down_request(3 downto 1)>"000" then
                                            if dcreq='1' then --delay of 0.5 sec
                                                e2<='1';
                                                if d2='1' then state<="001"; dcreq<='0'; e2<='0'; end if;
                                            else --delay of 1 sec
                                                e3<='1';
                                                if d3='1' then state<="001"; e3<='0'; end if;
                                            end if;
                                        end if;
                                    end if;
                                -----
                                ----F_1 open
                                when "010" =>
                                    if target(1)='1' or up_request(1)='1' or down_request(1)='1' then
                                        target(1)<='0'; up_request(1)<='0'; down_request(1)<='0';
                                        
                                    ----if there are pending requests then close the door after delay depending on door_close request
                                    else if target>"0000" or up_request(2 downto 0)>"000" or down_request(3 downto 1)>"000" then
                                            if dcreq='1' then --delay of 0.5 sec
                                                e2<='1';
                                                if d2='1' then state<="011"; dcreq<='0'; e2<='0'; end if;
                                            else --delay of 1 sec
                                                e3<='1';
                                                if d3='1' then state<="011"; e3<='0'; end if;
                                            end if;
                                         else state<="010"; --state remains same
                                        end if;
                                    end if;
                                    --state<="011";---testing purpose
                                -----
                                ----F_2 open
                                when "100" =>
                                    if target(2)='1' or up_request(2)='1' or down_request(2)='1' then
                                        target(2)<='0'; up_request(2)<='0'; down_request(2)<='0';
                                        
                                    ----if there are pending requests then close the door after delay depending on door_close request
                                    else if target>"0000" or up_request(2 downto 0)>"000" or down_request(3 downto 1)>"000" then
                                            if dcreq='1' then --delay of 0.5 sec
                                                e2<='1';
                                                if d2='1' then state<="101"; dcreq<='0'; e2<='0'; end if;
                                            else --delay of 1 sec
                                                e3<='1';
                                                if d3='1' then state<="101"; e3<='0'; end if;
                                            end if;
                                        end if;
                                    end if;
                                -----
                                ----F_3 open
                                when "110" =>
                                    if target(3)='1' or up_request(3)='1' or down_request(3)='1' then
                                        target(3)<='0'; up_request(3)<='0'; down_request(3)<='0';
                                        
                                    ----if there are pending requests then close the door after delay depending on door_close request
                                    else if target>"0000" or up_request(2 downto 0)>"000" or down_request(3 downto 1)>"000" then
                                            if dcreq='1' then --delay of 0.5 sec
                                                e2<='1';
                                                if d2='1' then state<="111"; dcreq<='0'; e2<='0'; end if;
                                            else --delay of 1 sec
                                                e3<='1';
                                                if d3='1' then state<="111"; e3<='0'; end if;
                                            end if;
                                        end if;
                                    end if;
                                when others =>
                                    state<="000";
                            end case;
                        end if;
                    end if;
                end if;
            end if;
        end process;
        ---
end architecture;
------------
architecture behav of delay is
--signal de1: integer:=0;
--signal de2: integer:=0;
--signal de3: integer:=0;
--signal de4: integer:=0;
signal counter : std_logic_vector(2 downto 0);
begin
    process(clk)
    begin
        if clk='1' and clk'event then
            if e='1' then
                counter <= counter +1 ;
            else counter<="000";
            end if;
            --if e1='1' then if de1<2 then de1<=de1+1; else de1<=0; end if;
            --else de1<=0; end if;
            
            --if e2='1' then if de2<3 then de2<=de2+1; else de2<=0; end if;
            --else de2<=0; end if;
            
            --if e3='1' then if de3<4 then de3<=de3+1; else de3<=0; end if;
            --else de3<=0; end if;
            
            --if e4='1' then if de4<5 then de4<=de4+1; else de4<=0; end if;
            --else de4<=0; end if;
        end if;
    end process;
    --d1<='1' when counter="010" else '0';
    --d2<='1' when counter="011" else '0';
    d<='1' when counter="100" else '0';
    --d4<='1' when counter="101" else '0';
    --d1<='1' when de1=10000000 else '0'; ---delay of 0.1 sec
    --d2<='1' when de2=50000000 else '0'; --- delay of 0.5 sec
    --d3<='1' when de3=100000000 else '0'; ---delay of 1 sec
    --d4<='1' when de4=200000000 else '0'; ---delay of 2 sec
    --d1<='1' when de1=10 else '0'; ---delay of 0.1 sec
    --d2<='1' when de2=50 else '0'; --- delay of 0.5 sec
    --d3<='1' when de3=100 else '0'; ---delay of 1 sec
    --d4<='1' when de4=200 else '0'; ---delay of 2 sec
    
    ---below is for simulation 
    --d1<='1' when de1=2 else '0'; ---delay of 0.1 sec
    --d2<='1' when de2=3 else '0'; --- delay of 0.5 sec
    --d3<='1' when de3=4 else '0'; ---delay of 1 sec
    --d4<='1' when de4=5 else '0'; ---delay of 2 sec

end architecture;
----
architecture behav of request_handler is

signal up_req : std_logic_vector(3 downto 0);
signal down_req : std_logic_vector(3 downto 0);
signal idle1 : std_logic;
signal idle2 : std_logic;
signal c1 : integer:=0;
signal c2 : integer:=0;
signal c3 : integer:=0;
signal c4 : integer:=0;
signal c5 : integer:=0;
signal c6 : integer:=0;

signal lift1_floor : integer:=0;
signal lift2_floor : integer:=0;
signal lift1_mov : std_logic:='0';
signal lift2_mov : std_logic:='0';

begin
    to_sdb<=down_req & up_req;
    
    idle1<='1' when lift1_status(1 downto 0) ="00" or lift1_status(1 downto 0) ="11" else '0';
    idle2<='1' when lift2_status(1 downto 0) ="00" or lift2_status(1 downto 0) ="11" else '0';
    lift1_mov<='0' when lift1_status(1 downto 0)= "01" else '1';
    lift2_mov<='0' when lift2_status(1 downto 0)= "01" else '1';
    
    with lift1_status(3 downto 2) select lift1_floor <=
                                                        3 when "11",
                                                        2 when "10",
                                                        1 when "01",
                                                        0 when others;
    with lift2_status(3 downto 2) select lift2_floor <=
                                                        3 when "11",
                                                        2 when "10",
                                                        1 when "01",
                                                        0 when others;                                    

    process(clk,up_request,down_request,reset)
    begin
        if reset='1' then
            up_lift1<="0000";
            down_lift1<="0000";
            up_lift2<="0000";
            down_lift2<="0000";
            down_req<="0000";
            up_req<="0000";
            c1<=0;c2<=0;c3<=0;c4<=0;c5<=0;c6<=0;
            
        else if 
            up_request>"0000" or down_request>"0000" then
            up_req <= up_req or up_request;
            down_req <= down_req or down_request;
            up_req(3)<='0';
            down_req(0)<='0';
                
            else
                --- up request from floor 0
                if up_req(0)='1' then
                    if idle1='1' then ---send pulse to lift1_controller
                        up_lift1(0)<='1';
                        c1<=c1+1;
                        if(c1=2) then up_lift1(0)<='0';up_req(0)<='0';c1<=0; end if;
                    else if idle2='1' then --send pulse to lift2_controller
                            up_lift2(0)<='1';
                            c1<=c1+1;
                            if(c1=2) then up_lift2(0)<='0';up_req(0)<='0';c1<=0; end if;
                        end if;
                    end if;
                end if;
                ----down request from floor 3
                if down_req(3)='1' then
                    if lift1_floor>3 and lift2_floor>3 then
                        if idle1='1' then ---send pulse to lift1_controller
                            down_lift1(3)<='1';
                            c2<=c2+1;
                            if(c2=2) then down_lift1(3)<='0';down_req(3)<='0';c2<=0; end if;
                        else if idle2='1' then --send pulse to lift2_controller
                                down_lift2(3)<='1';
                                c2<=c2+1;
                                if(c2=2) then down_lift2(3)<='0';down_req(3)<='0';c2<=0; end if;
                            end if;
                        end if;
                    else if lift1_floor=3 then ---send pulse to lift1_controller
                            down_lift1(3)<='1';
                            c2<=c2+1;
                            if(c2=2) then down_lift1(3)<='0';down_req(3)<='0';c2<=0; end if;
                        else --send pulse to lift2_controller
                            down_lift2(3)<='1';
                            c2<=c2+1;
                            if(c2=2) then down_lift2(3)<='0';down_req(3)<='0';c2<=0; end if;
                        end if;
                    end if;
                end if;
                --------up request from floor 1
                if up_req(1)='1' then
                    if lift1_floor=0 then ---send pulse to lift1_controller
                        up_lift1(1)<='1';
                        c3<=c3+1;
                        if(c3=2) then up_lift1(1)<='0';up_req(1)<='0';c3<=0; end if;
                        
                    else if lift2_floor=0 then ---send pulse to lift2_controller
                            up_lift2(1)<='1';
                            c3<=c3+1;
                            if(c3=2) then up_lift2(1)<='0';up_req(1)<='0';c3<=0; end if;
                        
                        else
                            if idle1='1' then ---send pulse to lift1_controller
                                up_lift1(1)<='1';
                                c3<=c3+1;
                                if(c3=2) then up_lift1(1)<='0';up_req(1)<='0';c3<=0; end if;
                            else if idle2='1' then --send pulse to lift2_controller
                                    up_lift2(1)<='1';
                                    c3<=c3+1;
                                    if(c3=2) then up_lift2(1)<='0';up_req(1)<='0';c3<=0; end if;
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
                --------down request from floor 1
                if down_req(1)='1' then
                    if lift1_floor>0 and lift1_mov='0' then ---send pulse to lift1_controller
                        down_lift1(1)<='1';
                        c4<=c4+1;
                        if(c4=2) then down_lift1(1)<='0';down_req(1)<='0';c4<=0; end if;
                    else if lift2_floor>0 and lift2_mov='0' then ---send pulse to lift2_controller
                            down_lift2(1)<='1';
                            c4<=c4+1;
                            if(c4=2) then down_lift2(1)<='0';down_req(1)<='0';c4<=0; end if;
                        else 
                            if idle1='1' then ---send pulse to lift1_controller
                                down_lift1(1)<='1';
                                c4<=c4+1;
                                if(c4=2) then down_lift1(1)<='0';down_req(1)<='0';c4<=0; end if;
                            else if idle2='1' then --send pulse to lift2_controller
                                    down_lift2(1)<='1';
                                    c4<=c4+1;
                                    if(c4=2) then down_lift2(1)<='0';down_req(1)<='0';c4<=0; end if;
                                end if;
                            end if;
                        end if;    
                    end if;
                end if;
                -------------up request from floor 2
                if up_req(2)='1' then
                    if lift1_floor < 2 and lift1_mov='1' then
                        up_lift1(2)<='1';
                        c5<=c5+1;
                        if(c5=2) then up_lift1(2)<='0';up_req(2)<='0';c5<=0; end if;
                    else if lift2_floor < 2 and lift2_mov='1' then
                            up_lift2(2)<='1';
                            c5<=c5+1;
                            if(c5=2) then up_lift2(2)<='0';up_req(2)<='0';c5<=0; end if;
                        else
                            if idle1='1' then ---send pulse to lift1_controller
                                up_lift1(2)<='1';
                                c5<=c5+1;
                                if(c5=2) then up_lift1(2)<='0';up_req(2)<='0';c5<=0; end if;
                            else if idle2='1' then --send pulse to lift2_controller
                                    up_lift2(2)<='1';
                                    c5<=c5+1;
                                    if(c5=2) then up_lift2(2)<='0';up_req(2)<='0';c5<=0; end if;
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
                ----------down request from floor 2
                if down_req(2)='1' then
                    if lift1_floor > 1 and lift1_mov='0' then
                        down_lift1(2)<='1';
                        c6<=c6+1;
                        if(c6=2) then down_lift1(2)<='0';down_req(2)<='0';c6<=0; end if;
                    else if lift2_floor > 1 and lift2_mov='0' then
                            down_lift2(2)<='1';
                            c6<=c6+1;
                            if(c6=2) then down_lift2(2)<='0';down_req(2)<='0';c6<=0; end if;
                        else
                            if idle1='1' then ---send pulse to lift1_controller
                                down_lift1(2)<='1';
                                c6<=c6+1;
                                if(c6=2) then down_lift1(2)<='0';down_req(2)<='0';c6<=0; end if;
                            else if idle2='1' then --send pulse to lift2_controller
                                    down_lift2(2)<='1';
                                    c6<=c6+1;
                                    if(c6=2) then down_lift2(2)<='0';down_req(2)<='0';c6<=0; end if;
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
end architecture;
-------

architecture behav of sdb is

begin
    led_outputs <= lift1_req_indicator & lift2_req_indicator & from_rh;
    
    process(clock)
        type status is ('u','d','o','c','0','1','2','3');
        variable digits : status:='o';
        variable count : integer:=1;    
        begin
            if(clock='0' and clock'event) then
                if(count=4) then count:=1;
                else count:=count+1;
                end if;

                case count is
                    when 4 =>
                            anode<= "1110";
                            case lift2_status(3 downto 2) is 
                                when "00" =>
                                    digits:='0';
                                when "01" =>
                                    digits:='1';
                                when "10" =>
                                    digits:='2';
                                when others =>
                                    digits:='3';
                            end case;
                    
                    when 3 =>
                            anode<= "1101";
                            if lift2_door<='0' then digits:='o';
                            else 
                                case lift2_status(1 downto 0) is 
                                    when "01" =>
                                        digits:='d';
                                    when "10" =>
                                        digits:='u';
                                    when others =>
                                        digits:='c';
                                end case;
                            end if;
                    when 2 =>
                            anode<= "1011";
                            case lift1_status(3 downto 2) is 
                                when "00" =>
                                    digits:='0';
                                when "01" =>
                                    digits:='1';
                                when "10" =>
                                    digits:='2';
                                when others =>
                                    digits:='3';
                            end case;
                    when others =>
                            anode<= "0111";
                            if lift1_door<='0' then digits:='o';
                            else 
                                case lift1_status(1 downto 0) is 
                                    when "01" =>
                                        digits:='d';
                                    when "10" =>
                                        digits:='u';
                                    when "00" =>
                                        digits:='o';
                                    when others =>
                                        digits:='c';
                                end case;
                            end if;
                end case;

                case digits is
                    when '0' => cathode<="1000000";            
                    when '1' => cathode<="1111001";
                    when '2' => cathode<="0100100";
                    when '3' => cathode<="0110000";
                    when 'u' => cathode<="1100011";
                    when 'd' => cathode<="0100001";
                    when 'o' => cathode<="0100011";
                    when others=> cathode<="0100111";
                end case;
            end if;
        end process;
end architecture;
---
architecture behav of clock_set is
        signal counter : std_logic_vector(19 downto 0):=(others=>'0');
        begin
        process(clock_in)
        begin
            if(clock_in='1' and clock_in'event) then
                counter <= counter +1;
            end if;
        end process;
        
        display_clock <= counter(17) when b='0' else clock_in;    
        work_clock <= counter(19) when b='0' else counter(1);
end architecture;
----------------------
------------------------------END OF ELEVATOR CONTROL (LAB 8) -------------