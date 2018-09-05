#include "flashdata.h"

#define BAUDRATE 1000000
#define WIDTH 56
#define HEIGHT 64

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
	STATE_SHOW_ADMITTANSEN,
	STATE_SHOW_MRMEST,
	STATE_SHOW_TROLL,
	STATE_CREATE_LIFE,
	STATE_LIVE_LIFE,
	NUM_STATES
	} current_state;
	
#define WORLD_SIZE (WIDTH*HEIGHT/8)
byte world[WORLD_SIZE];
byte next_world[WORLD_SIZE];


boolean life_getxy(int x, int y, byte *data = world);
void life_setxy(int x, int y, boolean status, byte *data = next_world);

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

unsigned long long life_last_time;
unsigned long long life_timeout = 500;


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
		current_state = STATE_SHOW_ADMITTANSEN;
		
		break;
		
	case STATE_SHOW_ADMITTANSEN:
		if(millis()-last_time >= timeout)
		{
			draw_flash_to_screen(MRMEST_BG);
			last_time = millis();
			current_state = STATE_SHOW_MRMEST;
			break;
		}
		break;
		
	case STATE_SHOW_MRMEST:
		if(millis()-last_time >= timeout)
		{
			draw_flash_to_screen(TROLL_BG);
			last_time = millis();
			current_state = STATE_SHOW_TROLL;
			break;
		}
		break;
		
	case STATE_SHOW_TROLL:
		if(millis()-last_time >= timeout)
		{
			last_time = millis();
			draw_flash_to_screen(ADMITTANSEN_BG);
			current_state = STATE_SHOW_ADMITTANSEN;
			//current_state = STATE_CREATE_LIFE;
			break;
		}
		break;
		
	case STATE_CREATE_LIFE:
		Serial.write(CMD_CLEAR_SCREEN);
		wait_for_cmd(REPLY_ACK);
		wait_for_cmd(REPLY_SUCCESS);
		wait_for_cmd(REPLY_RDY);
		life_init();
		
		current_state = STATE_LIVE_LIFE;
		last_time = millis();
		break;
		
	case STATE_LIVE_LIFE:
		life_update();
		
		if(millis()-last_time >= timeout)
		{
			//draw_flash_to_screen(ADMITTANSEN_BG);
			last_time = millis();
			//current_state = STATE_SHOW_ADMITTANSEN;
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

void put_pixel(unsigned char x, unsigned char y, boolean state)
{
	if(state)
	{
		Serial.write(CMD_PIXEL_ON);
		wait_for_cmd(REPLY_ACK);
	}
	else
	{
		Serial.write(CMD_PIXEL_OFF);
		wait_for_cmd(REPLY_ACK);
	}
	
	Serial.write(x);
	wait_for_cmd(REPLY_ACK);
	Serial.write(y);
	wait_for_cmd(REPLY_ACK);
	wait_for_cmd(REPLY_SUCCESS);
	wait_for_cmd(REPLY_RDY);
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




void life_init()
{
	for(int i = 0; i < WORLD_SIZE; i++)
	{
		world[i] = next_world[i] = 0;
	}
	
	// Add some "blinkers"
	next_world[WIDTH*8+2] = 0x03;
	next_world[WIDTH*16+4] = 0x03;
	next_world[WIDTH*HEIGHT-2] = 0x03;
	
	// Add a spaceship
	life_setxy(5, 21, true);
	life_setxy(6, 22, true);
	life_setxy(7, 20, true);
	life_setxy(7, 21, true);
	life_setxy(7, 22, true);
	
	life_last_time = millis();
}

void life_update()
{	 
	 if(millis()-life_last_time >= life_timeout)
	 {
		 life_draw();
		 
		 for(int y = 0; y < HEIGHT; y++)
		 {
			 for(int x = 0; x < WIDTH; x++)
			 {
				 int alive_neighbours = life_alive_neighbours(x, y);
				 if(life_getxy(x, y))
				 {
					 if(alive_neighbours < 2 || alive_neighbours > 3)
						life_setxy(x, y, false);
				 }
				 else
				 {
					 if(alive_neighbours == 3)
						life_setxy(x, y, true); 
				 }
			 }
		 }
		 
		 life_last_time = millis();
	 }
}

void life_draw()
{
	for(int y = 0; y < HEIGHT; y++)
	{
		for(int x = 0; x < WIDTH; x++)
		{
			if(life_getxy(x, y) != life_getxy(x, y, next_world))
				put_pixel(x, y, life_getxy(x, y, next_world));
		}
	}
	memcpy(world, next_world, WORLD_SIZE);
}

int life_alive_neighbours(int x, int y)
{
	int neighbours = 0;
	
	for(int blocky = y-1; blocky < (y+1); blocky++)
	{
		for(int blockx = x-1; blockx < (x+1); blockx++)
		{
			if(blockx != x && blocky != y)
			{
				if(life_getxy(blockx, blocky))
					neighbours++;
			}
		}
	}
}

boolean life_getxy(int x, int y, byte *data)
{
	while(x < 0)
		x += WIDTH;
	while(y < 0)
		y += HEIGHT;
		
	x %= WIDTH;
	y %= HEIGHT;
	
	unsigned char pixel_index = y*WIDTH + x;
	unsigned char byte_index = pixel_index >> 3; // div by 8
	unsigned char bit_index = pixel_index & (1<<byte_index);
	
	return (world[byte_index] & bit_index) != 0;
}

void life_setxy(int x, int y, boolean status, byte *data)
{
	while(x < 0)
		x += WIDTH;
	while(y < 0)
		y += HEIGHT;
	
	x %= WIDTH;
	y %= HEIGHT;

	unsigned char pixel_index = y*WIDTH + x;
	unsigned char byte_index = pixel_index >> 3; // div by 8
	unsigned char bit_index = pixel_index & (1<<byte_index);
	
	if(status)
		next_world[byte_index] |= bit_index;
	else
		next_world[byte_index] &= ~bit_index;
}
