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

## Related Repositories

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/codycarter1763/NASA-Trick-Simulation-BLDC-Motor">
        <img src="https://github.com/user-attachments/assets/0f41a4d6-699f-4cef-ac3c-ed4590e83f26" width="420" />
      </a>
      <br />
      <b>NASA Trick BLDC Motor Simulation</b><br />
      <sup>Physics simulation of a Castle Creations 2200KV brushless motor using NASA Trick</sup>
    </td>
    <td align="center">
      <a href="https://github.com/codycarter1763/CCSDS-Space-Packet-Protocol-">
        <img src="https://github.com/user-attachments/assets/ea7a9c17-3e1a-4e09-bd56-f2d6e04dfd7d" width="420" />
      </a>
      <br />
      <b>CCSDS Space Packet Protocol Implementation</b><br />
      <sup>Implements CCSDS Space Packet Protocol on STM32, showcasing space-grade data handling</sup>
    </td>
  </tr>
</table>

# BLDC Trick Simulation
Mainly used a way for me to learn how to use Trick to model hardware, I chose the Castle Creations 2200Kv motor to be able to have a baseline for how close the simulation could match the real motor. Core electrical and mechanical equations of a brushless DC motor were implemented using C, with Trick handling job scheduling, intergration and derivation, inputs and outputs, and backend simulation setup. This allowed for me to quickly model the physics without having to worry about having to create a simulation from scratch for each design aspect.

In addition, I implemented a Tcl/Tk display that connects to Trick's variable server over TCP/IP that provides a user friendly way to change motor variables such as input voltage and load torque without having to manually change code. As well as provide a output interface to view the motor performance in real time.

<img width="599" height="838" alt="image" src="https://github.com/user-attachments/assets/faf88fc8-f7ab-4c23-8a19-90292dbd5cce" />

# CCSDS Space Packet Protocol

# Combining Trick With CCSDS 

# Setting Up

# Results
