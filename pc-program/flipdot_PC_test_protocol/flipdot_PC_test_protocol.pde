//import controlP5.*;

//import java.io.File;
//import java.awt.event.KeyEvent;
import javax.swing.JOptionPane;
import processing.serial.*;

SM com;

final static int BAUD_RATE = 115200;

Serial selectSerialPort()
{
  Serial port = null;
  String result = (String) JOptionPane.showInputDialog(frame, 
    "Select the serial port that corresponds to your Arduino board.", 
    "Select serial port", 
    JOptionPane.QUESTION_MESSAGE, 
    null, 
    Serial.list(), 
    0);

  if (result != null) {
    String portname = result;
    if (portname == null) return null;
    if (port != null) port.stop();
  
    port = new Serial(this, portname, BAUD_RATE);
  
    println(portname);
  
    //port.bufferUntil('\n');
    return port;
  }
  return null;
}

void setup() {
  size(10, 10, P2D);
  com = new SM(selectSerialPort());
  /*
  print("Serial port is ready\n");
  print("Waiting for dvice to start..\n");
  
  while(port.available() == 0);
  
  delay(500);
  print("Something is on the port!\n");
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
*/
  
}

void draw() {
  com.update();
}

/*
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
*/

void keyPressed() 
{
  switch(key){
  case '1':
    println("pixel_on(5, 10)");
    if(com.pixel_on(5,10)){
      println("pixel will be drawn!");
    }
    else{
      println("System is busy..");
    }
    break;
  case '2':
    if(com.ready()){
      println("System is ready!");
    }
    else{
      println("System is busy..");
    }
    break;
  case 'f':
    println("0xff sent");
    break;
  }  
}
