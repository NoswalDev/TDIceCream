{Tracy Allen, EME systems.  (c) 2012 subject to MIT license, see end of listing
18-Jan-2011
Test program for FullDuplexSerial4portPlus
This demo can be set up on a pcb such as the quickstart or demo board.  What have you.
The demo takes two two jumper wires, one to transmit data from one cog to another, and the second to demo flow control

This demo doesn't do anything serious.  The purpose is to show
 -- how to set up multiple serial ports and to verify operation of flow control.
 -- that the fullDuplexSerial object can be shared by multiple objects (dataIO4port), no duplication of code, buffers are shared.
 -- how to stop and restart the object, which is sometimes useful for changing baud rates or configuration in midstream.
 -- use of some of the basic character, string and numeric methods.
 -- how to access the buffer sizes via the data structure.

Wiring summary:
  -- jumper from p11 A_OUTPIN to p8 B_INPIN ascii data
  -- jumper from p10 A_CTS to p6 B_CTS flow control
  -- note that the pin numbers are declared as CONstants in case you need to change them.

The setup:
 -- fullDuplexSerial4port is included as an OBJect.   It will start up another cog with the pasm portion, and its spin methods
    will be available to send data bytes and strings, and to receive bytes either with or without blocking.  The basics.
--  A 2nd object is declared, dataIO4port for numeric I/O.  It is needed only for numeric data output, or for numeric
    or string data input.   Some serial port objects include these methods within the object itself,
    but I prefer for flexibility to split them off into a separate object.
    If you prefer you can merge the methods that you need from dataIO4port back into the main object.
    How to do so is described in the comments with dataIO4port.
 -- The demo initializes ports 0, 2 and 3, as DEBUG, B_PORT and A_PORT respectively, and port 1 is left unused.
 -- A 3rd cog is started, which transmits data asynchronously and rapidly out port A_PORT  via A_OUTPIN
    The flow is controlled however by A_CTSPIN.

  Because of the RTS to CTS connection, B_PORT can ask A_PORT to hold off until space is available in the B_PORT buffer.
  B_PORT receives the data at a leisurely pace and retransmits it at a lower baud rate on the DEBUG port.
  After receiving 30 lines of data, or a break from the user (spacebar), the program asks for a change of baud rate, then
  repeats the process.

To observe and try:
 -- different baud rates slow (remember 300 baud?!) and fast (up to 250kbaud or more).
 -- to observe the action of flow control on a 'scope.
 -- to disable flow control by removing the RTS-CTS wire or by disabling it in the setup.
 -- to connect CTS to ground or Vdd to enable or disable flow manually.
 -- to change the A_port buffer size in fullDuplexSerial4port
 -- different clkmode settings, different clkfreq, affects the maximum baud rate.
}

CON
_clkmode = xtal1 + pll16x
_xinfreq = 5_000_000


  DEBUG = 0                                             ' ports: debug port sends results to terminal
  A_PORT = 2                                            ' this port will send
  B_PORT = 3                                            ' data sent by this port.

  A_TXPIN = 11                                          ' this port pin will transmit data
  B_RXPIN = 8                                           ' this port pin will receive data  --  connect these two pins with a wire

  A_CTSPIN = 10                                         ' this pin will look for flow control on this pin
  B_RTSPIN = 6                                          ' this pin will assert flow control -- connect these two pins with a wire

  B_TXPIN = 7                                           ' data will be transmitted out this pin, for observation only on second terminal or scope

  DEBUG_BAUD = 9600                                     ' baud rates, debug to terminal
  AB_BAUD = 57600                                       ' rate to send data from A_PORT tp B_PORT.

  B_THRESHOLD = FDS#DEFAULTTHRESHOLD                    ' this parameter can be adjusted, usually not necessary

  CR = 13                                               ' new line
  SP = 32                                               ' space



OBJ
  fds :  "FullDuplexSerial4port"
  dio :  "dataIO4port"


VAR

long foxCog, stack[40]                                  ' for the new cog started to transmit data
long loopCount                                          ' to keep track of how many times the uarts have been restarted                         '
long abBaud                                             ' baud rate for communication from A_PORT to B_PORT
long fdsDatPtr                                          ' a pointer to the data structure within fullDuplexSerial4port, for the buffer sizes

byte myBuf[50]                                          ' buffer to store received lines


PUB main | idx, char, flag
  abBaud := AB_BAUD                                     ' start with default baud rate
  repeat                                                ' outer loop starts and restarts the uarts
    start_uarts
    if loopCount++ == 0                                 ' only the first time through the loop
       showBufferSizes                                  ' show the buffer size settings, within fullDuplexSerial4port
       fds.str(DEBUG,string(CR,"press any key"))        ' program waits for user to press a key
       fds.rx(DEBUG)                                    ' blocked here until user does so.
    fds.str(DEBUG,string(CR,CR,"starting... baud rate="))    ' baud rate, for information
    dio.dec(DEBUG,abBaud)                               ' numeric output calls uses method from auxiliary object, dataIO4port
    pause(1000)
    fds.str(DEBUG,string(CR,"press space bar to break...",CR,CR))
    pause(1000)

    foxCog := cognew(sendChicken,@stack) + 1         ' start sending fox data autonomously from its own cog

    fds.rxflush(DEBUG)                                  ' clear out any extraneous key presses from the DEBUG rx buffer
    flag~                                               ' flag to show when the user presses a key
    repeat 15                                           ' receives and displaysup to 15 lines, or until user presses spacebar
      idx~                                              ' zero the buffer pointer
      repeat                                            '
        char := fds.rxCheck(B_PORT)                     ' non-blocking, read input port
        if char > -1                                    ' -1 is no character, otherwise ascii code of character
          fds.tx(B_PORT,char)                           ' send it right back out the B_PORT
          fds.tx(DEBUG,char)                            ' also send it right out the debuf port
          myBuf[idx++] := char                          ' also append it to the string buffer
          if fds.rxcheck(DEBUG) == SP                   ' break out if user presses space at the DEBUG port
            flag~~                                      ' user pressed spacebar
            quit
      until char==CR                                    ' or we received an end of line character
      if flag                                           ' if user pressed spacebar, break out of this level of repeat too
        quit
      myBuf[idx]~                                       ' insert a null at the end of the string buffer, so it can a zstring
      fds.tx(DEBUG,">")
      fds.str(DEBUG,@mybuf)                             ' show the string, should match what was sent in real time.

    if foxCog                                           ' inner loops have finished, stopping transmission from the ansynchronous foxCpg
      cogstop(foxCog-1)
    if fds.rxHowFull(B_PORT)                            ' flush out remaining data, for information, not strictly necessary
      fds.str(DEBUG,string(CR,"discarding "))
      dio.dec(DEBUG,fds.rxHowFull(B_port))              ' Shows how many bytes are in the rx buffer.   May be at RTS threshold.
      fds.str(DEBUG,string(" characters from B receive buffer",CR))
      fds.rxflush(B_PORT)

    fds.str(0,string(CR,"Please enter new AB baud rate: "))   ' Can be any value, not only the standards, up to about 250000
    abBaud := dio.decIn(DEBUG)                          ' uses decimal input method to get the new baud rate.
    if abBaud == 0
      abBaud := AB_BAUD                                 ' user pressed CR only or entered zero.  use default.                                    '
    fds.str(0,string(CR,"restarting ports...",CR))      ' back to top repeat


PUB sendChicken  | ticks  ' this method gets its own cog, sends out same string repeatedly but with flow constrol enabled.
  ticks~
  repeat
    pause(20)  '
    fds.str(A_PORT,@chicken)
    dio.dec(A_PORT, ++ticks)
    fds.str(A_PORT,string(" times?",13))

PUB start_uarts
'' port 0-3 port index of which serial port
'' rx/tx/cts/rtspin pin number                          #PINNOTUSED = -1  if not used
'' prop debug port rx on p31, tx on p30
'' cts is prop input associated with tx output flow control
'' rts is prop output associated with rx input flow control
'' rtsthreshold - buffer threshold before rts is used   #DEFAULTTHRSHOLD = 0 means use default=buffer 3/4 full
''                                                      note rtsthreshold has no effect unless RTS pin is enabled
'' mode bit 0 = invert rx                               #INVERTRX  bit mask
'' mode bit 1 = invert tx                               #INVERTTX  bit mask
'' mode bit 2 = open-drain/source tx                    #OCTX   bit mask
'' mode bit 3 = ignore tx echo on rx                    #NOECHO   bit mask
'' mode bit 4 = invert cts                              #INVERTCTS   bit mask
'' mode bit 5 = invert rts                              #INVERTRTS   bit mask
'' baudrate                                             desired baud rate, e.g. 9600

  if foxCog                                             ' stopping transmission from the ansynchronous foxCpg
    cogstop(foxCog-1)
  pause(100)

  fdsDatPtr := fds.init                                 ' clears the buffers and pointers, returns a pointer to the internal fds data structure

  fds.AddPort(A_PORT, -1, A_TXPIN, A_CTSPIN,-1, 0, %000000, abBaud)
                                                        ' tx but no rx,
                                                        ' cts is enabled, tx will wait if cts is high
  fds.AddPort(B_PORT, B_RXPIN, B_TXPIN, fds#PINNOTUSED, B_RTSPIN, B_THRESHOLD, fds#NOMODE, abBaud)
                                                        ' RTS will go high if #chars in rx buffer exceeds threshold.
  fds.AddPort(DEBUG,31,30,-1,-1,0,%000000,DEBUG_BAUD)   ' debug to the terminal screen

' port 1 is not used.   The order that you define ports does not matter.  You don't have to do anything to set up unused ports

  fds.Start                                             ' now actually start the ports
  pause(100)                                            '


PUB ShowBufferSizes | idx
  ' the following shows that it is possible to read the internal data structure of the fds object.
  ' the fds.init routine returned a pointer to the first long in the data structure, which happens to be the size
  ' of the port 0 receive buffer.   After that come the sizes of 7 more buffers.
  ' See the fullDuplexSerial4port listing to find the offsets of other variables that might be useful
  ' in advanced applications.
  fds.str(DEBUG,string(13,"receive buffer sizes:",13))
  repeat idx from 0 to 3
    dio.dec(DEBUG,idx)
    fds.tx(DEBUG,32)
    dio.dec(DEBUG,long[fdsDatPtr][idx])
    fds.tx(DEBUG,CR)
 fds.str(DEBUG,string("transmit buffer sizes:",13))
  repeat idx from 4 to 7
    dio.dec(DEBUG,idx//4)
    fds.tx(DEBUG,32)
    dio.dec(DEBUG,long[fdsDatPtr][idx])
    fds.tx(DEBUG,13)



PRI pause(ms)
  waitcnt(clkfreq/1000*ms + cnt)

DAT
  chicken byte "Wy did the chicken cross the road ",0

{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}

