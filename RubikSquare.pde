int RUBIK_ROWS = 4, RUBIK_COLS = 4;
float RUBIK_FACE_SIZE = 15.0;
int PIVOT_DURATION = 20;
float EXIT_DURATION = 200;

color RUBIK_FRONT_COLOR = #ff0000;
color RUBIK_BACK_COLOR = #ffffff;

class RubikSquare {
  PivotMove curmove = null;
  boolean faces[][] = new boolean[RUBIK_ROWS][RUBIK_COLS];
  ArrayList<PivotMove> pending_moves = new ArrayList<PivotMove>();
  
  int offx = RUBIK_ROWS/2, offy = RUBIK_COLS/2;
  float scale_factor = 1.1;
  
  int exit_frames = 0;
  
  RubikSquare() {
    for (int i = 0; i < RUBIK_ROWS; i++) {
      for (int j = 0; j < RUBIK_COLS; j++) {
        faces[i][j] = false;
      }
    }
  }
  
  void prescale() {
    scale(scale_val);
  }
  
  void draw() {
    pushMatrix();

    stroke(100, 10, 10);
    strokeWeight(5000.0);
    fill(255, 25, 0);
    
    // STEP 1. draw non-animating squares

    for (int i = 0; i < RUBIK_ROWS; i++) {
      for (int j = 0; j < RUBIK_COLS; j++) {
        // don't render this cell if it's part of a pivoting row or column
        if (curmove != null &&
            ( ( curmove.isRow && i == curmove.id) ||
              (!curmove.isRow && j == curmove.id) ) ) {
              continue;
        }

        pushMatrix();
        tileTranslate(i, j);
        // draw the cube at i, j
        drawFace(faces[i][j]);
        popMatrix();
      }
    }
    
    // STEP 2. process input/animate current choice
    
    if (pending_moves.size() > 0 && curmove == null) {
      // process the input queue if we're not busy
      curmove = pending_moves.remove(0);
    }
    else if (curmove != null) {
      // otherwise animate the pivot
      drawPivoting(); 
    }
    
    // if we're in an exit sequence, animate that
    if (exit_frames > 0) {
      float exit_frac = 1.0 - exit_frames/(float)EXIT_DURATION;
      scale_factor = 1.1 + exit_frac*3.0;
      exit_frames -= 1;
    }
    
    popMatrix();
  }
  
  void drawPivoting(boolean auto) {
    if (curmove == null)
      return;
      
    if (curmove.frames >= 0) {
      // STEP 1a: draw the row/col that's pivoting
      float angle = (1.0 - (curmove.frames/(float)PIVOT_DURATION)) * PI * (curmove.clockwise?1.0:-1.0);
      
      pushMatrix();
      
      if (!curmove.isRow) {
        rotateX(angle);
        // draw the selected column flipping over
        int j = curmove.id;
        for (int i = 0; i < RUBIK_ROWS; i++) {
          pushMatrix();
          tileTranslate(i, j);
          // draw the cube at i, j
          drawFace(faces[i][j]);
          popMatrix();
        }
      }
      else {
        rotateY(angle);
        // draw the selected row flipping over
        int i = curmove.id;
        for (int j = 0; j < RUBIK_COLS; j++) {
          pushMatrix();
          tileTranslate(i, j);
          // draw the cube at i, j
          drawFace(faces[i][j]);
          popMatrix();
        }
        
        popMatrix();
      }
      
      // STEP 1b: and contine the pivot animation next frame
      curmove.frames -= 1;
    }
    
    if (curmove.frames <= 0) {
      // STEP 2a: flip the faces for the row/col that's selected
      
      if (!curmove.isRow) {
        // strange, but rotating a row means reversing each element in the columns of that row
        // ergo, we iterate over rows when we're rotating a column
        boolean items[] = new boolean[RUBIK_ROWS];
        for (int i = 0; i < RUBIK_ROWS; i++) { items[i] = !faces[i][curmove.id]; }
        items = reverse(items);
        for (int i = 0; i < RUBIK_ROWS; i++) { faces[i][curmove.id] = items[i]; }
      }
      else {
        boolean items[] = new boolean[RUBIK_COLS];
        for (int i = 0; i < RUBIK_COLS; i++) { items[i] = !faces[curmove.id][i]; }
        items = reverse(items);
        for (int i = 0; i < RUBIK_COLS; i++) { faces[curmove.id][i] = items[i]; }
      }
    
      // check for victory
      if (!curmove.auto)
        checkVictory();
      
      // STEP 2b: and stop the pivot
      curmove = null;
    }
  }
  
  void requestPivot(PivotMove p) {
    // don't allow moves if we're in an exit sequence
    
    if (exit_frames > 0)
      return;
      
    // push the requested move onto the stack
    pending_moves.add(p); 
  }
  
  void drawFace(boolean flipped) {
    pushMatrix();
    
    if (exit_frames > 0) {
      float exit_frac = 1.0 - pow(exit_frames,1.1)/(float)EXIT_DURATION;
      rotateX(exit_frac*0.2);
      rotateY(exit_frac*0.3);
      rotateZ(exit_frac*3.2);
      
      if (exit_frames == EXIT_DURATION/2)
        reset_frames = RESET_DURATION;
    }

    // top square
    if (!flipped) { fill(RUBIK_FRONT_COLOR); }
    else { fill(RUBIK_BACK_COLOR); }
    rect(0, 0, 1, 1);
    translate(0, 0, -0.01);
      
    // bottom square
    if (flipped) { fill(RUBIK_FRONT_COLOR); }
    else { fill(RUBIK_BACK_COLOR); }
    rect(0, 0, 1, 1);
    
    popMatrix();
  }
  
  void tileTranslate(int i, int j) {
    translate((j-offx + 0.5)*scale_factor, (i-offy + 0.5)*scale_factor); 
  }
  
  boolean checkVictory() {
    // and check for victory
    int reds = 0, whites = 0;
    for (int i = 0; i < RUBIK_ROWS; i++) {
      for (int j = 0; j < RUBIK_COLS; j++) {
        if (faces[i][j]) { reds += 1; } else { whites += 1; }
      }
    }
    
    if (reds == RUBIK_ROWS*RUBIK_COLS || whites == RUBIK_ROWS*RUBIK_COLS) {
      // victory!
      exit_frames = EXIT_DURATION;
      return true;
    }
    
    return false;
  }
}

class PivotMove {
  int id;
  boolean isRow;
  boolean clockwise;
  int frames;
  boolean auto;
  
 PivotMove(int id, boolean isRow, boolean clockwise, boolean auto) {
   this.id = constrain(id, 0, (isRow)?RUBIK_ROWS:RUBIK_COLS);
   this.isRow = isRow;
   this.clockwise = clockwise;
   this.frames = PIVOT_DURATION;
   this.auto = auto;
 } 
}

