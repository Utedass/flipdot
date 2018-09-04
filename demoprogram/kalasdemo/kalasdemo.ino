#include "flashdata.h"

#define BAUDRATE 1000000

enum SERIAL_COMMAND{
	CMD_PIXEL_OFF,
	CMD_PIXEL_ON,
	CMD_CLEAR_SCREEN,
	CMD_PIXEL_STREAM,
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
	STATE_ROLL_MRMEST,
	STATE_ROLL_TROLL,
	NUM_STATES
	} current_state;

void setup()
{
	Serial.begin(BAUDRATE);
	
	current_state = STATE_RESET;
	
	pinMode(2, OUTPUT);
	pinMode(3, OUTPUT);
	pinMode(4, OUTPUT);
	pinMode(5, OUTPUT);
	digitalWrite(2, HIGH);
	digitalWrite(3, HIGH);
	digitalWrite(4, HIGH);
	digitalWrite(5, HIGH);
	delay(500);
	digitalWrite(2, LOW);
	digitalWrite(3, LOW);
	digitalWrite(4, LOW);
	digitalWrite(5, LOW);
}

unsigned long long last_time;
unsigned long long timeout = 10000;


void loop()
{
	char c;
	
	switch(current_state)
	{	
	case STATE_RESET:
		digitalWrite(2, HIGH);
		digitalWrite(3, LOW);
		digitalWrite(4, LOW);
		digitalWrite(5, LOW);
		delay(1000);
		
		// Clear serial buffer
		while(Serial.available()){Serial.read();}
		digitalWrite(2, LOW);
		delay(500);
			
		Serial.write(CMD_RESET_COM);
		
		if(!wait_for_cmd(REPLY_ACK))
			break;
		
		if(!wait_for_cmd(REPLY_RDY))
			break;
		
		current_state = STATE_INIT;
		break;
		
	case STATE_INIT:
		digitalWrite(3, HIGH);
		
		Serial.write(CMD_CLEAR_SCREEN);
		
		if(!wait_for_cmd(REPLY_ACK))
		{
			current_state = STATE_RESET;
			break;
		}
		
		digitalWrite(4, HIGH);
		
		if(!wait_for_cmd(REPLY_SUCCESS))
		{
			current_state = STATE_RESET;
			break;
		}
	
		if(!wait_for_cmd(REPLY_RDY))
		{
			current_state = STATE_RESET;
			break;
		}
		
		digitalWrite(5, HIGH);
		
		
		if(!draw_flash_to_screen(ADMITTANSEN_BG))
		{
			current_state = STATE_RESET;
			break;
		}
		current_state = STATE_ROLL_ADMITTANSEN;
		
		break;
		
	case STATE_ROLL_ADMITTANSEN:
		if(millis()-last_time >= timeout)
		{
			draw_flash_to_screen(MRMEST_BG);
			last_time = millis();
			current_state = STATE_ROLL_MRMEST;
			break;
		}
		break;
		
	case STATE_ROLL_MRMEST:
		if(millis()-last_time >= timeout)
		{
			draw_flash_to_screen(TROLL_BG);
			last_time = millis();
			current_state = STATE_ROLL_TROLL;
			break;
		}
		break;
		
	case STATE_ROLL_TROLL:
		if(millis()-last_time >= timeout)
		{
			draw_flash_to_screen(ADMITTANSENL_BG);
			last_time = millis();
			current_state = STATE_ROLL_ADMITTANSEN;
			break;
		}
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
	if(!wait_for_cmd(REPLY_ACK))
		return false;
	
	for(int i = 0; i < 448; i++)
	{
		unsigned char chunk = pgm_read_byte(data+i);
		
		//chunk = 0xff;
		
		if(chunk == CMD_ESCAPE || chunk == CMD_RESET_COM)
		{
			Serial.write(CMD_ESCAPE);
			if(!wait_for_cmd(REPLY_ACK))
				return false;
		}
		Serial.write(chunk);
		if(!wait_for_cmd(REPLY_ACK))
			fatal();
	}
	if(!wait_for_cmd(REPLY_SUCCESS))
		return false;
	if(!wait_for_cmd(REPLY_RDY))
		return false;
		
	return true;
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


void fatal()
{
	while(true)
	{
		digitalWrite(2, LOW);
		digitalWrite(3, LOW);
		digitalWrite(4, LOW);
		digitalWrite(5, LOW);
		delay(100);
		digitalWrite(2, HIGH);
		digitalWrite(3, HIGH);
		digitalWrite(4, HIGH);
		digitalWrite(5, HIGH);
		delay(100);
	}
}
