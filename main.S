/*
 * main.S - ECE 540 project
 *
 * Created By:		Deepen Parmar (parmar@pdx.edu)
 * Last Modified:	20-Jan-2020
 *
 * Description:
 * Reads the pushbutton values on the FPGA board and writes them to the seven-segment display to display
 * the different motion of the virtual bot by blinking the led to show the motion in the different way
 *
 * Assumes the existance of an AHB-Lite peripheral for the 8 digit
 * 7-segment display on the Nexys4 DDR.  The peripheral has 4 memory
 * mapped I/O registers:
 *	PORT_SEVENSEG_EN - (8 bits) Individual enables for each digit. Set bit to 0 to enable digit
 *									Digit7 = bit[7], Digit6 = bit[6], Digit5 = bit[5], Digit4 = bit[4],
 *									Digit3 = bit[3], Digit2 = bit[2], Digit1 = bit[1], Digit0 = bit[0]
 *	PORT_SEVENSEG_HGH = (32 bits) Value of digit.  Each digit has the range of 31:0, top 3 bits ignored
 *									Digit7 = bits[31:24], Digit6 = bits[23:16],
 *									Digit5 = bits[15:8] , Digit4 = bits[7:0]
 *	PORT_SEVENSEG_LOW = (32 bits) Value of digit.  Each digit has the range of 31:0, top 3 bits ignored
 *									Digit3 = bits[31:24], Digit2 = bits[23:16],
 *									Digit1 = bits[15:8] , Digit0 = bits[7:0]
 *	PORT_SEVENSEG_DP - (8 bits) Individual decimal points for each digit. Set bit to 0 to turn on the decimal point
 *									DP7 = bit[7], DP6 = bit[6], DP5 = bit[5], DP4 = bit[4],
 *									DP3 = bit[3], DP2 = bit[2], DP1 = bit[1], DP0 = bit[0]
 */

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//Defining the label fot the different parts of the seven-segment display
//which specifies the different virtual address of the upper segment, lower
//segment, decimal point and the enable point.
//
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
PORT_SEVENSEG_EN 	= 0xbf700000		# (o) 7 Segment enable
PORT_SEVENSEG_HGH	= 0xbf700004		# (o) 7 Segment Higher Display
PORT_SEVENSEG_LOW	= 0xbf700008		# (o) 7 Segment Lower Display
PORT_SEVENSEG_DP	= 0xbf70000C		# (o) 7 segment Decimal Point Display


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//passing the virual address to the specific register od the MIPSfppga which can be
//used at the different position in the code to maintain the redability and to generalise
//the code
//
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
.globl main
main:

   lui   $12, 0xbf80    				# $12 = address of LEDs (0xbf800000)
   addiu $13, $12, 4    				# $13 = address of switches
   addiu $18, $12, 8                    # $18 = address of Push Buttons
   li    $14, PORT_SEVENSEG_EN			# $14 = address of the 7 segment enable
   li 	 $15, PORT_SEVENSEG_HGH			# $15 = address of the higher 7 segment digits
   li 	 $16, PORT_SEVENSEG_LOW			# $16 = address of the lower 7 segment digits
   li 	 $17, PORT_SEVENSEG_DP			# $17 = address of the dp points in 7 segment digits
   li 	 $5, 0

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//Defining the reset condition of the robot. Which states what happens when reset
//button is asserted
//
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
readIO:
    li 	  $11, 0xf0			# $11 = 0xf0 (loading 0xf0 in the register)
	sw	  $11, 0($14)		# Enable the lower segment display
	li 	  $11, 0xF7			# Turn on the specific  decimal point
	sw	  $11, 0($17)		# write the value store in the $11 register to the decimal point display
	li    $23,0x16000000	# load the specific value to enable segment A in the register
	sw    $23, 0($16)	    # write pushbutton values to lower 7 segment digits

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//This code define the idle condition. Which states that what robot do when none of the button is pressed
//thus this code is executed when none of the switch case statement is not executed
//
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	idle:

    and  $5,$5,0x00ffffff	# perform the and operation between the data in the $5 and the 0x00FFFFFF and store value in $5
	or	 $5,$5,0x16000000	# perform the or operation between the data in the $5 and the 0x16000000 and store value in $5
	sw   $5, 0($16)	    	# write pushbutton values to lower 7 segment digits
	lw	 $20, 0($18)		# read push buttons: $20 = push button values
    li   $21,360			# load immediate 360 into $21
    li   $22,0				# load immedate 0 into $22
    li   $9,0				# load immediate 0 into $9

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
// Branch instruction to know which button is pressed
//
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
L13:
	beq    $20,0x10,Left 	    # if pushbutton input is 0x10 turn left 1x speed
	beq    $20,0x04,Right       # if pushbutton input is 0x04 turn right 1x speed
	beq    $20,0x08,Right	    # if pushbutton input is 0x08 turn right 1x speed
	beq    $20,0x0c,Right2x     # if pushbutton input is 0x0C turn right 2x speed
	beq    $20,0x01,Left        # if pushbutton input is 0x01 turn left 1x speed
	beq    $20,0x05,Forward     # if pushbutton input is 0x05 go forward
	beq    $20,0x11,Left2x      # if pushbutton input is 0x11 turn left 2x speed
	beq    $20,0x18,Reverse     # if pushbutton input is 0x18 go reverse
			j      idle         # if none of the switch case is pressed go to the idle state

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  This part of the code implements the logic to display the right turn with the 1x speed
//  This condition will take place 2 times when left motor is forward and right motor is stop
//  and when left motor is stop and right motor is forward
//	This two condition takes place when only left pushbutton is pressed and when only down pushbutton is pressed
//	Hence in this the segments will be on in the clock wise direction
//
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    Right:   li $23,0x10000000         # load immediate the value into the $23 to activate segment 'A'
		  sw $23,0($16)				# write pushbutton values to lower 7 segment digits

		 	jal increment			# function call to increment the compass value
		    jal display_compass		# function call to display value on compass
		    jal delay1x				# function call to gnereate 1x delay
		    jal read				# funcation call to read value from the push button

		  li $23,0x11000000			# load immediate the value into the $23 to activate segment 'B'
		  sw $23,0($16)				# write pushbutton values to lower 7 segment digits

		    jal increment			# function call to increment the compass value
		    jal display_compass		# function call to display value on compass
		    jal delay1x
		    jal read

		li $23,0x12000000	    	# load immediate the value into the $23 to activate segment 'C'
		  sw $23,0($16)				# write pushbutton values to lower 7 segment digits

			jal increment			# function call to increment the compass value
			jal display_compass		# function call to display value on compass
		 	jal delay1x
			jal read

		li $23,0x13000000			# load immediate the value into the $23 to activate segment 'D'
		  sw $23,0($16)				# write pushbutton values to lower 7 segment digits

			jal increment			# function call to increment the compass value
		    jal display_compass		# function call to display value on compass
			jal delay1x
			jal read

		li $23,0x14000000			# load immediate the value into the $23 to activate segment 'E'
		  sw $23,0($16)				# write pushbutton values to lower 7 segment digits

		    jal increment			# function call to increment the compass value
		    jal display_compass		# function call to display value on compass
			jal delay1x
			jal read

		li $23,0x15000000			# load immediate the value into the $23 to activate segment 'F'
		  sw $23,0($16)				# write pushbutton values to lower 7 segment digits

			jal increment			# function call to increment the compass value
			jal display_compass		# function call to display value on compass
			jal delay1x
			jal read

		     j idle					# unconditional jump to the idle state

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
// This part of the code implements the logic to display the left turn with the 1x speed
// this condition will take place 2 times when the left motor is stop and the right motor is forward
// and when the left motor is reverse and the right motos is stop
// This two condition will take place when only right push button is pressed and only up pushbutton is pressed
// Hence in this the segment will be on in the anti clock wise direction
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Left:	      li $23,0x10000000			# load immediate the value into the $23 to activate segment 'A'
		  sw $23,0($16)

			jal decrement
			jal display_compass
			jal  delay1x
			jal read

		  li $23,0x15000000			# load immediate the value into the $23 to activate segment 'F'
		  sw $23,0($16)

			jal decrement
			jal display_compass
			jal  delay1x
			jal read

		  li $23,0x14000000			# load immediate the value into the $23 to activate segment 'E'
		  sw $23,0($16)

			jal decrement
			jal display_compass
			jal  delay1x
			jal read

		  li $23,0x13000000			# load immediate the value into the $23 to activate segment 'D'
		  sw $23,0($16)

			jal decrement
			jal display_compass
			jal  delay1x
			jal read

		  li $23,0x12000000			# load immediate the value into the $23 to activate segment 'C'
		  sw $23,0($16)

			jal decrement
			jal display_compass
			jal delay1x
			jal read

		  li $23,0x11000000			# load immediate the value into the $23 to activate segment 'B'
		  sw $23,0($16)

			jal decrement
			jal display_compass
		  	jal  delay1x
		  	jal read

		  	j idle

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  This part of the code implements the logic to display the right turn with the 2x speed
//  This condition will take place 1 time when left motor is forward and right motor is reverse
//  This condition will take place when left push button and down push button are pressed simultaneously
//  Hence in this the segments will be on in the clock wise direction. The only difference in
//  this and the right turn 1x code is of the delay
//
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



 Right2x:  	li $23,0x10000000
		  	sw $23,0($16)

			 jal increment
			 jal display_compass
			 jal delay2x			# function call to call the delay to generate 2x speed
			 jal read

		    li $23,0x11000000
		    sw $23,0($16)

			 jal increment
			 jal display_compass
			 jal  delay2x			# function call to call the delay to generate 2x speed
			 jal read

		    li $23,0x12000000
		    sw $23,0($16)

			 jal increment
		     jal display_compass
			 jal delay2x			# function call to call the delay to generate 2x speed
			 jal read

		    li $23,0x13000000
		    sw $23,0($16)

			 jal increment
			 jal display_compass
			 jal delay2x			# function call to call the delay to generate 2x speed
			 jal read

		    li $23,0x14000000
		    sw $23,0($16)

		     jal increment
			 jal display_compass
		     jal  delay2x			# function call to call the delay to generate 2x speed
			 jal read

		    li $23,0x15000000
		    sw $23,0($16)

             jal increment
 			 jal display_compass
		     jal  delay2x			# function call to call the delay to generate 2x speed
		     jal read

		     j idle

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
// This part of the code implements the logic of the forward state.
// this condition will take place when both the left and the right motor is forward
// this conditon takes place when left and right poushbutton are pressed simulataneously
//
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


 Forward:li $23,0x10000000

		 and   $5,$5,0x00ffffff     # perform the and operation between the data in the $5 and the 0x00FFFFFF and store value in $5
		 or	   $5,$5,$23            # perform the and operation between the data in the $5 and the 0x00FFFFFF and store value in $5
		 sw    $5, 0($16)	        # write pushbutton values to lower 7 segment digits

		 jal delayblink				# function call to generate delay

         li   $23,0x1c000000		# load the specific value in the $23 to display 'A' segment
         and  $5,$5,0x00ffffff		# perform the and operation between the data in the $5 and the 0x00FFFFFF and store value in $5
         or	  $5,$5,$23				# perform the and operation between the data in the $5 and the 0x00FFFFFF and store value in $5
		 sw   $5, 0($16)	        # write pushbutton values to lower 7 segment digits

		 jal delayblink				# function call to generate delay
	     jal display_compass		# funcation call to display compass value
		 jal read					# function call to read pushbutton
		 j idle						# to idle

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
// This part of the code implements the logic of the reverse state.
// this condition will take place when both the left and the right motor is reverse
// this conditon takes place when up and down poushbutton are pressed simulataneously
//
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


Reverse:   li $23,0x13000000

	       and   $5,$5,0x00ffffff   # perform the and operation between the data in the $5 and the 0x00FFFFFF and store value in $5
		   or	 $5,$5,$23			# perform the and operation between the data in the $5 and the 0x00FFFFFF and store value in $5
		   sw   $5, 0($16)	        # write pushbutton values to lower 7 segment digits

           jal delayblink			# function call to generate delay

		   li    $23,0x1c000000		# load the specific value in the $23 to display 'D' segment
           and   $5,$5,0x00ffffff	# perform the and operation between the data in the $5 and the 0x00FFFFFF and store value in $5
           or	$5,$5,$23			# perform the and operation between the data in the $5 and the 0x00FFFFFF and store value in $5
           sw    $5, 0($16)	        # write pushbutton values to lower 7 segment digits

           jal delayblink			# function call to generate delay
           jal display_compass		# funcation call to display compass value
		   jal read					# function call to read pushbutton
		   j idle

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  This part of the code implements the logic to display the left turn with the 2x speed
//  This condition will take place 1 time when left motor is reverse and right motor is forward
//  This condition will take place when right push button and up push button are pressed simultaneously
//  Hence in this the segments will be on in the anti-clock wise direction. The only difference in
//  this and the left turn 1x code is of the delay
//
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Left2x:	  li $23,0x10000000
		  sw $23,0($16)

		  	jal decrement
		    jal display_compass
			jal delay2x				# function call to call the delay to generate 2x speed
			jal read

		  li $23,0x15000000
		  sw $23,0($16)

		  	jal decrement
		    jal display_compass
			jal delay2x				# function call to call the delay to generate 2x speed
			jal read

		  li $23,0x14000000
		  sw $23,0($16)

		  	jal decrement
		    jal display_compass
			jal  delay2x			# function call to call the delay to generate 2x speed
			jal read

		  li $23,0x13000000
		  sw $23,0($16)

		  	jal decrement
		    jal display_compass
			jal  delay2x			# function call to call the delay to generate 2x speed
			jal read

		  li $23,0x12000000
		  sw $23,0($16)

		    jal decrement
		    jal display_compass
			jal delay2x				# function call to call the delay to generate 2x speed
			jal read

		  li $23,0x11000000
		  sw $23,0($16)

			jal decrement
		    jal display_compass
		    jal  delay2x			# function call to call the delay to generate 2x speed
		    jal read

		    j idle

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
// This function is used to generate delay for the 1x speed
//
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

 	  delay1x:  li $10, 0x00100000    # loading the specific value to generate the delay
	      DL1:  addi $10,$10,-1	      # subtracting the value loaded intitially by 1
                bne $10, $0, DL1	  # monitoring the value of the $10 untill it is 0
                jal $ra			      # jump to the location specified in the $ra

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
// This function is used to generate delay for the 2x speed
//
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////



      delay2x:  	li $10,0x00090000     # loading the specific value to generate the delay
          DL2:  	addi $10,$10,-1		  # subtracting the value loaded intitially by 1
              		bne $10, $0, DL2	  # subtracting the value loaded intitially by 1
              		jal $ra				  # jump to the location specified in the $ra

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
// This function is used to generate delay for the blinking of the seven-segment when in the forward
// and the reverse state
//
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////



	delayblink:  	li $10, 0x00900000	# loading the specific value to generate the delay
		   DL3:   	addi $10,$10,-1		# subtracting the value loaded intitially by 1
                  	bne $10, $0, DL3    # subtracting the value loaded intitially by 1
          		  	jal $ra				# jump to the location specified in the $ra

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// This function is used tyo monitor the pushbutton to see if the value is changing or not
// if the value changes it will go to the switch case statement to know which button is pressed
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////



          read: 	lw	  $20, 0($18)		# read push buttons: $20 = push button values
		  			beq     $20,0x00,idle   # if the valur in th $20 is equal to the 0 junp to idle state
		  			jal     $ra				# else jump to the specific location
		  			nop


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//												Compass Implementation
//
// In this part of the code there are total three fuunction which are increment, decrement and the
//	function to display the compass value on the seven segment display
//
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//												Increment Counter
// In this function the value of the counter is incremented each and every time the different sevensegment
// is displayed. This function will only be called when the robot is taking right turn at 1x and 2x speed
//
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


    	      null: li   $7,0000					# loading 0 into $7
		 increment: addi $7, $7, 1					# incrementing the value of $7
                    beq	 $7,$21,overflow_detected	# comparing the value of $7 with $21 (359) if equal will jump to specific location
                    j skip_overflow_detected
overflow_detected:  li   $7,0000
skip_overflow_detected:
						j $ra
				         nop


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//												Decrement Counter
// In this function the value of the counter is incremented each and every time the different sevensegment
// is displayed. This function will only be called when the robot is taking right turn
//
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


			dull: li  	 $7,0000								# loading 0 into $7
		 decrement: 	 addi $7, $7, -1						# decrementing the value of $7
                    	 beq	 $7,-1,underflow_detected		# comparing the value of $7 with $21 (359) if equal will jump to specific location
                  		 j skip_underflow_detected

 underflow_detected:  		li   $7,359
skip_underflow_detected:
 							j $ra
		             		nop

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//												Display Compass Value
// This function provides the logic to display compass logic properly on the lower three digits
// of the seven segment display
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		display_compass: move  $22,$7					# move the counter value in to $22
	    	         	 li $8,3						# load value three in $8
    			display: addi $8,$8,-1					# decrement the value of the $8
						 divu $22,10					# divide the value to get the single digit number
              			 mfhi $4						# remainder of the division store in $4
              			 mflo $22						# quotient of the division sotore in $22
              			 sll  $4,$4,24					# left shift the value in $4 by 24 bit
              			 or $9,$9,$4					# or the value of $4 and the $9 result store in $9
              			 srl $9,$9,8					# right shift the value of the $9 by 8 bits
 			  			 bne $8,$0, display				# if the value of the $8 not equal to 0 branch
			  			 or  $23,$9,$23					# or the content of the $23 and the $9
			 			 sw $23,0($16)					# display thr value on the segment
			             move $5,$23					# move the value to $5
				         j $ra							# unconditional jump
				         nop

						 beq   $0, $0, readIO 	        # repeat
						 nop                  	# branch delay slot


////////////////////////////////////////////////////////FINISH/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////












