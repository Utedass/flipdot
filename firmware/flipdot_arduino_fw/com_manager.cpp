// 
// 
// 

#include "com_manager.h"
#include "flipdot.h"

//#define debug(msg) Serial.println(msg)
#define debug(msg)

enum SERIAL_COMMAND{
	CMD_PIXEL_OFF,
	CMD_PIXEL_ON,
	CMD_CLEAR_SCREEN,
	CMD_RESET_COM = 0xff,
};

enum SERIAL_REPLY{
	REPLY_ACK = 0x06,
	REPLY_NAK = 0x15,
	REPLY_RDY = 0x07,
	REPLY_SUCCESS = 0x19,
	REPLY_FAIL = 0x21
};

enum FLAGS_A{
	FLAGS_A_PIXEL_OFF = 1,
};

// Declarations for individual state's functions
void com_wait_for_command_entry(struct Com_manager *c);
void com_wait_for_command_command(struct Com_manager *c, const unsigned char cmd);

void com_reset_com_entry(struct Com_manager *c);

void com_wait_x_command(struct Com_manager *c, const unsigned char cmd);

void com_wait_y_command(struct Com_manager *c, const unsigned char cmd);

void com_clear_screen_entry(struct Com_manager *c);

void com_pixel_off_entry(struct Com_manager *c);

void com_pixel_on_entry(struct Com_manager *c);


// Initialization of states
struct Com_manager_state com_wait_for_command	= {com_wait_for_command_entry, NULL, NULL, com_wait_for_command_command, NULL};
struct Com_manager_state com_reset_com			= {com_reset_com_entry, NULL, NULL, NULL, NULL};
struct Com_manager_state com_wait_x				= {NULL, NULL, NULL, com_wait_x_command, NULL};
struct Com_manager_state com_wait_y				= {NULL, NULL, NULL, com_wait_y_command, NULL};
struct Com_manager_state com_clear_screen		= {com_clear_screen_entry, NULL, NULL,  NULL, NULL};
struct Com_manager_state com_pixel_off			= {com_pixel_off_entry, NULL, NULL,  NULL, NULL};
struct Com_manager_state com_pixel_on			= {com_pixel_on_entry, NULL, NULL,  NULL, NULL};

void change_state(struct Com_manager *c, struct Com_manager_state *s)
{
	if(!c || !s)
		return;
		
	if(c->state->leave)
		c->state->leave(c);
			
	c->state = s;
		
	if(c->state->entry)
		c->state->entry(c);
}

void com_manager_init(struct Com_manager *c)
{
	if(!c)
		return;

	c->flags_a = 0;
		
	c->state = &com_wait_for_command;
	
	if(c->state->entry)
		c->state->entry(c);
		
}

void com_manager_update(struct Com_manager *c)
{
	if(!c || !c->state->update)
		return;
		
	c->state->update(c);
}

void com_manager_command(struct Com_manager *c, const unsigned char cmd)
{
	if(!c || !c->state->command)
		return;
	
	c->state->command(c, cmd);
}

// ======================== Individual states functions ======================== //

void com_wait_for_command_entry(struct Com_manager *c)
{
	debug("Entered com_wait_for_command_command");
	if(!c)
		return;
		
	Serial.write(REPLY_RDY);
}


void com_wait_for_command_command(struct Com_manager *c, const unsigned char cmd)
{
	debug("Entered com_wait_for_command_command");
	if(!c)
		return;
		
	switch(cmd)
	{
	case CMD_PIXEL_OFF:
		Serial.write(REPLY_ACK);
		c->flags_a |= FLAGS_A_PIXEL_OFF;
		change_state(c, &com_wait_x);
		break;
		
	case CMD_PIXEL_ON:
		Serial.write(REPLY_ACK);
		c->flags_a &= ~FLAGS_A_PIXEL_OFF;
		change_state(c, &com_wait_x);
		break;
		
	case CMD_CLEAR_SCREEN:
		Serial.write(REPLY_ACK);
		change_state(c, &com_clear_screen);
		break;
		
	case CMD_RESET_COM:
		Serial.write(REPLY_ACK);
		change_state(c, &com_reset_com);
		break;
		
	default:
		Serial.write(REPLY_NAK);
		change_state(c, &com_reset_com);
	}
}

void com_reset_com_entry(struct Com_manager *c)
{
	debug("Entered com_reset_com_entry");
	if(!c)
		return;
		
	change_state(c, &com_wait_for_command);
}

void com_wait_x_command(struct Com_manager *c, const unsigned char cmd)
{
	debug("Entered com_wait_x_command");
	if(!c)
		return;
		
	if(cmd == CMD_RESET_COM)
	{
		debug("Resetting com");
		Serial.write(REPLY_ACK);
		change_state(c, &com_reset_com);
		return;
	}

	Serial.write(REPLY_ACK);
	
	c->cursor_x = cmd;
	
	change_state(c, &com_wait_y);
}

void com_wait_y_command(struct Com_manager *c, const unsigned char cmd)
{
	debug("Entered com_wait_y_command");
	if(!c)
		return;
		
	if(cmd == CMD_RESET_COM)
	{
		debug("Resetting com");
		Serial.write(REPLY_ACK);
		change_state(c, &com_reset_com);
		return;
	}
		
	Serial.write(REPLY_ACK);

	c->cursor_y = cmd;
		
	if(c->flags_a | FLAGS_A_PIXEL_OFF)
		change_state(c, &com_pixel_off);
	else
		change_state(c, &com_pixel_on);
}

void com_clear_screen_entry(struct Com_manager *c)
{
	debug("Entered com_clear_screen_entry");
	if(!c)
		return;
		
	for(int y = 0; y < SCREEN_HEIGHT; y++)
	{
		for(int x = 0; x < SCREEN_WIDTH; x++)
		{
			pixel_off(x, y);
		}
	}

	Serial.write(REPLY_SUCCESS);
	change_state(c, &com_reset_com);
}

void com_pixel_off_entry(struct Com_manager *c)
{
	debug("Entered com_pixel_off_entry");
	if(!c)
		return;
	
	pixel_off(c->cursor_x, c->cursor_y);
	Serial.write(REPLY_SUCCESS);	
	change_state(c, &com_reset_com);
}

void com_pixel_on_entry(struct Com_manager *c)
{
	debug("Entered com_pixel_on_entry");
	if(!c)
		return;
		
	pixel_on(c->cursor_x, c->cursor_y);
	Serial.write(REPLY_SUCCESS);	
	change_state(c, &com_reset_com);
}