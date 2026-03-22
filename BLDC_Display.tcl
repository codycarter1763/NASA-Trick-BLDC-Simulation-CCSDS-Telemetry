#!/usr/bin/env wish

# Force kill on window close
proc force_exit {} {
    catch {exec kill [pid]}
}

bind . <Destroy> { force_exit }
wm protocol . WM_DELETE_WINDOW { force_exit }

# ─────────────────────────────────────────────
# 1.0 Get port from command line
# ─────────────────────────────────────────────
if {$argc != 1} {
    puts "Error: BLDC_DISPLAY.tcl <port_number>"
    exit
}
set port [lindex $argv 0]

# ─────────────────────────────────────────────
# 2.0 Sim path — portable
# ─────────────────────────────────────────────
set sim_dir [file normalize [file dirname [info script]]]
set sim_exe_list [glob -nocomplain $sim_dir/S_main_*.exe]
if {[llength $sim_exe_list] == 0} {
    puts "Error: No S_main_*.exe found in $sim_dir"
    exit
}
set sim_exe [file tail [lindex $sim_exe_list 0]]

# ─────────────────────────────────────────────
# 3.0 Procs
# ─────────────────────────────────────────────
proc safe_send {msg} {
    global sock
    catch {puts $sock $msg}
}

proc subscribe_vars {} {
    global sock
    safe_send "trick.var_pause()"
    safe_send "trick.var_ascii()"
    safe_send "trick.var_add(\"bldc_sim.motor.rpm\")"
    safe_send "trick.var_add(\"bldc_sim.motor.current\")"
    safe_send "trick.var_add(\"bldc_sim.motor.torque\")"
    safe_send "trick.var_add(\"bldc_sim.motor.back_emf\")"
    safe_send "trick.var_add(\"bldc_sim.motor.power\")"
    safe_send "trick.var_add(\"bldc_sim.motor.voltage\")"
    safe_send "trick.var_cycle(0.1)"
    safe_send "trick.var_unpause()"
}

proc cleanup {} {
    global sock
    catch {close $sock}
    exec pkill wish
}

proc restart_sim {} {
    global sock sim_dir sim_exe port
    catch {fileevent $sock readable {}}
    catch {close $sock}
    exec bash -c "cd $sim_dir && ./$sim_exe RUN_test/input.py &"
    after 3000 [list exec wish [file join $sim_dir BLDC_Display.tcl] $port &]
    exec pkill wish
}

# ─────────────────────────────────────────────
# 4.0 Async socket read handler
# ─────────────────────────────────────────────
proc handle_data {} {
    global sock

    if {[catch {gets $sock line} err] || [eof $sock]} {
        catch {fileevent $sock readable {}}
        catch {close $sock}
        return
    }

    if {$line ne ""} {
        set fields [split $line "\t"]
        if {[lindex $fields 0] == 0 && [llength $fields] == 7} {
            .readout.rpm.value     configure -text [format "%.1f"  [lindex $fields 1]]
            .readout.current.value configure -text [format "%.3f"  [lindex $fields 2]]
            .readout.torque.value  configure -text [format "%.4f"  [lindex $fields 3]]
            .readout.backemf.value configure -text [format "%.3f"  [lindex $fields 4]]
            .readout.power.value   configure -text [format "%.2f"  [lindex $fields 5]]
            .readout.voltage.value configure -text [format "%.1f"  [lindex $fields 6]]
        }
    }
}

# ─────────────────────────────────────────────
# 5.0 Connect socket
# ─────────────────────────────────────────────
set sock [socket localhost $port]
fconfigure $sock -translation binary -buffering line -blocking 0
fileevent $sock readable handle_data
subscribe_vars

# ─────────────────────────────────────────────
# 6.0 GUI
# ─────────────────────────────────────────────
wm title . "BLDC Motor Display"
wm geometry . 600x800
wm protocol . WM_DELETE_WINDOW { cleanup }
. configure -bg #1e1e1e

# Title
label .title -text "Castle Creations 2200Kv Motor Performance" \
    -font {Helvetica 16 bold} -fg white -bg #1e1e1e
pack .title -fill x -pady 10

# ── Readout frame ──
frame .readout -bg #2b2b2b -relief raised -bd 2
pack .readout -fill x -padx 10 -pady 5

proc make_row {parent label_text var_name unit} {
    frame $parent.$var_name -bg #2b2b2b
    pack $parent.$var_name -fill x -padx 10 -pady 4

    label $parent.$var_name.label -text $label_text \
        -width 15 -anchor w -bg #2b2b2b -fg #aaaaaa \
        -font {Helvetica 11}
    pack $parent.$var_name.label -side left

    label $parent.$var_name.value -text "---" \
        -width 12 -anchor e -bg #2b2b2b -fg #00bfff \
        -font {Helvetica 12 bold}
    pack $parent.$var_name.value -side left

    label $parent.$var_name.unit -text $unit \
        -width 8 -anchor w -bg #2b2b2b -fg #888888 \
        -font {Helvetica 10}
    pack $parent.$var_name.unit -side left
}

make_row .readout "RPM"      rpm     "RPM"
make_row .readout "Current"  current "A"
make_row .readout "Torque"   torque  "N.m"
make_row .readout "Back-EMF" backemf "V"
make_row .readout "Power"    power   "W"
make_row .readout "Voltage"  voltage "V"

# ── Control frame ──
frame .control -bg #2b2b2b -relief raised -bd 2
pack .control -fill x -padx 10 -pady 10

label .control.title -text "Motor Controls" \
    -bg #2b2b2b -fg white -font {Helvetica 12 bold}
pack .control.title -pady 5

label .control.label -text "Voltage" \
    -bg #2b2b2b -fg white -font {Helvetica 10 bold}
pack .control.label -pady 5

# ── Quick voltage buttons ──
frame .control.voltbuttons -bg #2b2b2b
pack .control.voltbuttons -pady {5 20}

foreach {lbl v} {
    "1S 3.7V"  3.7
    "2S 7.4V"  7.4
    "3S 11.1V" 11.1
    "4S 14.8V" 14.8
    "5S 18.5V" 18.5
    "6S 22.2V" 22.2
} {
    set btn ".control.voltbuttons.v[string map {. _} $v]"
    button $btn \
        -text $lbl \
        -bg #444444 -fg white \
        -font {Helvetica 9 bold} \
        -command [list apply {{v} {
            if {[catch {
                safe_send "bldc_sim.motor.voltage = $v"
            } err]} {
                puts "Warning: $err"
            }
        }} $v]
    pack $btn -side left -padx 2
}

# ── Load scale ──
scale .control.load_scale \
    -from 0.0 -to 5.0 \
    -resolution 0.01 \
    -orient horizontal \
    -label "Load Torque (N·m)" \
    -bg #2b2b2b -fg white \
    -troughcolor #444444 \
    -activebackground #ff6b6b \
    -length 400
pack .control.load_scale -padx 10 -pady {2 5}
.control.load_scale set 0.0

# ── Apply button ──
button .control.apply \
    -text "Apply" \
    -bg #00bfff -fg black \
    -font {Helvetica 11 bold} \
    -command {
        safe_send "bldc_sim.motor.tau_load = [.control.load_scale get]"
    }
pack .control.apply -pady 10

# ── Sim control buttons ──
frame .buttons -bg #1e1e1e
pack .buttons -fill x -padx 10 -pady 5

# Inner frame to center buttons
frame .buttons.inner -bg #1e1e1e
pack .buttons.inner -anchor center

button .buttons.inner.start \
    -text "Start" \
    -bg #51cf66 -fg black \
    -font {Helvetica 11 bold} \
    -command { safe_send "trick.exec_run()" }
pack .buttons.inner.start -side left -padx 5

button .buttons.inner.freeze \
    -text "Freeze" \
    -bg #ffd43b -fg black \
    -font {Helvetica 11 bold} \
    -command { safe_send "trick.exec_freeze()" }
pack .buttons.inner.freeze -side left -padx 5

button .buttons.inner.shutdown \
    -text "Shutdown" \
    -bg #cf6a51 -fg black \
    -font {Helvetica 11 bold} \
    -command {
        safe_send "trick.stop()"
        exec pkill wish
    }
pack .buttons.inner.shutdown -side left -padx 5