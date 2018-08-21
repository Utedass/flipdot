import java.util.EnumMap;
import processing.serial.*;
import javax.swing.JOptionPane;
import java.util.concurrent.locks.*;

// Name of this can for some reason not be STATE as it apparently collides with the class named State. Something to do with
// the class files generated from internal classes as flipdot_PC_test_protocol$STATE and so on.
enum STATES{
  SEND_BYTE,
  WAIT_FOR_REPLY,
  RESET,
  WAIT_FOR_READY,
  IDLE,
  PIXEL_ON,
  PIXEL_OFF,
  SEND_X,
  SEND_Y,
  CLEAR_SCREEN,
  WAIT_FOR_SUCCESS,
  FATAL_ERROR
}

public final class SERIAL_COMMAND{
  private SERIAL_COMMAND(){};
  
  public static final byte PIXEL_OFF    = (byte) 0x00;
  public static final byte PIXEL_ON     = (byte) 0x01;
  public static final byte CLEAR_SCREEN = (byte) 0x02;
  public static final byte RESET_COM    = (byte) 0xff;
}

public final class SERIAL_REPLY{
  private SERIAL_REPLY(){};
  
  public static final byte ACK     = (byte) 0x06;
  public static final byte NAK     = (byte) 0x15;
  public static final byte RDY     = (byte) 0x07;
  public static final byte SUCCESS = (byte) 0x19;
  public static final byte FAIL    = (byte) 0x21;
}

public static final int DEBUG_LEVEL = 10;

void DEBUG(String s){
  DEBUG(s, 5);
}

void DEBUG(String s, int priority){
  if(priority < DEBUG_LEVEL){
    println(s);
  }
}

class SM {
  // ================== Public
  SM(Serial port){
    this.port = port;
    
    global_lock = new ReentrantLock();
        
    // Initialize the state map with each according state
    state_map = new EnumMap<STATES, State>(STATES.class);
    
    state_map.put(STATES.SEND_BYTE,        new Send_byte(this));
    state_map.put(STATES.WAIT_FOR_REPLY,   new Wait_for_reply(this));
    state_map.put(STATES.RESET,            new Reset(this));
    state_map.put(STATES.WAIT_FOR_READY,   new Wait_for_ready(this));
    state_map.put(STATES.IDLE,             new Idle(this));
    state_map.put(STATES.PIXEL_ON,         new Pixel_on(this));
    state_map.put(STATES.PIXEL_OFF,        new Pixel_off(this));
    state_map.put(STATES.SEND_X,           new Send_x(this));
    state_map.put(STATES.SEND_Y,           new Send_y(this));
    state_map.put(STATES.CLEAR_SCREEN,     new Clear_screen(this));
    state_map.put(STATES.FATAL_ERROR,      new Fatal_error(this));
    state_map.put(STATES.WAIT_FOR_SUCCESS, new Wait_for_success(this));
        
    current = state_map.get(STATES.RESET);
    current.enter();
  }
  
  public void update() {
    global_lock.lock();
    current.update();
    last_update = millis();
    global_lock.unlock();
  }
  
  public boolean ready(){
    boolean result;
    
    global_lock.lock();
    result = (current == state_map.get(STATES.IDLE));
    global_lock.unlock();
    
    return result;
  }
  
  public boolean pixel_on(int x, int y){
    if(ready())
    {
      global_lock.lock();
      cursor_x = x;
      cursor_y = y;
      change_state(STATES.PIXEL_ON);
      global_lock.unlock();
      return true;
    }
    return false;
  }
  
  public boolean pixel_off(int x, int y){
    if(ready())
    {
      global_lock.lock();
      cursor_x = x;
      cursor_y = y;
      change_state(STATES.PIXEL_OFF);
      global_lock.unlock();
      return true;
    }
    return false;
  }
  
  public boolean clear(){
    if(ready())
    {
      global_lock.lock();
      change_state(STATES.CLEAR_SCREEN);
      global_lock.unlock();
      return true;
    }
    return false;
  }
  
  // ================== Private
  
  // Synchronisation lock
  ReentrantLock global_lock;
  
  // Private collection of all the states
  private EnumMap<STATES, State> state_map;
  
  private State current = null;
  private Serial port = null;
  
  private int cursor_x;
  private int cursor_y;
  
  private int last_update;
  
  // private method to correctly switch state
  private void change_state(STATES next) {
    current.leave();
    current = state_map.get(next);
    current.enter();
  }
  
  private void send_byte(byte cmd, STATES success, STATES fail){
    send_byte(cmd, success, fail, fail);
  }
  
  private void send_byte(byte cmd, STATES success, STATES fail, STATES timeout_fail){
    send_byte(cmd, success, fail, timeout_fail, 5000);
  }
  
  private void send_byte(byte cmd, STATES success, STATES fail, STATES timeout_fail, int timeout){
    Send_byte s = (Send_byte) state_map.get(STATES.SEND_BYTE);
    s.prepare(cmd, success, fail, timeout_fail, timeout);
    change_state(STATES.SEND_BYTE);
  }
  
  private void wait_for_reply(byte reply, STATES success, STATES fail){
    wait_for_reply(reply, success, fail, fail);
  }
  
  private void wait_for_reply(byte reply, STATES success, STATES fail, STATES timeout_fail){
    wait_for_reply(reply, success, fail, timeout_fail, 5000);
  }
  
  private void wait_for_reply(byte reply, STATES success, STATES fail, STATES timeout_fail, int timeout){
    Wait_for_reply s = (Wait_for_reply) state_map.get(STATES.WAIT_FOR_REPLY);
    s.prepare(reply, success, fail, timeout_fail, timeout);
    change_state(STATES.WAIT_FOR_REPLY);
  }
  
  // ================== End of class
}

// Base class for a state
abstract class State {
  State(SM p){
    parent = p;
  }
  
  public void enter() {}
  public void update() {}
  public void leave() {}
  
  // Needs to be able to modify its parent
  protected SM parent;
}

// =============================== Definition of state classes ===============================

// ======================== Send_byte state
class Send_byte extends State {
  Send_byte(SM p){
    super(p);
  }
  
  public void enter(){
    DEBUG("Entering Send_byte (0x" + hex(cmd) + ") state");
    parent.port.write(cmd);
    DEBUG("Byte (0x" + hex(cmd) + ")  sent, waiting for ack..");
    parent.wait_for_reply(SERIAL_REPLY.ACK, success, fail, timeout_fail, timeout);
  }
  /*
  public void update(){
    if(parent.port.available() != 0){
      byte b = (byte)parent.port.read();
      DEBUG("Byte received! Is it the ack?");
      if(b == SERIAL_REPLY.ACK){
        DEBUG("Yes it was!");
        parent.change_state(success);
      }
      else{
        DEBUG("Nope! ERROR!");
        parent.change_state(fail);
      }
    }
  }
  */
  public void leave(){
    DEBUG("Leaving Send_byte state");
  }
  
  public void prepare(byte cmd, STATES success, STATES fail, STATES timeout_fail, int timeout){
    this.cmd = cmd;
    this.success = success;
    this.fail = fail;
    this.timeout_fail = timeout_fail;
    this.timeout = timeout;
  }
  
  private byte cmd;
  private STATES success;
  private STATES fail;
  private STATES timeout_fail;
  private int timeout;
}

// ======================== Wait_for_reply state
class Wait_for_reply extends State {
  Wait_for_reply(SM p){
    super(p);
  }
  
  public void enter(){
    DEBUG("Entering Wait_for_reply (0x" + hex(reply) + ") state");
    start_time = millis();
  }
  
  public void update(){
    if(parent.cursor_x != 1337){    // HIGHLY TEMPORARY TEST; DISABLES WAIT FOR REPLY!
      parent.change_state(success);
      return;
    }
    if(parent.port.available() != 0)
    {
      byte b = (byte)parent.port.read();
      DEBUG("Received byte! (0x" + hex(b) + ") in " + (millis()-start_time) + " ms. Is it the desired  (0x" + hex(reply) + ") ?");
      DEBUG("The last update() was " + (millis()-parent.last_update) + " ms ago.");
      if(b == reply){
        DEBUG("Yes it was!");
        parent.change_state(success);
      }
      else{
        DEBUG("No it wasn't!");
        parent.change_state(fail);
      }
    }
    if(millis()-start_time > timeout){
      DEBUG("Timeout!");
      parent.change_state(fail);
    }
  }
  
  public void leave(){
    DEBUG("Leaving Wait_for_reply state");
  }
  
  public void prepare(byte reply, STATES success, STATES fail, STATES timeout_fail, int timeout){
    this.reply = reply;
    this.success = success;
    this.fail = fail;
    this.timeout_fail = timeout_fail;
    this.timeout = timeout;
  }
  
  // Private
  private byte reply;
  private STATES success;
  private STATES fail;
  private STATES timeout_fail;
  private int timeout;
  private int start_time;
}

// ======================== Reset state
class Reset extends State {
  Reset(SM p){
    super(p);
  }
  
  public void enter(){
    DEBUG("Entering Reset state", 3);
    DEBUG("Waiting for com-port to settle for " + timeout + " ms..");
    last_activity = millis();
  }
  
  public void update(){
    if(parent.port.available() != 0){
      DEBUG("Got some crap! (0x" + hex(parent.port.read()) + ")");
      last_activity = millis();
    }
    else if(millis()-last_activity >= timeout){
      DEBUG("Port has settled down.");
      DEBUG("Sending RESET_COM");
      parent.send_byte(SERIAL_COMMAND.RESET_COM, STATES.WAIT_FOR_READY, STATES.RESET);
    }
  }
  
  public void leave(){
    DEBUG("Leaving Reset state");
  }
  
  private int last_activity;
  private int timeout = 5000;
}

// ======================== Wait_for_ready state
class Wait_for_ready extends State {
  Wait_for_ready(SM p){
    super(p);
  }
  
  public void enter(){
    DEBUG("Entering Wait_for_ready state");
    parent.wait_for_reply(SERIAL_REPLY.RDY, STATES.IDLE, STATES.FATAL_ERROR);
  }
  
  public void leave(){
    DEBUG("Leaving Wait_for_ready state");
  }
}

// ======================== Idle state
class Idle extends State {
  Idle(SM p){
    super(p);
  }
  
  public void enter(){
    DEBUG("Entering Idle state");
  }
  
  public void update(){
    /*       // HIGHLY TEMPORARY TEST; DISABLES WAIT FOR REPLY!
    if(parent.port.available() != 0)
    {
      byte b = (byte)parent.port.read();
      DEBUG("Received byte while idle! (0x" + hex(b) + ")");
      parent.change_state(STATES.RESET);
    }
    */
  }
  
  public void leave(){
    DEBUG("Leaving Idle state");
        // HIGHLY TEMPORARY TEST; DISABLES WAIT FOR REPLY!
    parent.port.write(SERIAL_COMMAND.RESET_COM);
  }
}

// ======================== Pixel_off state
class Pixel_off extends State {
  Pixel_off(SM p){
    super(p);
  }
  
  public void enter(){
    DEBUG("Entering Pixel_off state");
    parent.send_byte(SERIAL_COMMAND.PIXEL_OFF, STATES.SEND_X, STATES.RESET, STATES.RESET);
  }
  
  public void leave(){
    DEBUG("Leaving Pixel_off state");
  }
}

// ======================== Pixel_on state
class Pixel_on extends State {
  Pixel_on(SM p){
    super(p);
  }
  
  public void enter(){
    DEBUG("Entering Pixel_on state");
    parent.send_byte(SERIAL_COMMAND.PIXEL_ON, STATES.SEND_X, STATES.RESET, STATES.RESET);
  }
  
  public void leave(){
    DEBUG("Leaving Pixel_on state");
  }
}

// ======================== Send_x state
class Send_x extends State {
  Send_x(SM p){
    super(p);
  }
  
  public void enter(){
    DEBUG("Entering Send_x state");
    parent.send_byte((byte)parent.cursor_x, STATES.SEND_Y, STATES.RESET, STATES.RESET);
  }
  
  public void leave(){
    DEBUG("Leaving Send_x state");
  }
}

// ======================== Send_y state
class Send_y extends State {
  Send_y(SM p){
    super(p);
  }
  
  public void enter(){
    DEBUG("Entering Send_y state");
    parent.send_byte((byte)parent.cursor_y, STATES.WAIT_FOR_SUCCESS, STATES.RESET, STATES.RESET);
  }
  
  public void leave(){
    DEBUG("Leaving Send_y state");
  }
}

// ======================== Clear_screen state
class Clear_screen extends State {
  Clear_screen(SM p){
    super(p);
  }
  
  public void enter(){
    DEBUG("Entering Clear_screen state");
    parent.send_byte(SERIAL_COMMAND.CLEAR_SCREEN, STATES.WAIT_FOR_SUCCESS, STATES.RESET, STATES.RESET);
  }
  
  public void leave(){
    DEBUG("Leaving Clear_screen state");
  }
}

// ======================== Wait_for_success state
class Wait_for_success extends State {
  Wait_for_success(SM p){
    super(p);
  }
  
  public void enter(){
    DEBUG("Entering Wait_for_success state");
    parent.wait_for_reply(SERIAL_REPLY.SUCCESS, STATES.WAIT_FOR_READY, STATES.RESET, STATES.RESET, 5000);
  }
  
  public void leave(){
    DEBUG("Leaving Wait_for_success state");
  }
}

// ======================== Fatal_error state
class Fatal_error extends State {
  Fatal_error(SM p){
    super(p);
  }
  
  public void enter(){
    DEBUG("Entering Fatal_error state");
  }
}
