import processing.serial.*;

Serial arduino;

final int PADDLE_WIDTH = 60;
final int PADDLE_HEIGHT = 15;
final int BALL_RADIUS = 8;
final int BALL_DIAMETER = BALL_RADIUS * 2;
final int MAX_VELOCITY = 8;
final int MARGIN = 10;
final int POINT_LIMIT = 5;

int px, py;
int vx, vy;
int paddlePositions[] = {150, 150};
int playerPoints[] = {0, 0};

boolean isGamePaused = true;

void setup() {
  size(500, 700);
  noCursor();
  initBall();
  arduino = new Serial(this, Serial.list()[3], 115200);
}

void draw() {
  background(0);
  stroke(255);

  if (someoneWon()) {
    printWinMessage();
  } else {
    displayPlayerInfo();
    updateGame();
    drawBall();
    drawPaddles();
    handleKeyboardEvents();
  }
}

void initBall() {
  int direction[] = {-1, 1};
  px = width / 2;
  py = height / 2;
  vx = int(random(-MAX_VELOCITY, MAX_VELOCITY));
  vy = 2 * direction[int(random(0, 2))];
}

void displayPlayerInfo() {
  fill(128);
  textSize(14);
  text("Player 1", 10, 20);
  textSize(20);
  text(playerPoints[0], width - 20, 20);
  textSize(14);
  text("Player 2", 10, height - 15);
  textSize(20);
  text(playerPoints[1], width - 20, height - 15);
}

void drawBall() {
  strokeWeight(1);
  fill(128, 0, 0);
  ellipse(px, py, BALL_DIAMETER, BALL_DIAMETER);
}

void drawPaddles() {
  drawPaddleFirst();
  drawPaddleSecond();
}

void drawPaddleFirst() {
  int x = paddlePositions[0] - PADDLE_WIDTH / 2;
  int y = height - 25;
  drawPaddle(x, y);
}

void drawPaddleSecond() {
  int x = paddlePositions[1] - PADDLE_WIDTH/2;
  int y = 15;
  drawPaddle(x, y);
}

void drawPaddle(int x, int y) {
  strokeWeight(1);
  fill(128);
  rect(x, y, 60, 15);
}

void handleKeyboardEvents() {
  if (keyPressed) {
    if (key == 'b') {
      paddlePositions[0] += 3;
    } else if (key == 'v') {
      paddlePositions[0] -= 3;
    }

    if (key == 's') {
      paddlePositions[1] += 3;
    } else if (key == 'a') {
      paddlePositions[1] -= 3;
    }

    if (key == 'p') {
      isGamePaused = false;
    }
  }

  preservePaddlesInGameBoard();
}

void printWinMessage() {
  fill(225);
  textSize(36);
  textAlign(CENTER);
  text("Player " + (playerPoints[1] > playerPoints[0] ? "2" : "1") + " wins", width/2, height*2/3);
  text(playerPoints[0] + " : " + playerPoints[1], width / 2, height * 0.8);
}

void updateGame() {
  if (ballDroppedOffBottom()) {
    initBall();
    playerPoints[0]++;
    delay(500);
  } else if (ballDroppedOffTop()) {
    initBall();
    playerPoints[1]++;
    delay(500);
  } else if (!isGamePaused) {
    checkWallCollision();
    checkPaddleCollision();

    px += vx;
    py += vy;
  }
}

boolean someoneWon() {
  return playerPoints[0] >= POINT_LIMIT || playerPoints[1] >= POINT_LIMIT;
}

boolean ballDroppedOffBottom() {
  return py + vy > height - BALL_RADIUS;
}

boolean ballDroppedOffTop() {
  return py + vy - BALL_RADIUS <= 0;
}

void checkWallCollision() {
  if (px + vx < BALL_RADIUS || px + vx > width - BALL_RADIUS)
    vx = -vx;

  if (py + vy < BALL_RADIUS || py + vy > height - BALL_RADIUS)
    vy = -vy;
}

void checkPaddleCollision() {
  final int firstPaddlePosition = paddlePositions[0];
  final int secondPaddlePosition = paddlePositions[1];
  if (hasCollisionWithFirstPaddle(firstPaddlePosition)) {
    vy = -vy;
    vx = int(
      map(
      px - firstPaddlePosition, 
      -(PADDLE_WIDTH/2), 
      PADDLE_WIDTH/2, 
      -MAX_VELOCITY, 
      MAX_VELOCITY
      )
      );
  } else if (hasCollisionWithSeconPaddle(secondPaddlePosition)) {
    vy = -vy;
    vx = int(
      map(
      px - secondPaddlePosition, 
      -(PADDLE_WIDTH/2), 
      PADDLE_WIDTH/2, 
      -MAX_VELOCITY, 
      MAX_VELOCITY
      )
      );
  }
}

boolean hasCollisionWithFirstPaddle(int cx) {
  return py+vy >= height - (PADDLE_HEIGHT + MARGIN + 6) &&
    px >= cx - PADDLE_WIDTH/2 && px <= cx + PADDLE_WIDTH/2;
}

boolean hasCollisionWithSeconPaddle(int cx) {
  return py + vy <= 0 + (PADDLE_HEIGHT + MARGIN + 6) &&
    px >= cx - PADDLE_WIDTH/2 && px <= cx + PADDLE_WIDTH/2;
}

int parseMessage(String msg, String replacement) {
  return int(msg.replace(replacement, "").trim());
}

void serialEvent(Serial p) {
  String message = arduino.readStringUntil(13);

  if (message != null) {
    println(message);
    if (message.contains("START")) {
      isGamePaused = false;
    }

    if (message.contains("RESET")) {
      playerPoints[0] = 0;
      playerPoints[1] = 0;
      isGamePaused = true;
      initBall();
    }

    if (message.contains("LEFT")) {
      smoothMovement(0, parseMessage(message, "LEFT"));
    }

    if (message.contains("RIGHT")) {
      smoothMovement(1, parseMessage(message, "RIGHT"));
    }

    preservePaddlesInGameBoard();
  }
}

void smoothMovement(int paddleIndex, int newValue) {
  int oldValue = paddlePositions[paddleIndex];
  if (newValue > oldValue) {
    for (int i = oldValue; i <= newValue; i++) {
      paddlePositions[paddleIndex] = i;
    }
  } else {
    for (int i = oldValue; i >= newValue; i--) {
      paddlePositions[paddleIndex] = i;
    }
  }
}

void preservePaddlesInGameBoard() {
  for (int i = 0; i < 2; i++) {
    if (paddlePositions[i] > width - (PADDLE_WIDTH / 2)) {
      paddlePositions[i] = width - (PADDLE_WIDTH / 2);
    }

    if (paddlePositions[i] < (PADDLE_WIDTH / 2)) {
      paddlePositions[i] = (PADDLE_WIDTH / 2);
    }
  }
}
