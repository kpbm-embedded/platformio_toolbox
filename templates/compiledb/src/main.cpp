// @NAME@ (compiledb template): the same file compiled three ways; compile_commands.json records each command line.
#ifdef ARDUINO
#include <Arduino.h>
void setup() { Serial.begin(115200); }
void loop() { Serial.println(millis()); delay(1000); }
#else
#include <cstdio>
int main() { std::puts("compiledb host build"); return 0; }
#endif
