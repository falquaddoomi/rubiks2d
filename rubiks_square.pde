RubikSquare square;

boolean DRAW_AXES = false;
int reset_frames = 0;
int RESET_DURATION = 20;
float scale_val;

void setup() {
  size(400,400,P3D);
  smooth();
  rectMode(CENTER);
  
  square = new RubikSquare();
  scale_val = 250/min(RUBIK_ROWS, RUBIK_COLS);
  
  reset();
}

void keyReleased() {
  if (reset_frames > 0)
    return;

  if (key == 'r') {
    reset_frames = RESET_DURATION; 
  }
}

PVector mousePos = new PVector();
boolean clicking = false;

void mousePressed() {
  mousePos.set(mouseX, mouseY);
  clicking = true;
}

void mouseReleased() {
  // project starting pos into scene to determine square
  int tmx = (int)(mousePos.x - width/2)/scale_val, tmy = (int)(mousePos.y - height/2)/scale_val;
  int ttx = (int)constrain(floor(tmx  + floor(RUBIK_ROWS/2)), 0, RUBIK_ROWS-1);
  int tty = (int)constrain(floor(tmy + floor(RUBIK_COLS/2)), 0, RUBIK_COLS-1);

  // use difference from current pos to determine row/col and rotation direction
  PVector curPos = new PVector(mouseX, mouseY);
  PVector displace = PVector.sub(mousePos, curPos);
  
  float heading = (displace.heading() + PI)/PI;
  
  boolean isRow = (heading > 7.0/4.0 || heading < 1.0/4.0) || (heading > 3.0/4.0 && heading < 5.0/4.0);
  boolean clockwise = (isRow && (heading > 7.0/4.0 || heading < 1.0/4.0)) || (!isRow && (heading > 1.0/4.0 && heading < 3.0/4.0));

  square.requestPivot(new PivotMove((isRow)?tty:ttx, isRow, clockwise, false));
  clicking = false;
}

void draw() {
  background(0);
  
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
  
  if (clicking) {
    int rad = dist(mouseX, mouseY, mousePos.x, mousePos.y)*0.3;
    noStroke();
    fill(12, 30, 100, 0.25);
    ellipse(mousePos.x, mousePos.y, rad, rad);
    fill(255, 255, 255, 0.25);
    ellipse(mousePos.x, mousePos.y, rad*2, rad*2);
  }
  
  pushMatrix();

  translate(width/2, height/2);
  
  square.prescale();
  
  if (reset_frames > 0) {
    float frac = 1.0 - (reset_frames/(float)(RESET_DURATION));
    // scale(-1.0 * (1.0 - frac));
    
    if (frac < 0.5)
      translate(0, frac * 8.0, 0);
    else
      translate(0, (1.0-frac) * -8.0, 0);
    
    if (reset_frames == RESET_DURATION/2) {
     square = new RubikSquare();
    }
    else if (reset_frames == 1) {
      reset(5 + level*2);
    }
  
    reset_frames -= 1;
  }

  square.draw();
  popMatrix();
}

void reset(int pivots) {
  // int walk = (int)random(0, min(RUBIK_ROWS, RUBIK_COLS)-1);
  boolean isRow;
  for (int i = 0; i < pivots; i++) {
    isRow = random(100) < 30;
    
    // int pos = (isRow)?(int)random(0, RUBIK_ROWS):(int)random(0, RUBIK_COLS);
    int pos = (int)random(0, 3);
    
    square.requestPivot(new PivotMove(pos, isRow, random(100) < 30, true));
  }
}
