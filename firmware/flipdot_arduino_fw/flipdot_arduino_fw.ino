//#include <avr/io.h>
//#include <avr/interrupt.h>
#include <util/delay.h>
#include "flipdot.h"
#include "com_manager.h"

#define BAUD_RATE 115200

Com_manager com;

void setup()
{
	// put your setup code here, to run once:
	Serial.begin(BAUD_RATE);
	com_manager_init(&com);

	flipdot_init();
}

long timer;
byte x, y;

void loop()
{
	/*	
	// For testing the flip dot screen without PC
	for(int y = 0; y < 64; y++)
	{
		
		for(int x = 0; x < 56; x++)
		{
			if((x == 0 && y == 0)||(x == 0 && y == 50)) timer = micros();
			pixel(x , y , 0xff);
			if((x == 0 && y == 0)||(x == 0 && y == 50)) Serial.println(micros()-timer);
		}
		for(int x = 0; x < 56; x++)
		{
			pixel(x , y , 0);
		}
		
		delay(1);
	}

	for(int y = 0; y < 64; y++)
	{
		for(int x = 0; x < 56; x++)
		{
			pixel(x , y , 0);
			
		}
	}
	*/
	
	/*
	if (Serial.available() >= 3)
	{

		uart_buf[0] = Serial.read(); //X data
		uart_buf[1] = Serial.read(); //Y data
		uart_buf[2] = Serial.read(); //color data

		pixel(uart_buf[0], uart_buf[1], uart_buf[2]);
	}
	*/
	com_manager_update(&com);
	
	while(Serial.available())
	{
		byte buf = Serial.read();
		com_manager_command(&com, buf);
	}

}






