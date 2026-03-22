#!/usr/bin/python3

import serial
import socket
import struct
import sys
import time
import os
import glob

def find_stm32_port():
    """Auto detect STM32 port — waits until device connects"""
    print("Waiting for STM32...")
    while True:
        # Check all possible serial ports
        ports = glob.glob('/dev/ttyACM*') + glob.glob('/dev/ttyUSB*')
        if ports:
            port = ports[0]
            print(f"STM32 found on {port}")
            return port
        time.sleep(0.5)

def get_trick_port():
    port_file = os.path.join(os.path.dirname(__file__), "trick_port.txt")
    attempts = 0
    while attempts < 40:
        try:
            with open(port_file, 'r') as f:
                port = int(f.read().strip())
                print(f"Found Trick port: {port}")
                return port
        except:
            print("Waiting for Trick to start...")
            attempts += 1
            time.sleep(1)
    print("Error: Could not find Trick port")
    sys.exit(1)

SERIAL_PORT = find_stm32_port() # Default when STM32 is connected
BAUD_RATE   = 115200
TRICK_HOST  = "localhost"
TRICK_PORT = get_trick_port()   

def Build_CCSDS_Packet(rpm, current, torque, back_emf, power, voltage):
    Packet_Version = 0b000
    Packet_Type = 0
    Secondary_Flag = 1
    APID = 2
    Sequence_Flag = 0b11
    Sequence_CountName = 0
    
    rpm_raw = int(rpm)
    current_raw = int(current * 100)
    torque_raw = int(torque * 10000)
    back_emf_raw = int(back_emf * 1000)
    power_raw = int(power * 10)
    voltage_raw = int(voltage * 10)

    Packet_ID = (
        ((Packet_Version & 0x7) << 13) |
        ((Packet_Type & 0x1) << 12) |
        ((Secondary_Flag & 0x1) << 11) |
        (APID & 0x07FF) 
    )

    Sequence_Control = (
        ((Sequence_Flag & 0x3) << 14) |
        (Sequence_CountName & 0x3FFF)
    )

    Secondary_Header = struct.pack("<HHHHHH",
        rpm_raw,
        current_raw,
        torque_raw,
        back_emf_raw,
        power_raw,
        voltage_raw
    )

    Data_Length = len(Secondary_Header) - 1
    Primary_Header = struct.pack("<HHH",
        Packet_ID,
        Sequence_Control,
        Data_Length
    )

    Telemetry_Packet = Primary_Header + Secondary_Header

    return Telemetry_Packet

# Serial connection to STM32
try:
    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout = 1)
    print(f"Connected to STM32 on {SERIAL_PORT}")

except serial.SerialException as e:
    print(f"Error: {e}")
    sys.exit(1)

# Connect to Trick simulator
try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((TRICK_HOST, TRICK_PORT))
    insock = sock.makefile("r")
except:
    print("Error: Can't connect to Trick server")
    sys.exit(1)

# Commands to request output variables from BLDC simulation
sock.send(b"trick.var_pause()\n")
sock.send(b"trick.var_ascii()\n")
sock.send(b"trick.var_add(\"bldc_sim.motor.rpm\")\n")
sock.send(b"trick.var_add(\"bldc_sim.motor.current\")\n")
sock.send(b"trick.var_add(\"bldc_sim.motor.torque\")\n")
sock.send(b"trick.var_add(\"bldc_sim.motor.back_emf\")\n")
sock.send(b"trick.var_add(\"bldc_sim.motor.power\")\n")
sock.send(b"trick.var_add(\"bldc_sim.motor.voltage\")\n")
sock.send(b"trick.var_cycle(0.1)\n")
sock.send(b"trick.var_unpause()\n")

# Loop to create CCSDS packet and transmit to STM32
while True:
    try:
        line = insock.readline()
        if line == ' ':
            break

        fields = line.strip().split("\t")
        if fields[0] == "0" and len(fields) == 7:
            rpm = float(fields[1])
            current = float(fields[2])
            torque = float(fields[3])
            backemf = float(fields[4])
            power = float(fields[5])
            voltage = float(fields[6])

            # Build CCSDS SSP
            packet = Build_CCSDS_Packet(rpm, current, torque, backemf, power, voltage)

            # Send via serial packet and length
            length = struct.pack("<H", len(packet))
            ser.write(length + packet)

            print(f"Sent CCSDS packet: RPM={rpm:.0f} "
                  f"I={current:.2f} T={torque:.4f}N.M V={voltage:.1f}V "
                  f"B_EMF={backemf:.3f}V P={power:.1f}W")
            
    except KeyboardInterrupt:
        print("Stopping transmission")
        break

    except Exception as e:
        print(f"Error: {e}")
        time.sleep(0.1)

ser.close()
sock.close()

    