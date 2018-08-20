
#include "com_manager.h"

#define BAUD_RATE 115200


Com_manager com;

void setup()
{
	Serial.begin(BAUD_RATE);
	com_manager_init(&com);
}

void loop()
{
	com_manager_update(&com);
	
	while(Serial.available())
	{
		unsigned char buf = Serial.read();
		com_manager_command(&com, buf);
	}
}