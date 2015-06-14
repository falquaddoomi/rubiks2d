/**
<p>
Click and drag to rotate a row or column. Dragging horizontally flips the row, vertically the column. Make the board uniform to advance.
</p>

<p>Pressing <b>'r'</b> resets the board at the cost of one level.</p>
*/

RubikSquare square;

boolean DRAW_AXES = false;
int reset_frames = 0;
int RESET_DURATION = 20;
float scale_val;
int level = 1;

void setup() {
  size(400,400,P3D);
  smooth();
  rectMode(CENTER);
  
  square = new RubikSquare((int)(level/3)+3, (int)(level/3)+3);
  scale_val = 250/max(square.rows, square.cols);
  randomize(level*1.5);
}

void keyReleased() {
  if (reset_frames > 0 || square.exit_frames > 0
  )
    return;

  if (key == 'r') {
    if (level > 1)
      level -= 1;
    reset_frames = RESET_DURATION; 
  }
  else if (key == 'p') {
    // victory!
    level += 1;
    square.exit_frames = EXIT_DURATION; 
  }
}

PVector mousePos = new PVector();
boolean dragging = false;

void mousePressed() {
  mousePos.set(mouseX, mouseY);
  dragging = true;
}

void mouseOut() {
  if (dragging)
    mouseReleased(); 
}

void mouseReleased() {
  // project starting pos into scene to determine square
  int tmx = (int)(mousePos.x - width/2)/scale_val + square.rows/2, tmy = (int)(mousePos.y - height/2)/scale_val + square.cols/2;
  int ttx = (int)floor(tmx);
  int tty = (int)floor(tmy);

  // use difference from current pos to determine row/col and rotation direction
  PVector curPos = new PVector(mouseX, mouseY);
  PVector displace = PVector.sub(mousePos, curPos);
  
  // basically just detects the direction of the drag to figure out if it's a row/col and in which direction to do the rotation
  float heading = (displace.heading() + PI)/PI;
  boolean isRow = (heading > 7.0/4.0 || heading < 1.0/4.0) || (heading > 3.0/4.0 && heading < 5.0/4.0);
  boolean clockwise = (isRow && (heading > 7.0/4.0 || heading < 1.0/4.0)) || (!isRow && (heading > 1.0/4.0 && heading < 3.0/4.0));

  square.requestPivot(new PivotMove((isRow)?tty:ttx, isRow, clockwise, false));
  dragging = false;
}

void draw() {
  background(0);

  // draw level indicator
  fill(255, 50);
  noStroke();
  for (int i = 0; i < level; i++) {
    rect(8 + 8*i, height-8, 5, 5); 
  }
  
  // debug axes
  if (DRAW_AXES) {
    pushStyle();
    strokeWeight(3);
    // x: red
    stroke(255, 0, 0);
    line(0, 0, 0, 10, 0, 0);
    // y: green
    stroke(0, 255, 0);
    line(0, 0, 0, 0, 10, 0);
    stroke(0, 0, 255);
    // z: blue
    line(0, 0, 0, 0, 0, 10);
    popStyle();
  }
  
  // display mouse-dragging reticule
  if (dragging) {
    int rad = dist(mouseX, mouseY, mousePos.x, mousePos.y)*0.3;
    noStroke();
    fill(12, 50, 100, 0.25);
    ellipse(mousePos.x, mousePos.y, rad, rad);
    fill(255, 0.25);
    ellipse(mousePos.x, mousePos.y, rad*2, rad*2);
  }
  
  // get on to the square itself
  pushMatrix();

  // move the coordinate system to the center of the viewport
  translate(width/2, height/2);
  
  // scale up b/c the square is in units of 1.0
  // we do this prior to drawing the square
  // so that the 'reset' animation is in the appropriate units
  scale(scale_val);
  
  // if we're resetting, perform an animation for that
  // this is also used for the exit sequence to advance to the next level
  if (reset_frames > 0) {
    float frac = 1.0 - (reset_frames/(float)(RESET_DURATION));
    // scale(-1.0 * (1.0 - frac));
    
    // split the reset duration into two intervals
    // 1) old square exiting from the bottom
    // 2) new square arriving from the top
    if (frac < 0.5)
      translate(0, frac * 8.0, 0);
    else
      translate(0, (1.0-frac) * -8.0, 0);
    
    if (reset_frames == RESET_DURATION/2) {
      // swap out the old square with a new one once it's offscreen
     square = new RubikSquare((int)(level/3)+3, (int)(level/3)+3);
     scale_val = 250/min(square.rows, square.cols);
     // randomize(level*1.5);
    }
    else if (reset_frames == 1) {
      // at our last frame, apply a series of random moves to the board to reset it
      randomize(level*1.5);
    }
  
    reset_frames -= 1;
  }

  // and finally draw the humble playing field
  square.draw();
  
  popMatrix();
}

// randomizes the board
void randomize(int pivots) {
  // int walk = (int)random(0, min(square.rows, square.cols)-1);
  boolean isRow;
  for (int i = 0; i < pivots; i++) {
    isRow = !isRow;
    
    // int pos = (isRow)?(int)random(0, square.rows):(int)random(0, square.cols);
    int pos = (isRow)?(int)random(0, square.rows-1):(int)random(0, square.cols-1);
    
    square.requestPivot(new PivotMove(pos, isRow, random(100) < 30, true));
  }
}
