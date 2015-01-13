// Declare Particle class
class Particle {

  // Declare Particle variables
  float xPos, yPos, xSpeed, ySpeed, diam, fillR, fillG, fillB;
  int margin = 10;           // The amount of room for error when checking for collision  
  int collisionTime;         // Time at which collision occurs
  boolean collCheck = true;  // Whether or not the program is checking for collisions
  boolean collision = false; // When a collision occurs, this momentarily turns true
  float delay = 300;         // Number of milliseconds which collision check is delayed for
                             // This could be improved by making it related to the speed of
                             // the particle: a higher speed would require a smaller delay,
                             // and vice versa.

  // I have started to implement physics in this project, so that when a particle is hit
  // by the waveform, the particle speeds up for a short amount of time, giving the impression
  // that some of the energy has transferred from the sine wave to the particle.  
  // These two variables determine the factor by which particles speed up and slow down again:  

  // float bounce = 1.3; // Factor by which particles speed up when hit
  // float damp = 0.7; // Dampening factor 


  // ------------------------------------------------------------------------------------------
  // Create particle constructor
  Particle(float tempX, float tempY, float tempXSpeed, float tempYSpeed, int tempDiam, int tempFillR, int tempFillG, int tempFillB) {
    xPos = tempX;
    yPos = tempY;
    xSpeed = tempXSpeed;
    ySpeed = tempYSpeed;
    diam = tempDiam;
    fillR = tempFillR;
    fillG = tempFillG;
    fillB = tempFillB;
  }


  // ------------------------------------------------------------------------------------------
  // Create method to draw particle
  void display() {
    fill(fillR, fillG, fillB);
    noStroke();
    ellipse(xPos, yPos, diam, diam);
  }

  // Create method to update particle position
  void update() {

    // Move particles
    xPos += xSpeed;
    yPos += ySpeed;

    // When a particle collides with the side of the screen (taking into account its radius), make it
    // bounce off
    if (xPos >= width - diam/2 || xPos <= 0 + diam/2) {
      xSpeed *= -1;
    }
    if (yPos >= height - diam/2 || yPos <= 0 + diam/2) {
      ySpeed *= -1;
    }

    // Checking for collision against the waveform
    if (collCheck == true) {  // collCheck is true by default, but becomes false for a short period of 
      // time after a collision has occurred, to prevent repeat collisions
      // If particle is within the collision area...
      if (yPos >= (height/2 - 125) && yPos <= (height/2 + 125)) {  // 125 being the max sine y position
        // ...check against wavefom:

        // 1. Find which of the 1024 samples the particle's x position is equivalent to   
        int samplePos = int ((1.0*(xPos/width))*1024);

        // 2. Get the value of this equivalent sample
        if (samplePos > -1 && samplePos < 1024) {  // only look within the range of 0-1024
          float sampleVal = auOut.left.get(samplePos); // again, only using the left audio channel

          // 3. Translate this sample value into a y position value, within the collision area 
          // (remember to scale by *50 as before)  
          float waveY = height/2 - sampleVal*50;  

          // 4. If waveY and y pos are equal or within a certain range, collision occurs
          if (yPos >= waveY - margin && yPos <= waveY + margin) {
            // If particle is white and travelling downwards, then inverse its ySpeed
            if (fillR == 255 && fillG == 255 && fillB == 255 && ySpeed >= 0) {
              ySpeed *= -1;
            }
            // If particle is red and travelling upwards, then inverse its ySpeed  
            if (fillR == 255 && fillG == 0 && fillB == 0 && ySpeed <= 0) {
              ySpeed *= -1;
            }
            collision = true;          // collision has occurred
            collCheck = false;         // stop checking for collisions
            collisionTime = millis();  // record the time at which the collision occurred

            // If particle is white, trigger the white sample
            if (fillR == 255 && fillG == 255 && fillB == 255) {
              white.trigger();
            }
            // If particle is red, trigger the red sample
            if (fillR == 255 && fillG == 0 && fillB == 0) {
              red.trigger();
            }
            // This commented section is my aforementioned attempt to implement 
            // the physics of increasing and decreasing the particle's speed
            // after collision:
            //            // Store particle's default speed
            //            float prevX = xSpeed;
            //            float prevY = ySpeed; 
            //            // Increase speed
            //            xSpeed *= bounce;
            //            ySpeed *= bounce;
            //            // Decrease speed back to previous speed
            // for (float i = ySpeed; i == prevY; i--){
              //   xSpeed *= damp;
              //   ySpeed *= damp;
            // }
          }
        }
      }
    }

    // 5. When collision has occured, wait for a moment before resuming collision check, to 
    // prevent glitching and repeat collisions on the same part of the waveform
    if (collision == true) {
      int elapsedTime = millis() - collisionTime;  // Note the time since collision occurred
      if (elapsedTime > delay) {  // Once elapsed time is greater than delay, resume checking
                                  // for collisions 
        collCheck = true;
      }
    }
  }
}
// ------------------------------------------------------------------------------------------

