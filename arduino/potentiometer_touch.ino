// INPUT: Potentiometer should be connected to 5V and GND
int potPin = A0;    // Potentiometer output connected to analog pin 0
int potVal = 0;     // Variable to store the input from the potentiometer

int LATCH    = 1;   // Switch to change from momentary to latch mode
int touching = 0;   // Bool to identify the continuity of the touch
int state    = LOW; // Current state of the latch/momentary switch
int touchPin = 2;   // Touch sensor output connected to digital pin 2
int touchVal = 0;   // Variable to store the input from the touch sensor

int DEBUG = 0;      // Switch to enable debugging mode

// Put your setup code here, to run once
void setup() {

  // Set touch sensor pin to input mode
  pinMode(touchPin, INPUT);

   
  Serial.begin(9600);  
  
}

// Put your main code here, to run repeatedly
void loop() {

  potVal   = analogRead(potPin);    // Read the potentiometer value at the input pin
  touchVal = digitalRead(touchPin); // Read Touch sensor signal

  // If it is momentary read the current state and store it
  if (!LATCH)
    state = touchVal;

  else {
    if (touchVal && !touching) {
      state    = !state;
      touching = 1;
    }

    else if (!touchVal)
      touching = 0;
  }

  if(!DEBUG){
    Serial.print(potVal);
    Serial.print(state == HIGH ? "H" : "L");
  }


  // Print debug info
  if (DEBUG) {
    Serial.print("\n\n");
    Serial.print("The Pot: ");
    Serial.print(potVal);
    Serial.print("\n");

    Serial.print("Touch: ");
    Serial.print(state == HIGH ? "HIGH" : "LOW");
    Serial.print("\n\n");
  }

  delay(20);
}
