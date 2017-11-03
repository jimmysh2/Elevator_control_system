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
     upreq_lift1,downreq_lift1, upreq_lift2,downreq_lift2: out std_logic_vector(3 downto 0); to_sdb: out std_logic_vector(7 downto 0));
end entity;
--------------
----LIFT_CONTROLLER----
library ieee;
use ieee.std_logic_1164.all;

entity lift_controller is
port (clk:in std_logic; lift_floor : in std_logic_vector(3 downto 0) ; door_open,door_close: in std_logic; up_request_rh,down_request_rh : in std_logic_vector(3 downto 0); reset : in std_logic;
      lift_status : out std_logic_vector(3 downto 0);req_indicator:out std_logic_vector(3 downto 0); door,mov:out std_logic;to_sdb:out std_logic_vector(7 downto 0));
end entity;
-----------
-----STATUS_DISPLAY_BLOCK----
library ieee;
use ieee.std_logic_1164.all;
entity sdb is
port(clock:in std_logic; lift1_status,lift1_req_indicator,lift2_status,lift2_req_indicator : in std_logic_vector(3 downto 0);from_rh: in std_logic_vector(7 downto 0);
    led_outputs :out std_logic_vector(15 downto 0); anode: out std_logic_vector(3 downto 0); cathode:out std_logic_vector(6 downto 0); 
    lift1_door, lift2_door,lift1_m,lift2_m: in std_logic);
end entity;

----CLOCK SETTER
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_unsigned.all;

entity clock_set is
    port(mode,clock_in : in std_logic; display_clock,work_clock : out std_logic);
end entity;
-----
-------DELAY CREATOR
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity delay is
port(clk,e1,e2,e3,e4: in std_logic; d1,d2,d3,d4: out std_logic);
--port(clk,e: in std_logic; d: out std_logic);
end entity;
---
---------END OF ENTITIES

------ ARCHITECTURE of TOP LEVEL ENTITY
architecture behav of lab8_elevator_control is

----- signal declarations
signal lift1_status,lift2_status : std_logic_vector(3 downto 0);
signal up_lift1,down_lift1,up_lift2,down_lift2: std_logic_vector(3 downto 0);

signal to_sdb_from_rh,to_sdb_from_lc1,to_sdb_from_lc2,to_sdb: std_logic_vector(7 downto 0);

signal lift1_req_indicator : std_logic_vector(3 downto 0);
signal lift2_req_indicator : std_logic_vector(3 downto 0);
signal display_clock: std_logic;
signal work_clock: std_logic;
signal lift1_door,lift2_door : std_logic;
signal lift1_m,lift2_m : std_logic;
-----
begin
	--- to_sdb is the signal(vector) which contains LED outputs for requests from outside the lifts
    to_sdb <= to_sdb_from_rh or to_sdb_from_lc1 or to_sdb_from_lc2 ;
	
    --- COMPONENT INSTANTIATIONS
	
    x1: entity work.request_handler(behav)
        port map(work_clock,reset,up_request,down_request,lift1_status, lift2_status,up_lift1, down_lift1, up_lift2,down_lift2, to_sdb_from_rh);
    ---------
    x2: entity work.lift_controller(behav)
        port map(work_clock,lift1_floor , door_open(0) , door_close(0) ,up_lift1,down_lift1, reset , lift1_status , lift1_req_indicator,lift1_door,lift1_m,to_sdb_from_lc1);
    
    x3: entity work.lift_controller(behav)
        port map(work_clock,lift2_floor , door_open(1) , door_close(1) ,up_lift2,down_lift2, reset , lift2_status , lift2_req_indicator,lift2_door,lift2_m,to_sdb_from_lc2);
    ---------
    x4: entity work.sdb(behav)
        port map(display_clock, lift1_status, lift1_req_indicator, lift2_status, lift2_req_indicator ,to_sdb,led_outputs, anode, cathode,lift1_door,lift2_door,lift1_m,lift2_m);
    ---------
	x5: entity work.clock_set(behav)
        port map('0',clk,display_clock,work_clock);
end architecture;
-----------------------------------------------------------
------ARCHITECTURE of LIFT CONTROLLER
architecture behav of lift_controller is

----- signal declarations
    signal idle : std_logic:='1';
    signal dir : std_logic:='1';
    signal state : std_logic_vector(2 downto 0):="000";
    ---
    signal target : std_logic_vector(3 downto 0);
    signal up_request : std_logic_vector(3 downto 0);
    signal down_request : std_logic_vector(3 downto 0);
    ---
    signal e1,e2,e3,e4 : std_logic:='0';
    signal d1,d2,d3,d4 : std_logic:='0';
    signal doreq : std_logic:='0';
    signal dcreq : std_logic:='0';
    signal m : std_logic:='0'; -- this signal is special and it becomes '1' only when the door is opening or closing else it remains '0'
-----    
    begin
		--- Component instantiation of delay creator
        delay_element: entity work.delay(behav)
                       port map(clk,e1,e2,e3,e4,d1,d2,d3,d4);
        -------
		--- to_sdb is the signal(vector) which contains LED outputs for requests assigned to this lift from outside
        to_sdb<=down_request & up_request;
        ------             
        idle<='1' when target="0000" and up_request="0000" and down_request="0000" else '0';
        door<= state(0);
        mov<=m;
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
               e1<='0';e2<='0';e3<='0';e4<='0';dir<='1';state<="000";doreq<='0';dcreq<='0';m<='0';
            
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
                                ------ Floor 0, door close
                                when "001" =>
                                    
                                    dir<='1';
                                    if target(0)='1' or up_request(0)='1' then ------open the door after 0.1 or 0.5 sec depending on door request
                                        m<='1';
                                        if doreq='1' then --delay of 0.1 sec
                                            e1<='1';
                                            if d1='1' then
                                                state<="000";  doreq<='0'; e1<='0';target(0)<='0'; up_request(0)<='0';m<='0'; end if;
                                        
                                        else --delay of 0.5 sec
                                            e2<='1';
                                            if d2='1' then
                                                state<="000"; e2<='0';target(0)<='0'; up_request(0)<='0';m<='0'; end if;
                                        end if;
                                    
                                    else if target(3 downto 1)>"000" or up_request(2 downto 1)>"00" or down_request(3 downto 1)>"000" then ---after 2 sec delay change state to 011
                                            e4<='1';
                                            if d4='1' then
                                                state<="011"; e4<='0'; end if;
                                        
                                         ------------------------
                                         else ---you can play with door open/close
                                                                                                                              
                                              if doreq='1' then --delay of 0.1 sec and instantaneously start opening the door
                                                  e1<='1';m<='1';
                                                  if d1='1' then state<="000"; doreq<='0'; e1<='0';m<='0'; end if;
                                                  
                                              else --state remains same
                                                 state<="001";
                                              end if;
                                         end if;
                                    end if;
                                    
                                ------
                                ------ Floor 1, door close
                                when "011" =>
                                    
                                    if idle='1' then dir<='1'; end if;
                                    
                                    if target(1)='1' or up_request(1)='1' or down_request(1)='1' then ------open the door after 0.1 or 0.5 sec
                                        m<='1';
                                        if doreq='1' then --delay of 0.1 sec
                                            e1<='1';
                                            if d1='1' then
                                                state<="010"; doreq<='0'; e1<='0';target(1)<='0'; up_request(1)<='0'; down_request(1)<='0';m<='0'; end if;
                                        
                                        else --delay of 0.5 sec
                                            e2<='1';
                                            if d2='1' then
                                                state<="010"; e2<='0';target(1)<='0'; up_request(1)<='0'; down_request(1)<='0';m<='0'; end if;
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
                                                    
                                                else ---lift is idle so you can play with door open/close
                                                                                                                                                                                  
                                                      if doreq='1' then --delay of 0.1 sec and instantaneously start opening the door
                                                          e1<='1';m<='1';
                                                          if d1='1' then state<="010"; doreq<='0'; e1<='0';m<='0'; end if;
                                                          
                                                      else --state remains same
                                                         state<="011";
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
                                    
                                --------
                                ------- Floor 2 , door close
                                when "101" =>
                                    
                                    if idle='1' then dir<='1'; end if;
                                    
                                    if target(2)='1' or up_request(2)='1' or down_request(2)='1' then ------open the door after 0.1 or 0.5 sec
                                        m<='1';
                                        if doreq='1' then --delay of 0.1 sec
                                            e1<='1';
                                            if d1='1' then
                                                state<="100"; doreq<='0'; e1<='0';target(2)<='0'; up_request(2)<='0'; down_request(2)<='0';m<='0'; end if;
                                        
                                        else --delay of 0.5 sec
                                            e2<='1';
                                            if d2='1' then
                                                state<="100"; e2<='0';target(2)<='0'; up_request(2)<='0'; down_request(2)<='0';m<='0'; end if;
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
                                                    
                                                 else ---lift is idle so you can play with door open/close
                                                                                                                                                                                                                                     
                                                     if doreq='1' then --delay of 0.1 sec and instantaneously start opening the door
                                                         e1<='1';m<='1';
                                                         if d1='1' then state<="100"; doreq<='0'; e1<='0';m<='0'; end if;
                                                         
                                                     else --state remains same
                                                        state<="101";
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
                                ------ Floor 3 , door close
                                when "111" =>
								
                                    m<='0';
                                    dir<='0';
                                    if target(3)='1' or down_request(3)='1' then ------open the door after 0.1 or 0.5 sec depending on door request
                                        m<='1';
                                        if doreq='1' then --delay of 0.1 sec
                                            e1<='1';
                                            if d1='1' then
                                                state<="110"; doreq<='0'; e1<='0';target(3)<='0'; down_request(3)<='0';m<='0'; end if;
                                        
                                        else --delay of 0.5 sec
                                            e2<='1';
                                            if d2='1' then
                                                state<="110"; e2<='0';target(3)<='0'; down_request(3)<='0';m<='0'; end if;
                                        end if;
                                    
                                    else if target(2 downto 0)>"000" or up_request(2 downto 0)>"000" or down_request(2 downto 1)>"00" then ---after 2 sec delay change state to 101
                                            e4<='1';
                                            if d4='1' then
                                                state<="101"; e4<='0'; end if;
                                        
                                         else ---lift is idle so you can play with door open/close
                                                                                                                                                                                                                                 
                                             if doreq='1' then --delay of 0.1 sec and instantaneously start opening the door
                                                 e1<='1';m<='1';
                                                 if d1='1' then state<="110"; doreq<='0'; e1<='0';m<='0'; end if;
                                                 
                                             else --state remains same
                                                state<="111";
                                             end if;
                                        end if;
                                    end if;
                                -------
                                ----- Floor 0 , door open
                                when "000" =>
								
                                    if target(0)='1' or up_request(0)='1' or down_request(0)='1' then
                                        target(0)<='0'; up_request(0)<='0'; down_request(0)<='0';
                                        
                                    ----if there are pending requests then close the door after delay depending on door_close request
                                    else if target>"0000" or up_request(2 downto 0)>"000" or down_request(3 downto 1)>"000" then
                                    
                                            if dcreq='1' then --delay of 0.5 sec and instantaneously start closing the door
                                                e2<='1';m<='1';
                                                if d2='1' then state<="001"; dcreq<='0'; e2<='0';m<='0'; end if;
                                                
                                            else --delay of 1 sec and then start closing the door
                                                if m='0' then
                                                    e3<='1';
                                                    if d3='1' then e3<='0';m<='1'; end if;
                                                                                                
                                                else --delay of 0.5 sec
                                                    e2<='1';
                                                    if d2='1' then state<="001"; e2<='0';m<='0'; end if;
                                                end if;
                                            end if;
                                         else ---you can play with door open/close
                                                                                     
                                             if dcreq='1' then --delay of 0.5 sec and instantaneously start closing the door
                                                 e2<='1';m<='1';
                                                 if d2='1' then state<="001"; dcreq<='0'; e2<='0';m<='0'; end if;
                                                 
                                             else --state remains same
                                                state<="000";
                                             end if;
                                        end if;
                                    end if;
                                -----
                                ----Floor 1 , door open
                                when "010" =>
								
                                    if target(1)='1' or up_request(1)='1' or down_request(1)='1' then
                                        target(1)<='0'; up_request(1)<='0'; down_request(1)<='0';
                                        
                                    ----if there are pending requests then close the door after delay depending on door_close request
                                    else if target>"0000" or up_request(2 downto 0)>"000" or down_request(3 downto 1)>"000" then
                                    
                                            if dcreq='1' then --delay of 0.5 sec and instantaneously start closing the door
                                                e2<='1';m<='1';
                                                if d2='1' then state<="011"; dcreq<='0'; e2<='0';m<='0'; end if;
                                                
                                            else --delay of 1 sec and then start closing the door
                                                if m='0' then
                                                    e3<='1';
                                                    if d3='1' then e3<='0';m<='1'; end if;
                                                                                                
                                                else --delay of 0.5 sec
                                                    e2<='1';
                                                    if d2='1' then state<="011"; e2<='0';m<='0'; end if;
                                                end if;
                                            end if;
                                            
                                         else ---you can play with door open/close
                                         
                                             if dcreq='1' then --delay of 0.5 sec and instantaneously start closing the door
                                                 e2<='1';m<='1';
                                                 if d2='1' then state<="011"; dcreq<='0'; e2<='0';m<='0'; end if;
                                                 
                                             else --state remains same
                                                state<="010";
                                             end if;
                                        end if;
                                    end if;
                                    
                                -----
                                ----Floor 2 , door open
                                when "100" =>
								
                                    if target(2)='1' or up_request(2)='1' or down_request(2)='1' then
                                        target(2)<='0'; up_request(2)<='0'; down_request(2)<='0';
                                        
                                    ----if there are pending requests then close the door after delay depending on door_close request
                                    else if target>"0000" or up_request(2 downto 0)>"000" or down_request(3 downto 1)>"000" then
                                            
                                            if dcreq='1' then --delay of 0.5 sec and instantaneously start closing the door
                                                e2<='1';m<='1';
                                                if d2='1' then state<="101"; dcreq<='0'; e2<='0';m<='0'; end if;
                                                
                                            else --delay of 1 sec and then start closing the door
                                                if m='0' then
                                                    e3<='1';
                                                    if d3='1' then e3<='0';m<='1'; end if;
                                                                                                
                                                else --delay of 0.5 sec
                                                    e2<='1';
                                                    if d2='1' then state<="101"; e2<='0';m<='0'; end if;
                                                end if;
                                            end if;
                                         else ---you can play with door open/close
                                                                                     
                                             if dcreq='1' then --delay of 0.5 sec and instantaneously start closing the door
                                                 e2<='1';m<='1';
                                                 if d2='1' then state<="101"; dcreq<='0'; e2<='0';m<='0'; end if;
                                                 
                                             else --state remains same
                                                state<="100";
                                             end if;
                                        end if;
                                    end if;
                                -----
                                ----Floor 3 , door open
                                when "110" =>
								
                                    if target(3)='1' or up_request(3)='1' or down_request(3)='1' then
                                        target(3)<='0'; up_request(3)<='0'; down_request(3)<='0';
                                        
                                    ----if there are pending requests then close the door after delay depending on door_close request
                                    else if target>"0000" or up_request(2 downto 0)>"000" or down_request(3 downto 1)>"000" then
                                    
                                            if dcreq='1' then --delay of 0.5 sec and instantaneously start closing the door
                                                e2<='1';m<='1';
                                                if d2='1' then state<="111"; dcreq<='0'; e2<='0';m<='0'; end if;
                                                
                                            else --delay of 1 sec and then start closing the door
                                                if m='0' then
                                                    e3<='1';
                                                    if d3='1' then e3<='0';m<='1'; end if;
                                                                                                
                                                else --delay of 0.5 sec
                                                    e2<='1';
                                                    if d2='1' then state<="111"; e2<='0';m<='0'; end if;
                                                end if;
                                            end if;
                                         else ---you can play with door open/close
                                                                                     
                                             if dcreq='1' then --delay of 0.5 sec and instantaneously start closing the door
                                                 e2<='1';m<='1';
                                                 if d2='1' then state<="111"; dcreq<='0'; e2<='0';m<='0'; end if;
                                                 
                                             else --state remains same
                                                state<="110";
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
------------------------------------
------- ARCHITECTURE of DELAY CREATOR
architecture behav of delay is
signal c1,c2,c3,c4 : std_logic_vector(8 downto 0):="000000000";
begin
    process(clk)
    begin
        if clk='1' and clk'event then
            
            if e1='1' then c1<=c1+1;
            else c1<="000000000"; end if;
            
            if e2='1' then c2<=c2+1;
            else c2<="000000000"; end if;
            
            if e3='1' then c3<=c3+1;
            else c3<="000000000"; end if;
            
            if e4='1' then c4<=c4+1;
            else c4<="000000000"; end if;
			
        end if;
    end process;
    
    d1<='1' when c1(4)='1' else '0'; -- d1 represents delay of 0.1 sec (approx.)
    d2<='1' when c2(6)='1' else '0'; -- d2 represents delay of 0.5 sec (approx.)
    d3<='1' when c3(7)='1' else '0'; -- d3 represents delay of 1 sec (approx.)
    d4<='1' when c4(8)='1' else '0'; -- d4 represents delay of 2 sec (approx.)

end architecture;
----------------------------------------
-------- ARCHITECTURE of REQUEST HANDLER
architecture behav of request_handler is

----- signal declarations
signal up_req : std_logic_vector(3 downto 0);
signal down_req : std_logic_vector(3 downto 0);
signal idle1 : std_logic;
signal idle2 : std_logic;
signal up_lift1,down_lift1,up_lift2,down_lift2 : std_logic_vector(3 downto 0);
signal lift1_floor : integer:=0;
signal lift2_floor : integer:=0;
signal lift1_mov : std_logic:='0';
signal lift2_mov : std_logic:='0';
------
begin
    to_sdb<=down_req & up_req;
    upreq_lift1<=up_lift1;
    downreq_lift1<=down_lift1;
    upreq_lift2<=up_lift2;
    downreq_lift2<=down_lift2;
    -----
    -------             
    idle1<='1' when lift1_status(1 downto 0) ="00" or lift1_status(1 downto 0) ="11" else '0';
    idle2<='1' when lift2_status(1 downto 0) ="00" or lift2_status(1 downto 0) ="11" else '0';
    lift1_mov<='0' when lift1_status(1 downto 0)= "01" else '1';
    lift2_mov<='0' when lift2_status(1 downto 0)= "01" else '1';
    -------
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
	--------
    process(clk,up_request,down_request,reset)
    begin
        if reset='1' then
            up_lift1<="0000";
            down_lift1<="0000";
            up_lift2<="0000";
            down_lift2<="0000";
            down_req<="0000";
            up_req<="0000";
                        
        else if up_request>"0000" or down_request>"0000" then
                up_req <= up_req or up_request;
                down_req <= down_req or down_request;
                up_req(3)<='0';
                down_req(0)<='0';
                
            else
                if(clk='0' and clk'event) then
                    --- up request from floor 0
                    if up_req(0)='1' then
                        if up_lift1(0)='1' or up_lift2(0)='1' then 
                            up_lift1(0)<='0';up_lift2(0)<='0';up_req(0)<='0';
                        else
                            if lift1_floor>0 and lift2_floor>0 then
                                if idle1='1' then ---send pulse to lift1_controller
                                    up_lift1(0)<='1';
                                    
                                else if idle2='1' then --send pulse to lift2_controller
                                        up_lift2(0)<='1';
                                        
                                    end if;
                                end if;
                             else if lift1_floor=0 then ---send pulse to lift1_controller
                                         up_lift1(0)<='1';
                                         
                                  else ---send pulse to lift2_controller
                                          up_lift2(0)<='1';
                                          
                                  end if;
                             end if;
                         end if;
                    end if;
                    ----down request from floor 3
                    if down_req(3)='1' then
                        if down_lift1(3)='1' or down_lift2(3)='1' then 
                            down_lift1(3)<='0';down_lift2(3)<='0';down_req(3)<='0';--e2<='0';--e2='1' then
                            
                        else
                            if lift1_floor<3 and lift2_floor<3 then
                                if idle1='1' then ---send pulse to lift1_controller
                                    down_lift1(3)<='1';
                                    
                                else if idle2='1' then --send pulse to lift2_controller
                                        down_lift2(3)<='1';
                                        
                                    end if;
                                end if;
                            else if lift1_floor=3 then ---send pulse to lift1_controller
                                    down_lift1(3)<='1';
                                    
                                else --if lift2_floor=3 then --send pulse to lift2_controller
                                        down_lift2(3)<='1';
                                        
                                     --end if;
                                end if;
                            end if;
                        end if;
                    end if;
                    --------up request from floor 1
                    if up_req(1)='1' then
                        if up_lift1(1)='1' or up_lift2(1)='1' then 
                            up_lift1(1)<='0';up_lift2(1)<='0';up_req(1)<='0';
                        else
                            if lift1_floor=0 then ---send pulse to lift1_controller
                                up_lift1(1)<='1';
                                                                
                            else if lift2_floor=0 then ---send pulse to lift2_controller
                                    up_lift2(1)<='1';
                                                                    
                                else
                                    if idle1='1' then ---send pulse to lift1_controller
                                        up_lift1(1)<='1';
                                        
                                    else if idle2='1' then --send pulse to lift2_controller
                                            up_lift2(1)<='1';
                                            
                                        end if;
                                    end if;
                                end if;
                            end if;
                        end if;
                    end if;
                    --------down request from floor 1
                    if down_req(1)='1' then
                        if down_lift1(1)='1' or down_lift2(1)='1' then 
                            down_lift1(1)<='0';down_lift2(1)<='0';down_req(1)<='0';
                        else
                            if lift1_floor>0 and lift1_mov='0' then ---send pulse to lift1_controller
                                down_lift1(1)<='1';
                                
                            else if lift2_floor>0 and lift2_mov='0' then ---send pulse to lift2_controller
                                    down_lift2(1)<='1';
                                    
                                else 
                                    if idle1='1' then ---send pulse to lift1_controller
                                        down_lift1(1)<='1';
                                        
                                    else if idle2='1' then --send pulse to lift2_controller
                                            down_lift2(1)<='1';
                                            
                                        end if;
                                    end if;
                                end if;    
                            end if;
                        end if;
                    end if;
                    -------------up request from floor 2
                    if up_req(2)='1' then
                        if up_lift1(2)='1' or up_lift2(2)='1' then 
                            up_lift1(2)<='0';up_lift2(2)<='0';up_req(2)<='0';
                            
                        else
                            if lift1_floor < 2 and lift1_mov='1' then
                                up_lift1(2)<='1';
                                
                            else if lift2_floor < 2 and lift2_mov='1' then
                                    up_lift2(2)<='1';
                                    
                                else
                                    if idle1='1' then ---send pulse to lift1_controller
                                        up_lift1(2)<='1';
                                        
                                    else if idle2='1' then --send pulse to lift2_controller
                                            up_lift2(2)<='1';
                                            
                                        end if;
                                    end if;
                                end if;
                            end if;
                        end if;
                    end if;
                    ----------down request from floor 2
                    if down_req(2)='1' then
                        if down_lift1(2)='1' or down_lift2(2)='1' then 
                            down_lift1(2)<='0';down_lift2(2)<='0';down_req(2)<='0';
                            
                        else
                            if lift1_floor > 1 and lift1_mov='0' then
                                down_lift1(2)<='1';
                                
                            else if lift2_floor > 1 and lift2_mov='0' then
                                    down_lift2(2)<='1';
                                    
                                else
                                    if idle1='1' then ---send pulse to lift1_controller
                                        down_lift1(2)<='1';
                                        
                                    else if idle2='1' then --send pulse to lift2_controller
                                            down_lift2(2)<='1';
                                            
                                        end if;
                                    end if;
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
end architecture;
----------------------------
------- ARCHITECTURE of STATUS DISPLAY BLOCK
architecture behav of sdb is

begin
	---- led_outputs is the final output to be displayed on the onboard LEDs
    led_outputs <= lift1_req_indicator & lift2_req_indicator & from_rh;
    ----
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
                            if lift2_m='1' then digits:='c';
                            else if lift2_door<='0' then digits:='o';
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
                            if lift1_m='1' then digits:='c';
                            else if lift1_door<='0' then digits:='o';
                                else 
                                    case lift1_status(1 downto 0) is 
                                        when "01" =>
                                            digits:='d';
                                        when "10" =>
                                            digits:='u';
                                        when others =>
                                            digits:='c';
                                    end case;
                                end if;
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
--------------------------
------- ARCHITECTURE of CLOCK SETTER
architecture behav of clock_set is
        signal counter : std_logic_vector(19 downto 0):=(others=>'0');
        begin
        process(clock_in)
        begin
            if(clock_in='1' and clock_in'event) then
                counter <= counter +1;
            end if;
        end process;
        
        display_clock <= counter(17) when mode='0' else clock_in;    
        work_clock <= counter(19) when mode='0' else counter(1);
end architecture;
----------------------
------------------------------END OF ELEVATOR CONTROL SYSTEM -------------