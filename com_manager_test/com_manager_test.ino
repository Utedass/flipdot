
#include "com_manager.h"

#define BAUD_RATE 115200


Com_manager com;

void setup()
{
	com_manager_init(&com, BAUD_RATE);
	Serial.println("Up n running!");
}

void loop()
{

}