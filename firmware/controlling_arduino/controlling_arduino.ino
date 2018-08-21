#define BAUD_RATE 1000000

// 11.41 sek för 2st på 2st av = 2.85s per frame
// 0.35 fps

// Med firmwaren direkt går det på 9.19s = 2.29s per frame
// 0.44 fps

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

bool test()
{
	
}

void fatal_error(byte m = 0xff)
{
  debug(m);
  while(true)
    ;
}

void debug(byte m)
{
  m <<= 2;
  PORTD = m;
}

void setup()
{
	DDRD = 0xfc;
	PORTD = 0xfc;
	
	Serial.begin(BAUD_RATE);
	delay(5000);
	debug(0);
	while(Serial.available()){Serial.read();}
	
	Serial.write(CMD_RESET_COM);
	
	while(!Serial.available())
		;

  debug(1);
  
	if(Serial.read() != REPLY_ACK)
		fatal_error();
		
	while(!Serial.available())
		;
	
	if(Serial.read() != REPLY_RDY)
		fatal_error();

    
   debug(3);
   delay(500);
}

void send_byte(byte b)
{
  Serial.write(b);
  wait_for_byte(REPLY_ACK);
}

void wait_for_byte(byte b)
{
  while(!Serial.available())
    ;

  if(Serial.read() == b)
    return;
   
  fatal_error(0x30);
}

void loop()
{
   for(int y = 0; y < 64; y++)
   {
    for(int x = 0; x < 56; x++)
    {
      send_byte(CMD_PIXEL_ON);
      send_byte(x);
      send_byte(y);
      wait_for_byte(REPLY_SUCCESS);
      wait_for_byte(REPLY_RDY);
    }
   }
   
   for(int y = 0; y < 64; y++)
   {
    for(int x = 0; x < 56; x++)
    {
      send_byte(CMD_PIXEL_OFF);
      send_byte(x);
      send_byte(y);
      wait_for_byte(REPLY_SUCCESS);
      wait_for_byte(REPLY_RDY);
    }
   }
}





