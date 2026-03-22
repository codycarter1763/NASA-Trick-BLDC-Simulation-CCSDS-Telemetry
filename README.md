# NASA Trick BLDC Simulation With CCSDS Telemetry

# About
This repository builds on my NASA Trick simulation learning journey by combining a brushless DC motor simulation with a hardware telemetry pipeline using my implementation of the CCSDS Space Packet Protocol.

Using core electrical and mechanical equations of a brushless DC motor, including parameters of phase, back-EMF, torque contants, rotor inertia, and viscous damping, allows for a simulated physics model to be realized and analyzed. Then, the output data from the BLDC simulation is packaged into CCSDS space packets and transmitted over USB to an STM32 Black Pill microcontroller, where it is decoded and displayed on an OLED display. 

The project ties together three distinct systems:

- **NASA Trick Simulation** — physics simulation and job scheduling
- **CCSDS Space Packet Protocol** — the same telemetry standard used on 
  real spacecraft
- **STM32 Telemetry Display** — hardware receiving and displaying live 
  simulation data

As both the BLDC simulation and CCSDS Space Packet Protocol have been covered prior in my repositories, I will list them below for reference if more information is desired.


# BLDC Trick Simulation

# CCSDS Space Packet Protocol

# Combining Trick With CCSDS 

# Setting Up

# Results
