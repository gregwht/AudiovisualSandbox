/**
 ===========================================
 ||                                       ||
 ||          AUDIOVISUAL SANDBOX          ||
 ||            Gregory White              ||
 ||                                       ||
 ===========================================
 
 Programming for Artists Term 1 Project
 IS71016A
 MA in Computational Arts
 Goldsmiths' College
 
 Many thanks to Tim Blackwell, Lior Ben Gai, and the rest of the MA Computational
 Arts students for the teaching, help and inspiration.
 
 
 Aim
 ---
 
 My intent was to explore basic audiovisual interaction using Processing. I wanted 
 to build a 'sandbox' of particles that react to a sine wave passing through the 
 centre of the screen. When the particles collide with the sine wave, they are to 
 bounce off of it. Consequently I have had to explore methods of collision detection 
 in this project.  
 
 Process
 -------
 First, a waveform is created using the Minim library. This wave is output both sonically,
 though the speakers, and visually, as a drawn animated waveform. It is worth noting that the
 width of the image is equal to the buffer size: 1024. Therefore, each pixel across the screen
 represents one sample.
 
 Two arrays of the particle class are also created: a white and red set. The white particles spawn 
 from the top of the screen, and the red from the bottom. This has been used to help differentiate
 the particles (since one large mass of particles can be difficult to observe), but also serves
 to help debugging: it becomes more apparent when one particle escapes to the other side of the
 waveform when it is a different colour.
 
 Then we begin checking for collision. If the particles collide with the sides of the screen, 
 they rebound off of it. In future implementations I would like to include some sort of physics,
 where there is a slight increase in speed immediately after bouncing off the wall, as would happen
 in real life. 
 
 Then we check for collisions against the waveform. First, we check if the particle is in the 'collision
 area' - the segment of the screen which the waveform oscillates in, and therefore where collisions 
 are possible. If this is true, then we take the particle's x position and find its equivalent sample;
 if xPos = 249, then we lookup sample 249 in the buffer. The value of this sample is then read (using 
 only the left audio channel for simplicity), and translated into a y position, matching where the 
 waveform is at that particular point on screen. 
 
 Now that we have both the x and y position of a part of the waveform, we can check if the particle is 
 colliding with it. We check within a range (called the 'margin'), so if the particle and waveform positions
 are within this range, we deem a collision to have occurred. This is because only checking if the two 
 values are exactly equal will mean we miss many collisions. 
 
 If a collision has occurred with a downward-moving white particle, we inverse the y speed so that it travels 
 upwards, back towards the top of the screen. Similarly if the particle is an upwards-moving red one, the y 
 speed is inversed so it travels downwards. If we were to inverse the y speed of an upwards-moving white 
 particle (or downwards-moving red particle) this would give us an undesired result and cause glitching, since
 we want the particles to rebound off the wave and back towards the side of the screen they spawned on.
 
 When collisions with the waveform occur, one of two samples is triggered (related to the particle's colour). 
 
 Once we determine a collision has occurred, we stop checking for collisions against the waveform. Once a 
 set period of time has passed (called 'delay'), checking resumes. This is to prevent the particles from
 hitting multiple times against the same part of the waveform, which could cause it to glitch to the other
 side.
 
 Comments
 --------
 This sketch can provide a number of different results depending on the amount and size of particles,
 as well as changing the amplitude, frequency, and shape of the waveform. Try playing around with 
 these features to see what happens!
 
 
 Evaluation
 ----------
 The code presents quite a good representation of one possible implementation of my initial concept, 
 but can definitely be refined and expanded. The main challenge was getting the particles to interact
 properly with the waveform. 
 
 Bugs: - Some particles still manage to escape to the other side of the waveform
 - Slower particles can pass through several cycles of the sine wave once they have collided with it,
 since collision is no longer being checked. Realistically the particles should continue to bounce
 off of the waveform, with a change in x direction, as well as y direction.
 
 Extensions: This project only scratches the surface of the overall 'audiovisual sandbox' concept. 
 There are many ways this project could be developed, including (but not limited to) the following: 
 
 - Using tangents to determine at what angle the particle hits the waveform, and changing direction
 accordingly
 - Including an adaptable collision area that grows and shrinks along with the waveform's amplitude
 - Adding forces/physics, so that after a collision the particle speeds up as energy is transferred
 to it. It would then return back to normal speed by simulating drag.
 - Adjust the margin and delay values so that they are dependent on the speed of the particle
 - Have particles be attracted to the waveform instead of rebounding off them, with a force of attraction
 proportional to the ampitude. It would be interesting to see if you could observe the different
 wave shapes, without drawing the wave, but just by looking at the movement of the particles
 - Enable more control over the waveform e.g. multiplying several sine waves together to create different
 timbres and visual patterns
 - A version could also be created that reacted to microphone input rather than a synthesised wave. If
 the microphone is stereo, you could even build a different layer of interactivity where blowing into
 the microphone from the left side causes the particles to scatter over to the right side of the screen,
 and vice versa
 
 **/

// ------------------------------------------------------------------------------------------

// NOTE: CODE INBETWEEN *** HAS BEEN COPIED FROM MINIM EXAMPLE "SYNTHESIZE SOUND"

// ------------------------------------------------------------------------------------------

// Import minim libraries
// ***
import ddf.minim.*;
import ddf.minim.ugens.*;

// Declare minim objects
Minim       minim; 
AudioOutput auOut; // Audio output
Oscil       wave;  // Oscillator 
AudioSample white; // Sample to play when white particles collide with wave
AudioSample red;   // Sample to play when red particles collide with wave
// ***


// Declare particle arrays
Particle[] whiteParticles;  // Array of white particles
Particle[] redParticles;    // Array of red particles
int particleNum = 1000;     // Number of particles in each array
int diam = 5;               // Size of each particle
int speed = 5;              // Max speed of each particle

// Declare miscellaneous variables
int minSampleVal = -125;  // Minimum value of a sample in the buffer
int maxSampleVal = 125;   // Maximum value of a sample in the buffer 

/**
 The max and min sample values were found using this code:
 
 for (int i = 0; i < auOut.bufferSize () - 1; i++) {
 println(auOut.left.get(i)*50);
 }
 
 ...where 'auOut.left' is an array of values for each sample in the buffer, which we can use 
 to determine each the y position of each sample in the sine wave
 
 **/

// ------------------------------------------------------------------------------------------
void setup() {

  // Set up envrionment (drawing using P2D to make use of OpenGL hardware)
  size(1024, 600, P2D);  // Using 1024 for screen width since the buffer size is 1024
  // Therefore 1 pixel = one sample of the buffer

  // Initilialise minim object/sound
  // ***
  minim = new Minim(this);
  auOut = minim.getLineOut();  // Use the getLineOut method of the Minim object to get an 
  // AudioOutput object

    wave = new Oscil(44, 2.5f, Waves.SINE);  // Create a sine wave oscillator, set to 440 Hz for a 
  // consistent pattern, and at 2.5 amplitude for a good size/volume. These settings have been picked
  // as they visibly present how my concept works, as well as where it needs refinement. 

  wave.patch(auOut);  // Patch the Oscil object to the AudioOutput object
  // ***
  // Load collision samples
  white = minim.loadSample("white.mp3", 1024);
  red = minim.loadSample("red.mp3", 1024);


  // Initialise particle arrays
  whiteParticles = new Particle[particleNum];  // whiteParticles spawn on top half of screen
  redParticles = new Particle[particleNum];    // redParticles spawn on bottom half of screen
  // Variables are: start x position, start y position, x speed, y speed, diameter, red fill 
  // value, green fill value, blue fill value;
  for (int i = 0; i < particleNum; i++) {
    whiteParticles[i] = new Particle(random(width), random(0 + diam, (height/2 + minSampleVal)), 
    random(-speed, speed), random(-speed, speed), diam, 255, 255, 255); // start height is between top of screen and top of collision area
    redParticles[i] = new Particle(random(width), random(height/2 + maxSampleVal, height - diam), 
    random(-speed, speed), random(-speed, speed), diam, 255, 0, 0); // start height is between bottom of screen and bottom of collision area
  }
}


// ------------------------------------------------------------------------------------------
void draw() {

  background(0);

  // showCollisionArea();  // Use this method to highlight the collision area
  strokeWaveform();  // Draws waveform

    // Update and display particle arrays (see Particle_class tab for details)
  for (int i = 0; i < particleNum; i++) {
    whiteParticles[i].update();
    redParticles[i].update();
    whiteParticles[i].display();
    redParticles[i].display();
  }
}

// ------------------------------------------------------------------------------------------
void showCollisionArea() {

  // Draws a rectangle around the area in which collisions can occur
  // Once a particle enters this area, we check if it is colliding against the wave

  noFill();
  stroke(255, 0, 0);
  rectMode(CENTER); 
  rect(512, 300, 1024, 250);
}


// ------------------------------------------------------------------------------------------
void strokeWaveform() {

  // ***
  stroke(255);
  strokeWeight(1);
  // Draw the oscillator waveform (we are using just the left channel)
  for (int i = 0; i < auOut.bufferSize () - 1; i++) {
    line(i, height/2 - auOut.left.get(i)*50, i+1, height/2 - auOut.left.get(i+1)*50 ); // *50 to make waveform more visible
  }
  // ***
}


// ------------------------------------------------------------------------------------------
void mouseMoved() {

  // This method adds mouse control
  // Un-comment one or both of the below

  // ***

  //  // Maps amplitude to mouseY value (collisions still only occur within the predefined collision area)
  //  float amp = map( mouseY, 0, height, 5, 0 );
  //  wave.setAmplitude( amp );
  //  // Future versions of this project could include an adaptable collision area that grows and shrinks
  //  // along with the waveform

  //  // Maps frequency to mouseX value
  //  float freq = map( mouseX, 0, width, 1, 440 );
  //  wave.setFrequency( freq );

  // ***
}


// ------------------------------------------------------------------------------------------
void keyPressed() { 

  // Use to change waveform shape between sine, triangle, saw, square, and pulse waves
  // The project was developed with the sine wave in mind, but different (though probably glitchy)
  // effects can be observed using different wave shapes.

  //***
  switch( key )
  {
  case '1': 
    wave.setWaveform( Waves.SINE );
    break;

  case '2':
    wave.setWaveform( Waves.TRIANGLE );
    break;

  case '3':
    wave.setWaveform( Waves.SAW );
    break;

  case '4':
    wave.setWaveform( Waves.SQUARE );
    break;

  case '5':
    wave.setWaveform( Waves.QUARTERPULSE );
    break;

  default: 
    break;
  }
}
// ***
// ------------------------------------------------------------------------------------------

