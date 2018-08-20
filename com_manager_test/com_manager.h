// com_manager.h

#ifndef _COM_MANAGER_h
#define _COM_MANAGER_h

#if defined(ARDUINO) && ARDUINO >= 100
	#include "arduino.h"
#else
	#include "WProgram.h"
#endif

#if defined(__cplusplus)
extern "C"{
#endif

struct Com_manager;

struct Com_manager_state{
	void (*entry)(struct Com_manager *c);
	void (*update)(struct Com_manager *c);
	void (*leave)(struct Com_manager *c);
	void (*command)(struct Com_manager *c, const char cmd);
	void *aux;
};

struct Com_manager{
	struct Com_manager_state *state;
	unsigned int baud_rate;
};

void com_manager_init(struct Com_manager *c, unsigned int baud_rate);
void com_manager_update(struct Com_manager *c);
void com_manager_command(struct Com_manager *c, char cmd);

extern struct Com_manager_state wait_for_command;

#if defined(__cplusplus)
}
#endif

#endif

