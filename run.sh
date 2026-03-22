#!/bin/bash
#=========================================================
# BLDC Motor Simulation Launch Script
#=========================================================
SIM_DIR="$HOME/trick_sims/SIM_BLDC_Motor"
SIM_EXE=$(ls $SIM_DIR/S_main_*.exe 2>/dev/null | head -1)

# ── Check sim is built ──
if [ -z "$SIM_EXE" ]; then
    echo "Error: No S_main_*.exe found. Run trick-CP first."
    exit 1
fi

# ── Check for STM32 or use virtual ports ──
if [ -e "/dev/ttyACM0" ]; then
    echo "STM32 detected on /dev/ttyACM0"
    SERIAL_PORT="/dev/ttyACM0"
    SOCAT_PID=""
else
    echo "No STM32 found — starting virtual serial ports..."
    socat -d -d pty,raw,echo=0 pty,raw,echo=0 2>/tmp/socat.log &
    SOCAT_PID=$!
    sleep 1
    PTY1=$(grep "PTY is" /tmp/socat.log | sed -n '1p' | awk '{print $NF}')
    PTY2=$(grep "PTY is" /tmp/socat.log | sed -n '2p' | awk '{print $NF}')
    echo "Virtual ports: $PTY1 <-> $PTY2"
    SERIAL_PORT=$PTY1
    cat $PTY2 &
    CAT_PID=$!
fi

# ── Start sim ──
echo "Starting simulation..."
cd $SIM_DIR
$SIM_EXE RUN_test/input.py &
SIM_PID=$!
sleep 2

# ── Start bridge ──
echo "Starting bridge on $SERIAL_PORT..."
python3 $SIM_DIR/Trick_To_STM_Bridge.py $SERIAL_PORT &
BRIDGE_PID=$!

echo "================================="
echo "  All processes started"
echo "  Serial port: $SERIAL_PORT"
echo "  Sim PID:     $SIM_PID"
echo "  Bridge PID:  $BRIDGE_PID"
echo "  Press Ctrl+C to stop all"
echo "================================="

# ── Cleanup on Ctrl+C ──
trap "echo 'Stopping...'; kill $SIM_PID $BRIDGE_PID $SOCAT_PID $CAT_PID 2>/dev/null; exit" SIGINT SIGTERM

wait
