/***

	bitlashtelnet.pde:	Bitlash Telnet Server for the Ethernet Shield

	Copyright (C) 2008-2012 Bill Roy

	Permission is hereby granted, free of charge, to any person
	obtaining a copy of this software and associated documentation
	files (the "Software"), to deal in the Software without
	restriction, including without limitation the rights to use,
	copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following
	conditions:
	
	The above copyright notice and this permission notice shall be
	included in all copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
	OTHER DEALINGS IN THE SOFTWARE.
***/
#if defined(ARDUINO) && ARDUINO >= 100
	#include "Arduino.h"
	#define serialPrintByte(b) Serial.write(b)
	#include <Ethernet.h>
	#include <EthernetClient.h>
	#include <EthernetServer.h>
	#include <util.h>
#else
	#include "WProgram.h"
	#define serialPrintByte(b) Serial.print(b,BYTE)
	#include <Ethernet.h>
#endif
#include "bitlash.h"
#include <SPI.h>

////////////////////////////////////////
//
//	Ethernet configuration
//	Adjust for local conditions
//
byte mac[] 		= {'b','i','t','l','s','h'};
byte ip[]  		= {192, 168, 0, 27};
byte gateway[] 	= {192, 168, 0, 1};
byte subnet[] 	= {255, 255, 255, 0};
#define PORT 8080
//
////////////////////////////////////////

#if defined(ARDUINO) && ARDUINO >= 100
EthernetServer server = EthernetServer(PORT);
EthernetClient client;
#else
Server server = Server(PORT);
Client client(MAX_SOCK_NUM);		// declare an inactive client
#endif

void serialHandler(byte b) {
	serialPrintByte(b);
	if (client && client.connected()) client.print((char) b);
}

// Command line buffer for alternate command input stream
#define LBUFLEN 140
byte llen;
char linebuf[LBUFLEN];


void setup(void) {

	initBitlash(57600);
	Ethernet.begin(mac, ip, gateway, subnet);
	server.begin();

	setOutputHandler(&serialHandler);
}

void loop(void) {
	
	client = server.available();
	if (client) {
		extern void displayBanner(void);
		displayBanner();
		extern void prompt(void);
		prompt();
		while (client.connected()) {
			if (client.available()) {
				char c = client.read();
				if ((c == '\r') || (c == '\n')) {
					if (llen) {
						linebuf[llen] = '\0';
						doCommand(linebuf);
						llen = 0;
						prompt();
					}
				}
				else if (llen < LBUFLEN-1) linebuf[llen++] = c;
				else {;}	// drop overtyping on the floor here
			}
			else runBitlash();
		}
	}
	runBitlash();
}
