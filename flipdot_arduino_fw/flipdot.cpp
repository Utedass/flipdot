// 
// 
// 

#include "flipdot.h"


void shiftOut(int myDataPin, int myClockPin, byte myDataOut);
void my_digitalWrite_PORTB(byte pin, byte val);


byte B_PORTB = 0;
byte B_PORTC = 0;
byte B_PORTD = 0;

char SCREEN_INDEX = 'A';


void flipdot_init()
{
	pinMode(A_CLOCK, OUTPUT);
	pinMode(A_DATA, OUTPUT);
	pinMode(A_LATCH, OUTPUT);

	pinMode(B_CLOCK, OUTPUT);
	pinMode(B_DATA, OUTPUT);
	pinMode(B_LATCH, OUTPUT);
}

void pixel_on(byte x, byte y)
{
	pixel(x, y, 1);
}

void pixel_off(byte x, byte y)
{
	pixel(x, y, 0);
}

static void pixel (byte x_sane, byte y_sane, byte set)
{
	//TRANSFORM X and Y
	byte x = x_sane;
	byte y = y_sane;

	if ( y >= 32)
	{
		y = y - 32;
		SCREEN_INDEX = 'B';
	}
	else
	{
		SCREEN_INDEX = 'A';
	}

	if (y >= 16)
	{
		x = x + 56;
		y = y - 16;
	}

	

	//-----------------------MAGI

	B_PORTB = y_index[y & 0x1f];        //PortB is Row address

	if (set & 0x01)
	{
		/* Select X Board and B1.24 */
		B_PORTC = x_index[x];             //PortC is Column address and bit 6 is set bit
		B_PORTD = x_board[x] | 0x10;      //PortD is
	}
	else
	{
		/* Select X Board, BX.23 and B2.24 */

		//PortC is Column address and bit 6 is set bit
		B_PORTC = x_index[x] | 0x20;//= b 0010 0000

		//PortD is Column section, bit 3 and 5 is
		//.. Row HIGH/LOW side
		B_PORTD = x_board[x] | 0x4;//= b 0000 0100

	}
	
	//-----------------------
	
	

	//shift or shit out stuff

	if(SCREEN_INDEX == 'A')
	{
		my_digitalWrite_PORTB(A_LATCH, 0);
		shiftOut(A_DATA, A_CLOCK, B_PORTD);
		shiftOut(A_DATA, A_CLOCK, B_PORTC);
		shiftOut(A_DATA, A_CLOCK, B_PORTB);
		my_digitalWrite_PORTB(A_LATCH, 1);
	}
	else if(SCREEN_INDEX == 'B')
	{
		my_digitalWrite_PORTB(B_LATCH, 0);
		shiftOut(B_DATA, B_CLOCK, B_PORTD);
		shiftOut(B_DATA, B_CLOCK, B_PORTC);
		shiftOut(B_DATA, B_CLOCK, B_PORTB);
		my_digitalWrite_PORTB(B_LATCH, 1);
	}

	

	_delay_us(20); // lämplig delay för magnetisering... kanske?
	
	// ZERO OUTE THE PORT
	char noll = 0;
	if(SCREEN_INDEX == 'A')
	{
		my_digitalWrite_PORTB(A_LATCH, 0);
		shiftOut(A_DATA, A_CLOCK, noll);
		shiftOut(A_DATA, A_CLOCK, B_PORTC);
		shiftOut(A_DATA, A_CLOCK, B_PORTB);
		my_digitalWrite_PORTB(A_LATCH, 1);

	}
	else if(SCREEN_INDEX == 'B')
	{
		my_digitalWrite_PORTB(B_LATCH, 0);
		shiftOut(B_DATA, B_CLOCK, noll);
		shiftOut(B_DATA, B_CLOCK, B_PORTC);
		shiftOut(B_DATA, B_CLOCK, B_PORTB);
		my_digitalWrite_PORTB(B_LATCH, 1);

	}
	
	_delay_us(20); // Är denna nödvändig?
}


void shiftOut(int myDataPin, int myClockPin, byte myDataOut)
{
	// This shifts 8 bits out MSB first,
	//on the rising edge of the clock,
	//clock idles low

	//internal function setup
	int i = 0;
	int pinState;


	//clear everything out just in case to
	//prepare shift register for bit shifting
	my_digitalWrite_PORTB(myDataPin, 0);
	my_digitalWrite_PORTB(myClockPin, 0);

	//for each bit in the byte myDataOut?
	//NOTICE THAT WE ARE COUNTING DOWN in our for loop
	//This means that %00000001 or "1" will go through such
	//that it will be pin Q0 that lights.
	for (i = 7; i >= 0; i--)
	{
		my_digitalWrite_PORTB(myClockPin, 0);

		//if the value passed to myDataOut and a bitmask result
		// true then... so if we are at i=6 and our value is
		// %11010100 it would the code compares it to %01000000
		// and proceeds to set pinState to 1.
		if ( myDataOut & (1 << i) )
		{
			pinState = 1;
		}
		else
		{
			pinState = 0;
		}

		//Sets the pin to HIGH or LOW depending on pinState
		my_digitalWrite_PORTB(myDataPin, pinState);
		//register shifts bits on upstroke of clock pin
		my_digitalWrite_PORTB(myClockPin, 1);
		//zero the data pin after shift to prevent bleed through
		my_digitalWrite_PORTB(myDataPin, 0);
	}

	//stop shifting
	my_digitalWrite_PORTB(myClockPin, 0);

}

void my_digitalWrite_PORTB(byte pin, byte val)
{
	if(val == HIGH) //HIGH
	{
		PORTB |= 0x01 << (pin - 8);
	}
	else // LOW
	{
		PORTB &= ~(0x01 << (pin - 8));
	}
}



