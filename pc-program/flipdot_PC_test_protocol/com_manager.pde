
  
static enum Com_state{
  READY
}

class Com_manager
{
  Com_manager()
  {
  }
  
  public void update()
  {
  }
  
  public void pixel_off(int x, int y)
  {
    if(state != Com_state.READY)
    {
      return;
    }
  }
  
  public void pixel_on(int x, int y)
  {
  }
  
  public Com_state state;
  
}
