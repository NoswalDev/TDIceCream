CON

        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000


con ' pinout
'ken tarlow board


COM0_IN  = 31
COM0_OUT = 30
' 29 to 19 are not fanned out in the prop mini, but can be addressed if needed
' 28-29 is the eeprom if we need to save settings
GARMIN_SDA = 18 ' 6 pin connector on the corner, used for SDA or for the big stepper
GARMIN_SCL = 17 ' 6 pin connector on the corner, used for SDA or for the big stepper 
GARMIN_PWM = 16 ' 6 pin connector on the corner, used for SDA or for the big stepper 
COM3_IN  = 15 ' audioserial
COM3_OUT = 14 ' opamp out
COM2_IN = 13  ' st3232
COM2_OUT = 12 ' st3232
COM1_IN = 11  ' st3232
COM1_OUT = 10 ' st3232
SENS3 = 9 ' sensors (PINGs etc) are powered by the linear 5V regulator
SENS2 = 8
SENS1 = 7
SENS0 = 6
SERVO3 = 5 ' servos are powered by the big switching regulator which should be operated at 6 to 7 volts
SERVO2 = 4
SERVO1 = 3
SERVO0 = 2
USB1 = 1 ' usb data pin not connected, will only connect if we need it. USB charge will work normally.
USB0 = 0 ' usb data pin not connected, will only connect if we need it. USB charge will work normally.       


VAR
long tempvar

byte commandstring[260]
byte commandptr

byte programtorun

OBJ 'objects (libraries). they are included in the folder with the main program
  com : "pcFullDuplexSerial4FC128" ' runs 4 "slow" (56k or less) serial ports on one core
  servo: "Servo32v9" ' generates servo pulses
  math: "DynamicMathLibPlusStrings" ' allows using floating point math & output formatting

con
OUTPORT = 1  ' port that outputs to the 1 inch controllers
INPORT = 3  ' port that inputs from the raspberry pi or android tablet
ALWAYS_WAIT = false ' true or false: always wait for spacebar press on the terminal or input port to do the next step (for safety)
WAIT_ON_INPORT = false ' if true: wait from input port (two asterisks). if false: wait from debug port (spacebar)
NEVER_WAIT = false ' true or false: disable the "waitkey" command. THIS OVERRIDES THE TWO ABOVE SETTINGS!
SERVO_TICK = SERVO3 ' if it's a servo, "tick" when waiting seconds. if it's 0 or -1, don't.
pub init ' this 
                             
  com.AddPort(0,COM0_IN,COM0_OUT,-1,-1,0,%000000,19200) ' THIS IS THE DEBUG PORT initializes serial port parameters. the last number is baudrate 
  com.AddPort(1,COM1_IN,COM1_OUT,-1,-1,0,%000000,19200) ' THIS IS THE 1ST UART PORT initializes serial port parameters. the last number is baudrate 
  com.AddPort(2,COM2_IN,COM2_OUT,-1,-1,0,%000000,19200) ' THIS IS THE 2ND UART PORT initializes serial port parameters. the last number is baudrate 
  com.AddPort(3,COM3_IN,COM3_OUT,-1,-1,0,%000000,04800) ' This is the port that has audio input and TTL output initializes serial port parameters. the last number is baudrate 
  com.Start ' actually starts the serial ports. this uses 1 core
  
  servo.Set(SERVO3,1500) ' standard servo pulse in microseconds (1000 to 2000)
  servo.Set(SERVO2,1500) ' standard servo pulse in microseconds (1000 to 2000)
  servo.Set(SERVO1,1500) ' standard servo pulse in microseconds (1000 to 2000)
  servo.Set(SERVO0,1500) ' standard servo pulse in microseconds (1000 to 2000). use this instruction to send a servo somewhere
  servo.Start ' actually starts the servo pulse generator. this uses 1 core

  math.allowfast ' starts dynamic math core allocation; you only need this once. uses 0 or 1 cores
                                                        
  ' the main program (this one) uses 1 core, so right now we have 3-4 in use, and the rest free
  
  tempvar := 1000 ' note that in Spin, you use := and not = to set a variable 

  waitcnt(cnt+clkfreq)
  waitcnt(cnt+clkfreq)
  sad:=serial_adjust_delay

  if (NEVER_WAIT==false)
    if (WAIT_ON_INPORT)
      send(0, string("Press the PROCEED button on the app to begin"))
    else
      send(0, string("Press spacebar on the terminal to begin"))
  waitkey
  send(0, string("Entering command loop"))
  if (ALWAYS_WAIT==true)
      send(0, string("Manual confirmation (spacebar/proceed) required after each step"))
      
  repeat
    programtorun:=-1
    ParseCommand
    if (valid)
        send(0,string("****starting new cycle****"))
        wait(100)
      case programtorun ' if we need more than 9, tell me and i will refactor this :) mkb
        0: program0
        1: program1
        2: program2
        3: program3
        4: program4
        5: program5
        6: program6
        7: program7
        8: program8
        9: program9

      if (WAIT_ON_INPORT)
        send(0,string("****cycle complete, press PROCEED to resume"))
      else
        send(0,string("****cycle complete, press space to resume"))

      waitkey
      FlushCommand ' clear the command buffer
    idletask
        
pri valid
    return (programtorun =< 9 and programtorun => 0)    

pri FlushCommand
                      bytefill(@commandstring,0,256)
                      commandptr~
pri ParseCommand  

     ' read input from the audio jack: do idletask if nothing is coming in
  
    result:=com.rxtime(INPORT,50)
    if (result>0 and result<128)
        commandstring[commandptr++]:=result & $FF
        com.tx(0,result)
        if (commandptr>250)
          commandptr~
        
     ' scan the command line we just got (or not)
    result~~    
    repeat 256
          result++
          if (true)'commandstring[result+1]=="@")
             if (commandstring[result+2]=="r")
               if (commandstring[result+3]=="u")
                 if (commandstring[result+4]=="n")
                   if (commandstring[result+7] => "0" and commandstring[result+7] =< "9" and commandstring[result+5]==commandstring[result+6] and commandstring[result+5]==commandstring[result+7] and commandstring[result+5]==commandstring[result+8])
                      programtorun:=commandstring[result+6]-"0"
                      com.str(0,string(13,10,"Valid command: "))
                      com.str(0,@commandstring)
                      bytefill(@commandstring,0,256)
                      commandptr~
                      result~


pub idletask

    ' com.tx(0,"x")


pub program0
pub program1
     wait(300)                   
     cmd(string("@@!!")) ' flush buffer
     wait(300)                   ' wait 0.2 seconds
     cmd(string("@@BB>1000")) ' carousel spin left
     wait(5000)                   ' wait 0.2 seconds
     cmd(string("@@BB<1000")) ' carousel spin right
     wait(3000)                  ' wait 2 seconds                                                                          
     cmd(string("@@AD%1"))    ' engage clutch on lift stepp
     wait(2000)                                                                                                          
     cmd(string("@@AD<2400")) ' bring lift stepper up
     wait(5000)
     cmd(string("@@AB]1500")) ' open front door
     wait(10000)
     cmd(string("@@AB[1500")) ' close door
     wait(1000)
     cmd(string("@@A")) ' disengage clutch (remove after testing) @@AD%0
     wait(3000)                   ' wait 0.2 seconds

pub program2

     cmd(string("@@ZZ!250"))  ' turn toppings knob
     wait(1000)
     cmd(string("@@ZZ!1"))    ' turn knob back 
     wait(2000)
     cmd(string("@@AC>4100")) ' bring center arm to cup
     wait(5000)
     cmd(string("@@ZZ(200")) ' drop toppings
     wait(2000)
     cmd(string("@@AC<4200")) ' bring toppings arm back to start position
     wait(5000)


pub program3

     cmd(string("@@AA[2000")) ' bring liquid arm up
     wait(3500)

     cmd(string("@@PP")) ' dispense liquid topping  (ADD LIQUID AMOUNT)
     wait(5000)

     cmd(string("@@AA]2400")) ' bring liquid arm up
     wait(3000)

     repeat 10
       cmd(string("@@AA}200")) ' bring liquid arm up
       wait(400)
pub program4
     
     cmd(string("@@AB]1500")) ' open front door
     wait(5000)
     cmd(string("@@AB[1500")) ' close door
     wait(3000)
     cmd(string("@@AD%0")) ' drop lift arm

pub program5

      cmd(string("@@AA]1000")) ' liquid arm up
      wait(1500)
      cmd(string("@@AA}5000")) ' liquid arm up
pub program6

      cmd(string("@@ZZ!1")) ' toppings servo to 0

pub program7

      cmd(string("@@AD%0")) 'unlock clutch
pub program8

      cmd(string("@@AB]200")) ' Sping cup door
    
pub program9

pri waitkey ' for adjusting timing: waits for a key press in the terminal
        if (NEVER_WAIT)
          return
        if (WAIT_ON_INPORT)
          com.rxflush(INPORT)
          repeat until (com.rx(INPORT)=="*")
          repeat until (com.rx(INPORT)=="*")
          com.str(0,string("OK",13))
          com.rxflush(INPORT)
        else
          com.rxflush(0)
          repeat until (com.rx(0)==" ")
          com.str(0,string("OK",13))
          com.rxflush(0)
        
pri wait(howmany) ' this is in milliseconds. causes the main program to wait, but the other stuff runs in the background.
    com.str(0,string("-Wait"))
    com.dec(0,howmany)
    com.tx(0,13)
    
    if (howmany==0)
        waitkey
        return

    if (ALWAYS_WAIT == true)
        waitkey
    
    if (howmany>999)
      repeat
         if (SERVO_TICK > 0 and SERVO_TICK < 32)
            servo.Set(SERVO_TICK,1800)
         waitcnt(cnt+(clkfreq/2))
         howmany:=howmany - 1000
         if (SERVO_TICK > 0 and SERVO_TICK < 32)
            servo.Set(SERVO_TICK,1300)
         waitcnt(cnt+(clkfreq/2))
      while (howmany>999)

    if (SERVO_TICK > 0 and SERVO_TICK < 32)
            servo.Set(SERVO_TICK,1500)

    if (howmany>1)
      waitcnt(cnt + ((clkfreq/100)*howmany)/10)

pri cmd_motorfix(tosend)
    sad-=150
    com.str(0,tosend) ' string send (and possible tx flush)
    send_sync(OUTPORT,tosend) ' string send (and possible tx flush)
    com.tx(0,13)            ' add a carriage return
    sad+=150

pri cmd(tosend)
    com.str(0,tosend) ' string send (and possible tx flush)
    send_sync(OUTPORT,tosend) ' string send (and possible tx flush)
    com.tx(0,13)            ' add a carriage return
    
pri send(port, stringtosend) ' sends a string out to the serial port 
    com.str(port,stringtosend) ' string send (and possible tx flush)
    com.tx(port,13)            ' add a carriage return
pri send_debug(port, stringtosend) ' sends a string out to the serial port 
    com.str(0,stringtosend) ' string send (and possible tx flush)
    com.tx(0,13)            ' add a carriage return
    if (port>0)
       send_sync(port,stringtosend) ' string send (and possible tx flush)
con serial_adjust_delay = 840
var
long sad
pri send_sync(port, strAddr) ' sends a string out to the serial port 
    com.txflush(port)
    repeat strsize(strAddr)                             ' for each character in string
      com.tx(port,byte[strAddr++])                               '   write the character
      com.txflush(port)
      waitcnt(cnt + ((clkfreq/sad)))
      
    com.tx(port,13)            ' add a carriage return
    com.txflush(port)
    waitcnt(cnt + ((clkfreq/sad)))
