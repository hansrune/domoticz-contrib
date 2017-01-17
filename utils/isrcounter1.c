/*
 * isr-osc.c:
 *	Wait for Interrupt test program - ISR method - interrupt oscillator
 *
 *	How to test:
 *
 *	IMPORTANT: To run this test we connect 2 GPIO pins together, but
 *	before we do that YOU must make sure that they are both setup
 *	the right way. If they are set to outputs and one is high and one low,
 *	then you connect the wire, you'll create a short and that won't be good.
 *
 *	Before making the connection, type:
 *		gpio mode 0 output
 *		gpio write 0 0
 *		gpio mode 1 input
 *	then you can connect them together.
 *
 *	Run the program, then:
 *		gpio write 0 1
 *		gpio write 0 0
 *
 *	at which point it will trigger an interrupt and the program will
 *	then do the up/down toggling for itself and run at full speed, and
 *	it will report the number of interrupts recieved every second.
 *
 *	Copyright (c) 2013 Gordon Henderson. projects@drogon.net
 ***********************************************************************
 * This file is part of wiringPi:
 *	https://projects.drogon.net/raspberry-pi/wiringpi/
 *
 *    wiringPi is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU Lesser General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    wiringPi is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU Lesser General Public License for more details.
 *
 *    You should have received a copy of the GNU Lesser General Public License
 *    along with wiringPi.  If not, see <http://www.gnu.org/licenses/>.
 ***********************************************************************
 */

#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <wiringPi.h>



// What GPIO input are we using?
//	This is a wiringPi pin number

#define	OUT_PIN		0
#define	IN_PIN		1

// globalCounter:
//	Global variable to count interrupts
//	Should be declared volatile to make sure the compiler doesn't cache it.

static volatile unsigned long globalCounter = 0 ;

/*
 * myInterrupt:
 *********************************************************************************
 */

void myInterrupt (void)
{
  ++globalCounter ;
  // digitalWrite (OUT_PIN, globalCounter & 0x1 ) ;
}

int  updateFile ( char *filename, unsigned long count )
{
  char buf[32];
  int fd;
  if ((fd = open (filename, O_RDWR | O_CREAT)) < 0)
  {
    fprintf (stderr, "Unable to update file %s: %s\n", filename, strerror (errno)) ;
    return 1 ;
  }
  sprintf(buf, "%lu", count);
  write (fd, buf, strlen(buf)) ;
  return close (fd) ;
}

unsigned long readFile ( char *filename )
{
  char buf[32];
  int fd;
  if ((fd = open (filename, O_RDWR )) < 0)
  {
    fprintf (stderr, "Unable to read file %s: %s\n", filename, strerror (errno)) ;
    return 0 ;
  }
  read(fd, buf, sizeof(buf));
  close (fd) ;
  return atol(buf);
}

/*
 *********************************************************************************
 * main
 *********************************************************************************
 */

int main (int argc, char *argv[])
{
  unsigned long myCounter   = 0 ;
  unsigned long lastCounter = 0 ;

//  fprintf (stderr, "argc=%d\n" , argc);
  if (argc != 2)
  {
    fprintf (stderr, "Usage: %s filename\n", argv[0]);
    return 1 ;
  }

  if (wiringPiSetup () < 0)
  {
    fprintf (stderr, "Unable to setup wiringPi: %s\n", strerror (errno)) ;
    return 1 ;
  }
 
  globalCounter = readFile(argv[1]);

  pinMode (OUT_PIN, OUTPUT) ;
  pinMode (IN_PIN,  INPUT) ;
  pullUpDnControl(IN_PIN,  PUD_UP) ;

  if (wiringPiISR (IN_PIN, INT_EDGE_FALLING, &myInterrupt) < 0)
  {
    fprintf (stderr, "Unable to setup ISR: %s\n", strerror (errno)) ;
    return 1 ;
  }

  if (updateFile(argv[1], 0) != 0 )
  {
    return 1 ;
  }

  for (;;)
  {
    printf ("Waiting ... ") ; fflush (stdout) ;

    while (myCounter == globalCounter)
      delay (100) ;

    if ( lastCounter != 0 ) {
        printf (" Done. counter: %lu: %lu\n",
		globalCounter, myCounter - lastCounter) ;
    }
    lastCounter = myCounter ;
    myCounter   = globalCounter ;
    if ( lastCounter != 0 ) {
        updateFile(argv[1], myCounter);
    }
    digitalWrite (OUT_PIN, globalCounter & 0x1 ) ;
  }

  return 0 ;
}
