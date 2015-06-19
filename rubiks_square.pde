/**
<p>
Click and drag to rotate a row or column. Dragging horizontally flips the row, vertically the column. (Not dragging will rotate the clicked row.)
</p>

<p>Make the board uniform to advance.</p>

<p>(Both the grid size and number of initial turns increase as you complete each level. In later levels, all but the last 3 turns will be pre-applied.)</p>

<p><b>Controls:</b>
<ul>
  <li><b>SHIFT:</b> rotate the clicked cell's column</li>
  <li><b>r:</b> reset the board at the cost of one level.</li>
</ul>
</p>

<p style="font-size: 10px;"><b>NOTE:</b> on occasion the board will be created solved; just un-solve and re-solve it and it'll continue. Also note that what constitutes a good versus bad series of pivots to generate a hard board is still an open question.<p>
*/

/* @pjs font="atari_full.ttf"; */

RubikSquare square;

int reset_frames = 0;
int RESET_DURATION = 20;
float scale_val;
int level = 1;

PFont atari;

void setup() {
  size(400,400,P3D);
  smooth();
  rectMode(CENTER);
  // ortho(0, width, 0, height, -10, 10);
  
  atari = loadFont("atari_full.ttf");
  
  square = new RubikSquare((int)(level/3)+3, (int)(level/3)+3, level*1.5);
  scale_val = 250/max(square.rows, square.cols);
}

// ====================================
// === INPUT HANDLING
// ====================================

PVector mousePos = new PVector();
boolean dragging = false;
boolean mod_pressed = false;

void keyPressed() {
  if (key == CODED && keyCode == SHIFT)
    mod_pressed = true;
}

void keyReleased() {
  if (key == CODED && keyCode == SHIFT)
    mod_pressed = false;
    
  if (reset_frames > 0 || square.exit_frames > 0)
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
  float displace_mag = displace.mag();
  
  // basically just detects the direction of the drag to figure out if it's a row/col and in which direction to do the rotation
  float heading = (displace.heading() + PI)/PI;
  boolean isRow = (displace_mag <= 2) || (heading > 7.0/4.0 || heading < 1.0/4.0) || (heading > 3.0/4.0 && heading < 5.0/4.0);
  boolean clockwise = (displace_mag <= 2) || (isRow && (heading > 7.0/4.0 || heading < 1.0/4.0)) || (!isRow && (heading > 1.0/4.0 && heading < 3.0/4.0));
  
  // quick hack to allow for clicks w/the mod key pressed to always rotate the col
  if (mod_pressed) {
    isRow = false;
    clockwise = false;
  }

  square.requestPivot(new PivotMove((isRow)?tty:ttx, isRow, clockwise, false, 20));
  dragging = false;
}

// ====================================
// === MAIN LOOP
// ====================================

void draw() {
  background(0);

  // draw level indicator
  colorMode(HSB);
  noStroke();
  for (int i = 0; i < level; i++) {
    fill(i*47 % 255, 100, 255);
    rect(8 + 8*i, height-8, 5, 5); 
  }
  colorMode(RGB);
  
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
  translate(width/2, height/2, 0);
  
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
     square = new RubikSquare((int)(level/3)+3, (int)(level/3)+3, level*1.5);
     square.paused = true;
     scale_val = 250/min(square.rows, square.cols);
    }
    else if (reset_frames == 1) {
      // unfreeze the square to allow it to process its moves
      square.paused = false;
    }
  
    reset_frames -= 1;
  }

  // and finally draw the humble playing field
  square.draw();
  
  popMatrix();
}

