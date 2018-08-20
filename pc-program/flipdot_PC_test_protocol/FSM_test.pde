import java.util.EnumMap;
import processing.serial.*;
import javax.swing.JOptionPane;

public enum STATE{
  RESET,
  WAIT_FOR_READY,
  IDLE,
  PIXEL_ON,
  PIXEL_OFF,
  SEND_BYTE,
  SEND_X,
  SEND_Y,
  CLEAR_SCREEN
}
  
class SM {
  SM(Serial port){
    this.port = port;
    
    println("At least we got here!");
    
    // Initialize the state map with each according state
    state_map = new EnumMap<STATE, State>(STATE.class);
    println("Uuhm..");
    
    state_map.put(STATE.RESET,          new Reset(this));
    println("Naah..");
    state_map.put(STATE.WAIT_FOR_READY, new Wait_for_ready(this));
    state_map.put(STATE.IDLE,           new Idle(this));
    state_map.put(STATE.PIXEL_ON,       new Pixel_on(this));
    state_map.put(STATE.PIXEL_OFF,      new Pixel_off(this));
    state_map.put(STATE.SEND_BYTE,      new Send_byte(this));
    state_map.put(STATE.SEND_X,         new Send_x(this));
    state_map.put(STATE.SEND_Y,         new Send_y(this));
    state_map.put(STATE.CLEAR_SCREEN,   new Clear_screen(this));
    
    println("But probably not here..");
        
    current = state_map.get(STATE.IDLE);
    current.enter();
  }
  
  // == Private variables ==
  // Private collection of all the states
  private EnumMap<STATE, State> state_map;
  
  private State current = null;
  private Serial port = null;
  
  // private method to correctly switch state
  private void change_state(STATE next) {
    current.leave();
    current = state_map.get(next);
    current.enter();
  }
  
  // The only public available function
  public void update() {
    current.update();
  }
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
  private SM parent;
}

class Reset extends State {
  Reset(SM p){
    super(p);
  }
  
  public void enter(){
  }
}

class Wait_for_ready extends State {
  Wait_for_ready(SM p){
    super(p);
  }
}

class Idle extends State {
  Idle(SM p){
    super(p);
  }
}

class Pixel_off extends State {
  Pixel_off(SM p){
    super(p);
  }
}

class Pixel_on extends State {
  Pixel_on(SM p){
    super(p);
  }
}

class Send_byte extends State {
  Send_byte(SM p){
    super(p);
  }
}

class Send_x extends State {
  Send_x(SM p){
    super(p);
  }
}

class Send_y extends State {
  Send_y(SM p){
    super(p);
  }
}

class Clear_screen extends State {
  Clear_screen(SM p){
    super(p);
  }
}
