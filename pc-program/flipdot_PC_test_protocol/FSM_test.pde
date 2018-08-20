import java.util.EnumMap;
import processing.serial.*;
import javax.swing.JOptionPane;

// Name of this can for some reason not be STATE as it apparently collides with the class named State. Something to do with
// the class files generated from internal classes as flipdot_PC_test_protocol$STATE and so on.
enum STATES{
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
    
    // Initialize the state map with each according state
    state_map = new EnumMap<STATES, State>(STATES.class);
    
    state_map.put(STATES.RESET,          new Reset(this));
    
    state_map.put(STATES.WAIT_FOR_READY, new Wait_for_ready(this));
    state_map.put(STATES.IDLE,           new Idle(this));
    state_map.put(STATES.PIXEL_ON,       new Pixel_on(this));
    state_map.put(STATES.PIXEL_OFF,      new Pixel_off(this));
    state_map.put(STATES.SEND_BYTE,      new Send_byte(this));
    state_map.put(STATES.SEND_X,         new Send_x(this));
    state_map.put(STATES.SEND_Y,         new Send_y(this));
    state_map.put(STATES.CLEAR_SCREEN,   new Clear_screen(this));
        
    current = state_map.get(STATES.RESET);
    current.enter();
  }
  
  // == Private variables ==
  // Private collection of all the states
  private EnumMap<STATES, State> state_map;
  
  private State current = null;
  private Serial port = null;
  
  // private method to correctly switch state
  private void change_state(STATES next) {
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
  protected SM parent;
}

class Reset extends State {
  Reset(SM p){
    super(p);
  }
  
  public void enter(){
    println("Entered Reset state");
  }
  
  public void update(){
    println("Updating Reset state");
    parent.change_state(STATES.WAIT_FOR_READY);
  }
  
  public void leave(){
    println("Leaving Reset state");
  }
}

class Wait_for_ready extends State {
  Wait_for_ready(SM p){
    super(p);
  }
  
  public void enter(){
    println("Entered Wait_for_ready state");
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
