int LEDc = 2;

#define MAX 4
#define DEADZONE 80

void setup() {
  Serial.begin(9600);
}

void loop() {
  int sensorValue = analogRead(A0); 
  int voltage = (sensorValue - DEADZONE)/MAX;
  if(voltage < 0){
    voltage = 0;
  
  }
  Serial.print(voltage);
  Serial.print("a");
}