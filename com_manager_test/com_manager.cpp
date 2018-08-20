// 
// 
// 

#include "com_manager.h"

void wait_for_command_command(struct Com_manager *c, char cmd);
void reset_com_command(struct Com_manager *c, char cmd);

// Initialization of states
struct Com_manager_state wait_for_command = {NULL, NULL, NULL, wait_for_command_command, NULL};
struct Com_manager_state reset_com = {NULL, NULL, NULL, reset_com_command, NULL};

void change_state(struct Com_manager *c, struct Com_manager_state *s)
{
	if(c && s)
	{
		if(c->state->leave)
			c->state->leave(c);
			
		c->state = s;
		
		if(c->state->entry)
			c->state->entry(c);
	}
}


void com_manager_init(struct Com_manager *c, unsigned int baud_rate)
{
	if(c)
	{
		Serial.begin(baud_rate);
		c->state = &wait_for_command;
	}
}

void com_manager_update(struct Com_manager *c)
{
	if(c && c->state->update)
		c->state->update(c);
}

void com_manager_command(struct Com_manager *c, char cmd)
{
	if(c && c->state->command)
		c->state->command(c, cmd);
}

// Individual states functions

void wait_for_command_command(struct Com_manager *c, char cmd)
{
	change_state(c, &reset_com);
}

void reset_com_command(struct Com_manager *c, char cmd)
{
	change_state(c, &wait_for_command);
}