// 
// 
// 

#include "com_manager.h"

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
void wait_for_command_entry(struct Com_manager *c);
void wait_for_command_command(struct Com_manager *c, const unsigned char cmd);

void reset_com_entry(struct Com_manager *c);

void wait_x_command(struct Com_manager *c, const unsigned char cmd);

void wait_y_command(struct Com_manager *c, const unsigned char cmd);

void clear_screen_entry(struct Com_manager *c);

void pixel_off_entry(struct Com_manager *c);

void pixel_on_entry(struct Com_manager *c);


// Initialization of states
struct Com_manager_state wait_for_command = {wait_for_command_entry, NULL, NULL, wait_for_command_command, NULL};
struct Com_manager_state reset_com = {reset_com_entry, NULL, NULL, NULL, NULL};
struct Com_manager_state  wait_x = {NULL, NULL, NULL,  wait_x_command, NULL};
struct Com_manager_state  wait_y = {NULL, NULL, NULL,  wait_y_command, NULL};
struct Com_manager_state  clear_screen = {clear_screen_entry, NULL, NULL,  NULL, NULL};
struct Com_manager_state  pixel_off = {pixel_off_entry, NULL, NULL,  NULL, NULL};
struct Com_manager_state  pixel_on = {pixel_on_entry, NULL, NULL,  NULL, NULL};

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
		
	c->state = &wait_for_command;
	
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

void wait_for_command_entry(struct Com_manager *c)
{
	debug("Entered wait_for_command_command");
	if(!c)
		return;
		
	Serial.write(REPLY_RDY);
}


void wait_for_command_command(struct Com_manager *c, const unsigned char cmd)
{
	debug("Entered wait_for_command_command");
	if(!c)
		return;
		
	switch(cmd)
	{
	case CMD_PIXEL_OFF:
		Serial.write(REPLY_ACK);
		c->flags_a |= FLAGS_A_PIXEL_OFF;
		change_state(c, &wait_x);
		break;
		
	case CMD_PIXEL_ON:
		Serial.write(REPLY_ACK);
		c->flags_a &= ~FLAGS_A_PIXEL_OFF;
		change_state(c, &wait_x);
		break;
		
	case CMD_CLEAR_SCREEN:
		Serial.write(REPLY_ACK);
		change_state(c, &clear_screen);
		break;
		
	case CMD_RESET_COM:
		Serial.write(REPLY_ACK);
		change_state(c, &reset_com);
		break;
		
	default:
		Serial.write(REPLY_NAK);
		change_state(c, &reset_com);
	}
}

void reset_com_entry(struct Com_manager *c)
{
	debug("Entered reset_com_entry");
	if(!c)
		return;
		
	change_state(c, &wait_for_command);
}

void wait_x_command(struct Com_manager *c, const unsigned char cmd)
{
	debug("Entered wait_x_command");
	if(!c)
		return;
		
	if(cmd == CMD_RESET_COM)
	{
		debug("Resetting com");
		Serial.write(REPLY_ACK);
		change_state(c, &reset_com);
		return;
	}

	Serial.write(REPLY_ACK);
	
	c->cursor_x = cmd;
	
	change_state(c, &wait_y);
}

void wait_y_command(struct Com_manager *c, const unsigned char cmd)
{
	debug("Entered wait_y_command");
	if(!c)
		return;
		
	if(cmd == CMD_RESET_COM)
	{
		debug("Resetting com");
		Serial.write(REPLY_ACK);
		change_state(c, &reset_com);
		return;
	}
		
	Serial.write(REPLY_ACK);

	c->cursor_y = cmd;
		
	if(c->flags_a | FLAGS_A_PIXEL_OFF)
		change_state(c, &pixel_off);
	else
		change_state(c, &pixel_on);
}

void clear_screen_entry(struct Com_manager *c)
{
	debug("Entered clear_screen_entry");
	if(!c)
		return;
		
	change_state(c, &reset_com);
}

void pixel_off_entry(struct Com_manager *c)
{
	debug("Entered pixel_off_entry");
	if(!c)
		return;
	
	Serial.write(REPLY_SUCCESS);
	change_state(c, &reset_com);
}

void pixel_on_entry(struct Com_manager *c)
{
	debug("Entered pixel_on_entry");
	if(!c)
		return;
		
	Serial.write(REPLY_SUCCESS);
	change_state(c, &reset_com);
}