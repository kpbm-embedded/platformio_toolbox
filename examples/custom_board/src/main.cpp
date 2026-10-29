// custom_board: blink + clock report on the WeAct STM32H562RGT6 (board from boards/weact_h562rg.json).
#include <Arduino.h>
void setup() {
    Serial.begin(115200);
    pinMode(LED_PIN, OUTPUT);
}
void loop() {
    digitalWrite(LED_PIN, !digitalRead(LED_PIN));
    Serial.print("weact_h562 SystemCoreClock=");
    Serial.println(SystemCoreClock);
    delay(500);
}
