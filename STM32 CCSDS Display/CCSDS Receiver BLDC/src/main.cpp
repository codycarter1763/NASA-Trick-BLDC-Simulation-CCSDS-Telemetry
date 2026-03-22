/******************************************
 * CCSDS Space Packet Protocol Receiver
 * Author: Cody Carter
 * Date: March 2026
 * Version: 1.0.0
 * 
 * This firmware handles the data collection from a Trick BLDC simulation
 * sensor, the decoding of the space packet protocol header, and data transmission
 * via USB.
 * 
 * Made for STM32F411CE (Blackpill)
 ******************************************/

#include <Arduino.h>
#include <stdint.h>
#include <Wire.h>
#include "ssd1306.h"

float g_rpm = 0.0f;
float g_current = 0.0f;
float g_torque = 0.0f;
float g_backemf = 0.0f;
float g_power = 0.0f;
float g_voltage = 0.0f;

// Packet ID
#define version_Shift 13
#define packet_Type_Shift 12
#define secondary_Header_Flag_Shift 11
#define process_ID_Mask 0x07FF // Keeps lower 11 bits and clears everything else

// Sequence Control
#define sequence_Flag_Shift 14
#define sequence_CountName_Mask 0x3FFF // Keeps lower 14 bits and clears everything else

struct Primary_Header {
    uint16_t packet_ID; // Version num (3 bits) + type (1 bit) + secondary flag (1 bit) + process ID (11 bits)
    uint16_t sequence_Control; // Sequence flags (2 bits) + sequence count or name (14 bits)
    uint16_t data_Length; // Data length (14 bits)
};

// For use with BLDC
struct Secondary_Header { 
    uint16_t rpm;
    uint16_t current;
    uint16_t torque;
    uint16_t backemf;
    uint16_t power;
    uint16_t voltage;
} __attribute__((packed)); // Makes sure the header size is exactly 32 bits or 4 bytes

// Packed primary + secondary packet
struct Telemetry_Packet {
  Primary_Header primary;
  Secondary_Header secondary;
} __attribute__((packed));

void decodePacket(const Telemetry_Packet& packet) {
  uint8_t version =
    (packet.primary.packet_ID >> version_Shift) & 0x07;

  uint8_t packet_Type =
    (packet.primary.packet_ID >> packet_Type_Shift) & 0x1;


  uint8_t secondary_Header_Flag =
    (packet.primary.packet_ID >> secondary_Header_Flag_Shift) & 0x1;

  uint16_t process_ID = 
    packet.primary.packet_ID & process_ID_Mask;

  uint8_t sequence_Flags =
    (packet.primary.sequence_Control >> sequence_Flag_Shift) & 0x03;

  uint16_t sequence_CountName =
    packet.primary.sequence_Control & sequence_CountName_Mask;

    g_rpm     = (float)packet.secondary.rpm;
    g_current = (float)packet.secondary.current  / 100.0f;
    g_torque  = (float)packet.secondary.torque / 10000.0f;
    g_backemf = (float)packet.secondary.backemf / 1000.0f;
    g_power   = (float)packet.secondary.power    / 10.0f;
    g_voltage = (float)packet.secondary.voltage  / 10.0f;
}

bool receivePacket(Telemetry_Packet &packet) {
  static uint16_t expectedLen = 0;

  // Read length prefix
  if (expectedLen == 0) {
    if (Serial.available() >= sizeof(expectedLen)) {
      Serial.readBytes((uint8_t*)&expectedLen, sizeof(expectedLen));

      if (expectedLen != sizeof(Telemetry_Packet)) {
        Serial.printf("Bad length: %u\n", expectedLen);
        expectedLen = 0;
        Serial.flush();
        return false;
      }
    }
  }

  // Read packet
  if (expectedLen > 0 && Serial.available() >= expectedLen) {
    Serial.readBytes((uint8_t*)&packet, expectedLen);
    expectedLen = 0;
    return true;
  }

  return false;
}

void sendPacket(const Telemetry_Packet& packet) {
  uint16_t len = sizeof(Telemetry_Packet);

  Serial.write((uint8_t*)&len, sizeof(len));      // length prefix
  Serial.write((uint8_t*)&packet, len);           // CCSDS packet
}

void setup() {
  Serial.begin(115200);

  Wire.setSDA(PB7);
  Wire.setSCL(PB6);
  Wire.begin();        // PB7 SDA, PB6 SCL
  ssd1306_setFixedFont(ssd1306xled_font6x8);
  ssd1306_128x64_i2c_init();
  ssd1306_clearScreen();
}

void loop() {
    Telemetry_Packet packet;

    if (receivePacket(packet)) {
        decodePacket(packet);

        char rpm_str[12];
        char cur_str[12];
        char tor_str[12];
        char backemf_str[12];
        char pow_str[12];
        char volt_str[12];

        // dtostrf(value, min_width, decimal_places, buffer)
        dtostrf(g_rpm, 6, 0, rpm_str);
        dtostrf(g_current, 6, 2, cur_str);
        dtostrf(g_torque, 6, 4, tor_str);
        dtostrf(g_backemf, 6, 3, backemf_str);
        dtostrf(g_power, 6, 1, pow_str);
        dtostrf(g_voltage, 6, 1, volt_str);

        char line1[24];
        char line2[24];
        char line3[24];
        char line4[24];
        char line5[24];
        char line6[24];
        char line7[24];
        char line8[24];

        snprintf(line1, sizeof(line1), "Castle BLDC Trick Sim");
        snprintf(line2, sizeof(line2), "                 ");
        snprintf(line3, sizeof(line3), "RPM:       %s    ", rpm_str);
        snprintf(line4, sizeof(line4), "Current:   %s A  ", cur_str);
        snprintf(line5, sizeof(line5), "Torque:   %s N.M  ", tor_str);
        snprintf(line6, sizeof(line6), "Back EMF:  %s V  ", backemf_str);
        snprintf(line7, sizeof(line7), "Power:     %s W  ", pow_str);
        snprintf(line8, sizeof(line8), "Voltage:   %s V  ", volt_str);

        ssd1306_printFixed(0,  0, line1, STYLE_NORMAL);
        ssd1306_printFixed(0, 8, line2, STYLE_NORMAL);
        ssd1306_printFixed(0, 16, line3, STYLE_NORMAL);
        ssd1306_printFixed(0, 24, line4, STYLE_NORMAL);
        ssd1306_printFixed(0, 32, line5, STYLE_NORMAL);
        ssd1306_printFixed(0, 40, line6, STYLE_NORMAL);
        ssd1306_printFixed(0, 48, line7, STYLE_NORMAL);
        ssd1306_printFixed(0, 56, line8, STYLE_NORMAL);
    }
}