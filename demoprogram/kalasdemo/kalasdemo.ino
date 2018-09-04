#include "flashdata.h"

#define BAUDRATE 1000000

enum SERIAL_COMMAND{
	CMD_PIXEL_OFF,
	CMD_PIXEL_ON,
	CMD_PIXEL_STREAM,
	CMD_CLEAR_SCREEN,
	CMD_ESCAPE = 0xfe,
	CMD_RESET_COM = 0xff,
};

enum SERIAL_REPLY{
	REPLY_ACK = 0x06,
	REPLY_NAK = 0x15,
	REPLY_RDY = 0x07,
	REPLY_SUCCESS = 0x19,
	REPLY_FAIL = 0x21
};

enum{
	STATE_RESET,
	STATE_INIT,
	STATE_ROLL_ADMITTANSEN,
	NUM_STATES
	} current_state;

void setup()
{
	Serial.begin(BAUDRATE);
	
	current_state = STATE_INIT;
}

void loop()
{
	char c;
	
	switch(current_state)
	{	
	case STATE_RESET:
		delay(1000);
		
		// Clear serial buffer
		while(Serial.available()){Serial.read();}
			
		Serial.write(CMD_RESET_COM);
		
		while(!Serial.available()){}
		c = Serial.read();
		if(c != REPLY_ACK)
		{
			current_state = STATE_RESET;
			break;
		}
		
		while(!Serial.available()){}
		c = Serial.read();
		if(c != REPLY_RDY)
		{
			current_state = STATE_RESET;
			break;
		}
		current_state = STATE_INIT;
		break;
		
	case STATE_INIT:
		
		Serial.write(CMD_CLEAR_SCREEN);
		
		while(!Serial.available()){}
		c = Serial.read();
		if(c != REPLY_ACK)
		{
			current_state = STATE_RESET;
			break;
		}
		
		while(!Serial.available()){}
		c = Serial.read();
		if(c != REPLY_RDY)
		{
			current_state = STATE_RESET;
			break;
		}
		
		if(!draw_flash_to_screen(ADMITTANSEN_BG))
		{
			current_state = STATE_RESET;
			break;
		}
		
		current_state = STATE_ROLL_ADMITTANSEN;
		
		break;
		
	case STATE_ROLL_ADMITTANSEN:
		break;
		
	default:
		break;
	}
	
}


boolean draw_flash_to_screen(const char* data)
{
	boolean status = false;
	if(Serial.available())
		return false;
		
	Serial.write(CMD_PIXEL_STREAM);
	
	for(int i = 0; i < 448; i++)
	{
		char chunk = pgm_read_byte(data[i]);
		if(chunk == CMD_ESCAPE || chunk == CMD_RESET_COM)
		{
			Serial.write(CMD_ESCAPE);
			if(!wait_for_cmd(REPLY_ACK))
				return false;
		}
		Serial.write(chunk);
		if(!wait_for_cmd(REPLY_ACK))
			return false;
	}
	if(!wait_for_cmd(REPLY_SUCCESS))
		return false;
}

boolean wait_for_cmd(const char cmd)
{
	
	while(!Serial.available()){}
	char c = Serial.read();
	if(c != cmd)
	{
		return false;
	}
	return true;
}
