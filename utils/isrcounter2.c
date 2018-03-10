/*
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

#include <time.h>
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

static volatile unsigned long isrCounter = 0 ;

/*
 * myInterrupt:
 *********************************************************************************
 */

void myInterrupt (void) {
    ++isrCounter ;
}

int  updateFile ( char *filename, char *buf )
{
    int fd;
    if ((fd = open (filename, O_TRUNC | O_WRONLY)) < 0) {
        fprintf (stderr, "Unable to update file %s: %s\n", filename, strerror (errno)) ;
        return 1 ;
    }
    write (fd, buf, strlen(buf)) ;
    return close (fd) ;
}

unsigned long readFile ( char *filename ) {
    char buf[32];
    int fd;
    if ((fd = open (filename, O_RDWR )) < 0) {
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

int main (int argc, char *argv[]) {
    unsigned long myCounter   = 0 ;
    unsigned long lastCounter = 0 ;
    unsigned long lastRateCount = 0 ;
    unsigned long intervalTime = 60 ;
    unsigned long rate;
    char buf[32];

    time_t lastTime, currTime;

    if (argc < 2 && argc > 4) {
        fprintf (stderr, "Usage: %s countfile [ratefile interval]\n", argv[0]);
        return 1 ;
    }

    if (wiringPiSetup () < 0) {
        fprintf (stderr, "Unable to setup wiringPi: %s\n", strerror (errno)) ;
        return 1 ;
    }

    myCounter  = readFile(argv[1]);
    isrCounter = myCounter;
    lastRateCount = myCounter;
    lastTime = time(NULL);

    pinMode (OUT_PIN, OUTPUT) ;
    pinMode (IN_PIN,  INPUT) ;
    pullUpDnControl(IN_PIN,  PUD_UP) ;

    if (wiringPiISR (IN_PIN, INT_EDGE_FALLING, &myInterrupt) < 0) {
        fprintf (stderr, "Unable to setup ISR: %s\n", strerror (errno)) ;
        return 1 ;
    }

    if (updateFile(argv[1], "0") != 0 ) {
        return 1 ;
    }

    if (argc >= 3 && updateFile(argv[2], "0") != 0 ) {
        return 1; 
    }

    if (argc == 4) intervalTime = atol(argv[3]);

    for (;;) {
        printf ("\nWaiting... ") ; fflush (stdout) ;

        while (myCounter == isrCounter)
            delay (100) ;

        if ( lastCounter != 0 ) {
            printf ("Count %lu (diff %lu). ", isrCounter, myCounter - lastCounter) ;
        }
        lastCounter = myCounter ;
        myCounter   = isrCounter ;
        if ( lastCounter != 0 ) {
            sprintf(buf, "%lu\n", myCounter);
            updateFile(argv[1], buf);
        }
        digitalWrite (OUT_PIN, isrCounter & 0x1 ) ;

        if ( argc == 2 )
            continue;
        
        currTime = time(NULL);
        if ( currTime - lastTime >= intervalTime  ) {
            rate = (unsigned long) ((myCounter - lastRateCount) / (( currTime - lastTime) / (float) 3600));
            sprintf(buf, "%lu\n", rate);
            updateFile(argv[2], buf);
            printf ("Rate is %lu in %lu seconds",  rate,  currTime - lastTime );
            lastRateCount = myCounter;
            lastTime = currTime;
        }
    }

    return 0 ;
}
