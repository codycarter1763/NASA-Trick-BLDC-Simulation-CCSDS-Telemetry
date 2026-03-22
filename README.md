# NASA Trick BLDC Simulation With CCSDS Telemetry

# About
This repository builds on my NASA Trick simulation learning journey by combining a brushless DC motor simulation with a real hardware telemetry pipeline using the CCSDS Space Packet Protocol.

The simulation models the electrical and mechanical dynamics of a Castle Creations 2200KV brushless motor running in NASA's Trick simulation framework. Motor telemetry data — RPM, current, voltage, back-EMF, torque, and power — is packaged into CCSDS space packets and transmitted over USB to an STM32 Black Pill microcontroller, where it is decoded and displayed on an SSD1306 OLED display in real time.

The project ties together three distinct systems:

- **NASA Trick** — physics simulation and job scheduling
- **CCSDS Space Packet Protocol** — the same telemetry standard used on 
  real spacecraft
- **STM32 embedded firmware** — hardware receiving and displaying live 
  simulation data
# BLDC Trick Simulation

# CCSDS Space Packet Protocol

# Combining Trick With CCSDS 

# Setting Up

# Results
