//import controlP5.*;

import java.io.File;
import java.awt.event.KeyEvent;
import javax.swing.JOptionPane;
import processing.serial.*;

//Debug
boolean debug = false;

float x, y, z;

float i=0;

int x_i = 0, y_i = 0;

int time=0;
int screen_update_delay = 10;

int animation_num = 0;

final int SIGN_WIDTH = 16, SIGN_HEIGHT = 32;

final int CYAN = color(0, 255, 0);
final int ORANGE = color(0, 255, 0);
final int YELLOW = color(0, 255, 0);
final int PURPLE = color(0, 255, 0);
final int BLUE = color(0, 255, 0);
final int RED = color(0, 255, 0);
final int GREEN = color(0, 255, 0);

//ControlP5 controlP5;
Grid board, preview;
Tetromino curr;
Shape next;
Shape[] shapes = new Shape[7];
int timer = 20;
int currTime = 0;
int score = 0;
int lines = 0;
int level = 1;
final int SPEED_DECREASE = 2;
boolean game_over = false;

final int dot_px = 20;
final int fd_dot_height = 32;
final int fd_dot_width = 16;

final int grid_x = 10;
final int grid_y = 32;

int next_shape = (int)random(7);

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

int[][] new_frame = new int[2*SIGN_WIDTH][2*SIGN_HEIGHT];
int[][] old_frame = new int[2*SIGN_WIDTH][2*SIGN_HEIGHT];

void setup() {
  size(560, 640, P2D);
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

  //paint_all(0);

  textSize(25);
  //controlP5 = new ControlP5(this);
  //controlP5.addButton("play", 1, width/2 - 35, height/2, 70, 20).setLabel("play again");
  shapes[0] = new Shape(4, new int[] {8, 9, 10, 11}, CYAN);  // I
  shapes[1] = new Shape(3, new int[] {0, 3, 4, 5}, BLUE);  // J
  shapes[2] = new Shape(3, new int[] {2, 3, 4, 5}, ORANGE);  // L
  shapes[3] = new Shape(2, new int[] {0, 1, 2, 3}, YELLOW);  // O
  shapes[4] = new Shape(4, new int[] {5, 6, 8, 9}, GREEN);  // S
  shapes[5] = new Shape(3, new int[] {1, 3, 4, 5, }, PURPLE);  // T
  shapes[6] = new Shape(4, new int[] {4, 5, 9, 10}, RED);  // Z


  //Grid(int x, int y, int w, int h, int rows, int cols)
  board = new Grid(0, 0, dot_px*(grid_x+1), dot_px*SIGN_HEIGHT, grid_y, grid_x);
  preview = new Grid(dot_px*(grid_x+2), dot_px, dot_px*4, dot_px*2, 2, 4);
  next = shapes[next_shape];
  loadNext();
  
  //if (port != null)
  //{
  //  for (int  X = 0; X < 56; X++)
  //  {
  //    for (int Y = 0; Y < 64; Y++)
  //    {
  //      pixel(X, Y, 0);
  //      delay(1);
  //    }
  //  }
  //}
  
}

void draw() {
  background(0);
  noSmooth();//test

  if (game_over) 
  {
    textSize(52);
    textAlign(CENTER);
    //text("GAME OVER\nSCORE: " + score, width/2 - 70, height/2 - 50);
    //text("GAME\nOVER", width/2, height/2-50);
    //controlP5.draw(); // show the play again button
    //draw_to_screen();
  } else
  {
    currTime++;
  }

  if (currTime >= timer && board.animateCount == -1)
  {
    curr.stepDown();
  }

  //preview.draw();
  board.draw();

  if (curr != null)
  {
    curr.draw();
  }

  next.preview();
  fill(255, 0, 0);
  textSize(15);
  textAlign(LEFT);
  text("LEVEL: " + level+"\nLINES: " + lines + "\nSCORE:\n" + score, width - 95, 120);


  fill(0, 255, 0);
  rect(dot_px*(grid_x), 0, dot_px, dot_px*fd_dot_height);
  //fill(255, 0, 0);
  //rect(dot_px*(grid_x), 0, dot_px, dot_px*fd_dot_height);

  if (debug)
  {
    noStroke();
    fill(255);
    for (int X = 0; X < SIGN_WIDTH; X++)
    {
      for (int  Y = 0; Y < SIGN_HEIGHT; Y++)
      {  
        rect(X*dot_px, Y*dot_px, 1, 2);
      }
    }
  }

  //if (game_over) 
  //{
  //  fill(0);
  //  rect(0, 0, width, height);
  //}

  draw_to_screen();
}

void draw_to_screen()
{
  if (port != null)
  {

    if ((millis() > time + 10 ))
    {
      loadPixels();

      for (int X = 0; X < 2*SIGN_WIDTH; X++)
      {
        for (int  Y = 0; Y < 2*SIGN_HEIGHT; Y++)
        {

          new_frame[X][Y] = (int) pixels[Y*dot_px*width/2+X*dot_px/2] >> 8 & 0xFF;

          if (new_frame[X][Y] != old_frame[X][Y])
          {
            //pixel(Y, 15-X, new_frame[X][Y]);

            //pixel(Y, 15-X, new_frame[X][Y]);
            pixel(X, Y, new_frame[X][Y]);
          }

          old_frame[X][Y] = new_frame[X][Y];
        }
      }

      time = millis();
    }
  }
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

void loadNext() 
{
  curr = new Tetromino(next);
  next_shape = (next_shape + 1 + (int)random(5))%7;
  next = shapes[next_shape];
  println(next_shape);
  currTime = 0;
}

void keyPressed() 
{

  if (curr == null || game_over)
  {
    if (key == 'r')
    {
      restart();
      refresh_flip_dot();
    }
    return;
  } 
  
    
  
  
  switch(keyCode) 
  {
  case LEFT : 
    curr.left(); 
    break;
  case RIGHT : 
    curr.right(); 
    break;
  case UP : 
    curr.rotate(); 
    break;
    //case DOWN : curr.down(); break;
  case DOWN : 
    curr.hardDown(); 
    break;
  }

  if (key == 'r')
  {
    restart();
  }
  
  if (key == 'u')
  {
    refresh_flip_dot();
  }
  
}

void play(int value) 
{
  board.clear();
  loadNext();
}

void paint_all(int c)
{
  if (port != null)
  {
    for (int  X = 0; X < SIGN_HEIGHT; X++)
    {
      for (int Y = 0; Y < SIGN_WIDTH; Y++)
      {
        pixel(X, Y, c); //Swaped x and y
      }
    }
  }
}

void refresh_flip_dot()
{
  if (port != null)
  {
      loadPixels();

      for (int X = 0; X < 2*SIGN_WIDTH; X++)
      {
        for (int  Y = 0; Y < 2*SIGN_HEIGHT; Y++)
        {
          pixel(X, Y, (int) pixels[Y*dot_px*width/2+X*dot_px/2] >> 8 & 0xFF); 
        }
      }
  }
}

void restart()
{
  score = 0;
  lines = 0;
  level = 1;
  play(0);

}
