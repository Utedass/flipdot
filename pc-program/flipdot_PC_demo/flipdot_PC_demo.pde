import java.io.File;
import java.awt.event.KeyEvent;
import javax.swing.JOptionPane;
import processing.serial.*;

import processing.video.*;

SM com;
final static int BAUD_RATE = 1000000;

float x, y, z;

float i=0;

int x_i = 0, y_i = 0;

int time=0;
int screen_update_delay = 10;

int animation_num = 0;

final int SIGN_WIDTH = 56, SIGN_HEIGHT = 64;


public static int REPLY_ACK = 0x06;
public static int REPLY_NAK = 0x15;

// VIDEO -------
Capture video;
Capture video_old;


Serial port = null;

// select and modify the appropriate line for your operating system
// leave as null to use interactive port (press 'p' in the program)
String portname = null;
//String portname = Serial.list()[0]; // Mac OS X
//String portname = "/dev/ttyUSB0"; // Linux
//String portname = "COM6"; // Windows

void openSerialPort()
{
  if (portname == null) return;
  if (port != null) port.stop();

  port = new Serial(this, portname, BAUD_RATE);

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

void update_com(){
  while(!false){ // It's funny because it's true
    com.update();
  }
}

void setup() 
{
  size(560, 640, P3D);
  selectSerialPort();
  com = new SM(port);
  thread("update_com");
  println("Waiting for communiaction to be established..");
  while(!com.ready()){}
  println("System ready!");

  time = millis();

  //VIDEO-----
  video = new Capture(this, 640, 480);
  video.start();
  //----------
  
  print("Started!");

}

int[][] new_frame = new int[SIGN_WIDTH][SIGN_HEIGHT];
int[][] old_frame = new int[SIGN_WIDTH][SIGN_HEIGHT];

void draw() 
{

  switch(animation_num)
  {

  case 0:

    background(0);
    rectMode(CENTER);
    fill(0, 255, 255);
    noStroke();

    //translate(mouseX, mouseY, 0);
    translate(SIGN_WIDTH*10/2+SIGN_WIDTH*5*sin(i*2), SIGN_HEIGHT*10/2+SIGN_HEIGHT*5*cos(i), 50*sin(i));
    rotateZ(PI*i);
    rect(0, 0, 50, 50);
    i+=0.01;

    break;

    case 1:


      if (video.available() && keyPressed ) 
      {
        background(0);

        video.read();
        video.loadPixels();


        if (brightness(video.pixels[(video.width - 10 - 1) + 10*video.width]) > 130)
        {
          println(255);
        } else
        {
          println(0);
        }
        println();

        // Begin loop for columns
        for (int i = 0; i < 56; i++) 
        {
          // Begin loop for rows
          for (int j = 0; j < 48; j++) 
          {

            // Where are we, pixel-wise?
            int x = i * 10;
            int y = j * 10;
            int loc = (video.width - x - 1) + y*video.width; // Reversing x to mirror the image

            // Each rect is colored white with a size determined by brightness
            if (brightness(video.pixels[loc]) > 130)
            {
              fill(0, 255, 0);
            } else
            {
              fill(0);
            }

            noStroke();

            ellipse( x, y + 80, 10, 10);
          }
        }
      }

      break;

      case 2:

      background(0);

        break;
  }



  //  //------------
  draw_to_screen();

}

void draw_to_screen()
{
  if (port != null)
  {

    if ((millis() > time + 10 ))
    {
      loadPixels();

      for (int X = 0; X < SIGN_WIDTH; X++)
      {
        for (int  Y = 0; Y < SIGN_HEIGHT; Y++)
        {

          new_frame[X][Y] = (int) pixels[Y*10*width+X*10] >> 8 & 0xFF;

          if (new_frame[X][Y] != old_frame[X][Y])
          {
            pixel(X, Y, new_frame[X][Y]);
            
          }

          old_frame[X][Y] = new_frame[X][Y];
        }
      }

      time = millis();
    }
  }
}

void clear_screen()
{
  while(!com.clear()){}
  /*
  if (port != null)
  {
    for (int X = 0; X < SIGN_WIDTH; X++)
    {
      for (int  Y = 0; Y < SIGN_HEIGHT; Y++)
      {
        pixel(X, Y, 0); 
        delay(1);
      }
    }
  }
  */
}

void keyPressed() 
{
  if (keyCode == ENTER) 
  {
    animation_num += 1;
    animation_num = animation_num % 3;
  }
  
    if (key == 'u') 
  {
    refresh_screen();
  }
  
}

void pixel(int x, int y, int set)
{
  if(set != 0){
    while(!com.pixel_on(x, y)){}
  }
  else{
    while(!com.pixel_off(x, y)){}
  }
  
/*
  if (set != 0) set = 1;

  port.clear();
  print("Cleared serial buffer\n");
  
  do
  {
    port.write((byte) 0xff);
    print("Wrote 0xff\n");
    print("Waiting for ack\n");
    while(port.available() == 0);
    print("Got something\n");
  }while(port.read() != REPLY_ACK);
    
  port.write((byte) set);
  delay(1);
  port.write((byte) x);
  port.write((byte) y);
  */
  /*print("Waiting for ack\n");
  while(port.available() == 0);
  
  print("Got something\n");
  if(port.read() != REPLY_ACK)
  {
    print("FAIL!!\n");
    while(true);
  }*/
  

  //delay(1); // works sometimes without the delay, need investigation
}

void paint_all(int c)
{
  while(!com.clear()){}
  /*
  int count = 0;
  if (port != null)
  {
    for (int x = 0, y = 0; y < SIGN_HEIGHT; x++)
    {
      if (x == SIGN_WIDTH)
      {
        x = 0;
        y++;
      }

      pixel(x, y, c);
      count++;
    }
  }
  println(count);
  */
}

void refresh_screen()
{
  if (port != null)
  {
      loadPixels();

      for (int X = 0; X < SIGN_WIDTH; X++)
      {
        for (int  Y = 0; Y < SIGN_HEIGHT; Y++)
        {
            pixel(X, Y, (int) pixels[Y*10*width+X*10] >> 8 & 0xFF);
            delay(1);
        }
      }
    
  }
}
