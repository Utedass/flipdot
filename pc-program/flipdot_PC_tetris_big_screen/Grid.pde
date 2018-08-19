class Grid 
{
  int x, y;
  int myWidth, myHeight;
  int rows, cols;
  int[][] colors;
  ArrayList<Integer> clearedRows = new ArrayList<Integer>();
  int animateCount = -1;

  Grid(int x, int y, int w, int h, int rows, int cols) {
    this.x = x;
    this.y = y;
    myWidth = w;
    myHeight = h;
    this.rows = rows;
    this.cols = cols;
    colors = new int[cols][rows];
    for (int i = 0; i < cols; ++i)
      for (int j = 0; j < rows; ++j)
        colors[i][j] = 0;
  }

  void clear() {
    for (int i = 0; i < cols; ++i)
      for (int j = 0; j < rows; ++j)
        colors[i][j] = 0;
  }

  void draw() 
  {
    stroke(255);
    strokeWeight(1);
    //rect(x, y, myWidth, myHeight);
    for (int i = 0; i < cols; ++i)
      for (int j = 0; j < rows; ++j)
        fillSquare(i, j, colors[i][j]);

    final int speed = 15;

    if (animateCount >= 0)
    {
      if (/* myInterval >= 0 && */ animateCount <= speed*1) 
      {
        for (int row : clearedRows)
        {
          for (int i = 0; i < cols; ++i)
          {
            fillSquare(i, row, color(0, 0, 0));
          }
        }
        animateCount++;
      } 
      else if (/* myInterval >= 3 && */ animateCount <= speed*2) 
      {
        for (int row : clearedRows)
        {
          for (int i = 0; i < cols; ++i)
          {
            fillSquare(i, row, color(0, 255, 0));
          }
        }
        animateCount++;
      } 
      else if (/* myInterval >= 6 && */ animateCount <= speed*3) 
      {
        animateCount = -1;
        eraseCleared();
        loadNext();
      } 
      else 
      {
        animateCount++;
      }
    }
  }

  void fillSquare(int col, int row, color c) {
    if (col < 0 || col >= cols || row < 0 || row >= rows)
      return;
    noStroke();
    fill(c);
    rect(x + col*20, y + row*20, 20, 20);
    //rect(x + col, y + row, 20, 20);
  }

  void outlineSquare(int col, int row) {
    if (col < 0 || col >= cols || row < 0 || row >= rows)
      return;
    noFill();
    stroke(255);
    strokeWeight(2);
    rect(x + col*(myWidth/cols), y + row*(myHeight/rows), myWidth/cols, myHeight/rows);
  }

  void endTurn() {
    for (int i = 0; i < curr.shape.matrix.length; ++i)
    {
      for (int j = 0; j < curr.shape.matrix.length; ++j)
      {
        if (curr.shape.matrix[i][j] && j + curr.y >= 0) 
        {
          colors[i + curr.x][j + curr.y] = curr.getColor();
        }
      }
    }

    if (checkLines()) 
    {
      curr = null;
      animateCount = 0;
    } else
    {
      loadNext();
    }
  }

  boolean checkLines() {
    clearedRows.clear();
    for (int j = 0; j < rows; ++j) {
      int count = 0;
      for (int i = 0; i < cols; ++i)
        if (isOccupied(i, j))
          count++;
      if (count >= cols)
        clearedRows.add(j);
    }
    if (clearedRows.isEmpty())
      return false;

    if (lines/10 < (lines + clearedRows.size())/10) {
      level++;
      timer -= SPEED_DECREASE;
    }
    lines += clearedRows.size();
    score += (1 << clearedRows.size() - 1)*100;
    return true;
  }

  void eraseCleared() {
    for (int row : clearedRows) 
    {
      for (int j = row - 1; j > 0; --j) 
      {
        int[] rowCopy = new int[cols];
        for (int i = 0; i < cols; ++i)
          rowCopy[i] = colors[i][j];
        for (int i = 0; i < cols; ++i)
          colors[i][j + 1] = rowCopy[i];
      }
    }
  }

  boolean isOccupied(int x, int y) {
    if (y < 0 && x < cols && x >= 0) // allow movement/flipping to spaces above the board
      return false;
    return (x >= cols || x < 0 || y >= rows || colors[x][y] != 0);
  }
}