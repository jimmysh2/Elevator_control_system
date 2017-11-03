# Elevator Control System
Written in VHDL

CREATED BY:

HARSHIT GOEL

Indian Institute Of Technology Delhi

# Basic Concept Used : Finite State Machine (FSM) 
---------------------------------------------------------------------------------------
# Brief description of all the entities and some important signals

-->ENTITY 1: REQUEST_HANDLER

	This component takes requests (from outside the lift) from each floor for going up or down.
	Then it assigns each request to resp. lift acc. to the lift_status and outputs these requests to be displayed on LEDS.
             
-->ENTITY 2 : LIFT_CONTROLLER (this is same for both the lifts)

	This takes input from user inside the lift and also from request handler (request of users outside the lift)
	Then the controller processes these requests and determines the behaviour and future(next) status of the lift.
	The lift_status signal contains information about :
	1. The floor of the lift
	2. The status of the lift(up, down, idle->(door open/close))
              
-->ENTITY 3 : STATUS_DISPLAY_BLOCK

      This block receives the status of both the lifts and also the status of requests from users outside the lift
      Then it simply displays the results on the LEDs and SSD accordingly.
	  The 4 digit SSD Display is as follows:
	  Lift1 Status , Lift1 Floor , Lift2 Status , Lift2 Floor
	  Status:
		 u (if lift is moving up)
		 d (if lift is moving down)
		 o (if door of the lift is open)
		 c (if door of the lift is closed(or has started closing) and lift is not moving)
	  Floor: 0,1,2,3 (where 0 represents the ground floor)

-->ENTITY 4 : CLOCK_SETTER

	This component is used to slow the onboard clock for computation as well as display.
	It takes the onboard clock as input and gives work_clock and display_clock as outputs.
	The 'mode' is '0' for working on board and '1' for working in simulation on vivado.
	The display clock must be 4 times as fast as work_clock.

-->ENTITY 5 : DELAY_CREATOR

	This component is used to create the delay which represents the time taken to complete different tasks.
	The delays are as follows:
	a) 2 sec for floor change.
	b) 0.5 sec for door open/close but if door_open request is given then 0.1 sec for opening the door.
	c) 1 sec to keep the door open at one destination floor and close after that to go to another floor.
 
('reset' is just to start the whole system from a known base state which is floor=0 & door=open)

-----------------------------------------------------------------------------
# How to run on board ?
1. Open Vivado and make a new project.
2. Add the design file (*.vhd or *.vhf) and the constraints file (*.xdc)
2. Generate BitStream
3. Open hardware manager and program the device (make sure that the device is connected)
4. Now the device should be ready! :)

NOTE : 
1. For this project, the slide switches on the board have to be used like push buttons.
2. If you have any problem in generating the bitstream then use the *.bit file included in the repo to program the device.
3. For running simulation in vivado, make sure to change the value of 'mode' from '0'(default) to '1' inside the architecture of TOP_LEVEL_ENTITY.

# Possible modifications:
1. Allow to open the door while it is closing
2. Can be optimised further by changing the priority of request handler from lift1 to the lift which is closest to the requesting floor.

THANK YOU :)
