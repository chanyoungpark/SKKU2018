/*
  Arduino LED Example
  Date : 2018. March 29
  Name : Chan Young Park
*/

const unsigned int LED_PIN = 13;
const unsigned int PAUSE = 500;

void setup() {
  pinMode(LED_PIN, OUTPUT);
}

void loop() {
  digitalWrite(LED_PIN, HIGH);
  delay(PAUSE);
  digitalWrite(LED_PIN, LOW);
  delay(PAUSE);
}