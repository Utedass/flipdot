//import controlP5.*;

//import java.io.File;
//import java.awt.event.KeyEvent;
//import javax.swing.JOptionPane;
//import processing.serial.*;


Serial port = null;

String portname = null;

void openSerialPort()
{
  if (portname == null) return;
  if (port != null) port.stop();

  port = new Serial(this, portname, 56000);

  println(portname);

  port.bufferUntil('\n');
}

void selectSerialPort()
{
  String result = (String) JOptionPane.showInputDialog(frame, 
    "Select the serial port that corresponds to your Arduino board.", 
    "Select serial port", 
    JOptionPane.QUESTION_MESSAGE, 
    null, 
    Serial.list(), 
    0);

  if (result != null) {
    portname = result;
    openSerialPort();
  }
}

void setup() {
  size(10, 10, P2D);
  selectSerialPort();
  
  print("Serial port is ready\n");
  print("Waiting for dvice to start..\n");
  do{port.write((byte)0xff);}
  while(port.available() == 0);
  delay(500);
  while(port.available() != 0)
  {
    byte b = (byte)port.read();
    print("Got something from the serial port: " + hex(b) + "\n");
  }
  print("Sending reset command\n");
  do{port.write((byte)0xff);}
  while(port.available() == 0);
  print("Reset command sent, waiting for ack..\n");
  while(port.available() == 0);
  while(port.available() != 0)
  {
    byte b = (byte)port.read();
    print("Got something from the serial port: " + hex(b) + "\n");
  }
  
  print("Sending clear command\n");
  port.write((byte)0x02);
  print("Clear command sent, waiting for ack..\n");
  while(port.available() != 0)
  {
    byte b = (byte)port.read();
    print("Got something from the serial port: " + hex(b) + "\n");
  }

  time = millis();

  
}

void draw() {
}

void pixel(int x, int y, int set)
{

  if (set != 0) set = 1;

  port.write((byte) 0xff);
  while(port.available() == 0);
  port.write((byte) set);
  port.write((byte) x);
  port.write((byte) y);

  //println(x + ", " + y  + ", "  + set);

  delay(1);
}


void keyPressed() 
{

  if (curr == null || game_over)
  {
    if (key == 'r')
    {
    }
    return;
  } 
  
}
