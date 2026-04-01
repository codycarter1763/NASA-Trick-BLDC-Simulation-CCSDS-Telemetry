#!/usr/bin/env wish

package require Plotchart

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
set db_path [file join $sim_dir "www" "motor.db"]
set sim_exe_list [glob -nocomplain $sim_dir/S_main_*.exe]
if {[llength $sim_exe_list] == 0} {
    puts "Error: No S_main_*.exe found in $sim_dir"
    exit
}
set sim_exe [file tail [lindex $sim_exe_list 0]]                

# ─────────────────────────────────────────────
# 3.0 Procs
# ─────────────────────────────────────────────
proc get_current_run {} {
    set file "/home/cody/trick_sims/SIM_BLDC_Motor/www/current_run.txt"

    if {![file exists $file]} {
        return 0
    }

    set f [open $file r]
    set val [gets $f]
    close $f

    if {$val eq ""} {
        return 0
    }

    return $val
}

proc safe_send {msg} {
    global sock
    catch {puts $sock $msg}
}

proc subscribe_vars {} {
    global sock
    safe_send "trick.var_pause()"
    safe_send "trick.var_ascii()"
    safe_send "trick.var_add(\"bldc_sim.motor.time\")"
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
wm geometry . 600x900
wm protocol . WM_DELETE_WINDOW { cleanup }
. configure -bg #1e1e1e

# Title
label .title -text "Castle Creations 2200Kv Motor Performance" \
    -font {Helvetica 16 bold} -fg white -bg #1e1e1e
pack .title -fill x -pady 10

set current_run [expr {[get_current_run] + 1}]

label .runlabel \
    -text "Current Run: $current_run" \
    -font {Helvetica 12 bold} \
    -fg #00ffcc \
    -bg #1e1e1e

pack .runlabel -pady 5

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

proc increment_run_id {} {
    set file "/home/cody/trick_sims/SIM_BLDC_Motor/www/current_run.txt"

    # If file doesn't exist, create it with 0
    if {![file exists $file]} {
        set f [open $file w]
        puts $f 0
        close $f
    }

    # Read current value
    set f [open $file r]
    set val [gets $f]
    close $f

    if {$val eq ""} {
        set val 0
    }

    # Increment
    set val [expr {$val + 1}]

    # Write back
    set f [open $file w]
    puts $f $val
    close $f

    return $val
}

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
    -command {
        set ::db_plot_active 0
        .plot delete all
        set run_id [increment_run_id]
        puts "Starting run $run_id"
        safe_send "trick.exec_run()"
    }
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

# ─────────────────────────────────────────────
# PLOT + DB LAYER (NON-INTRUSIVE ADDITION)
# ─────────────────────────────────────────────

# Data buffers
set selected_var "rpm"
set selected_run 1

set time_data {}
set rpm_data {}
set current_data {}
set power_data {}
set bemf_data {}

proc get_fixed_range {var} {
    switch $var {
        "rpm"     { return {0 50000} }
        "current" { return {0 1000} }
        "power"   { return {0 20000} }
        "bemf"    { return {0 40} }
        default   { return {0 1} }
    }
}

proc draw_plot {} {
    global selected_var db_plot_active
    global time_data rpm_data current_data power_data bemf_data
    global plot

    if {$db_plot_active} { return }
    if {![winfo exists .plot]} { return }

    .plot delete all

    switch $selected_var {
        "rpm"     { set data $rpm_data }
        "current" { set data $current_data }
        "power"   { set data $power_data }
        "bemf"    { set data $bemf_data }
        default   { return }
    }

    set n [llength $data]
    if {$n < 2} return

    set t_start [lindex $time_data 0]
    set t_end   [lindex $time_data end]
    if {$t_end <= $t_start} { set t_end [expr {$t_start + 1}] }

    # Use same fixed ranges as DB plot
    set yrange [get_fixed_range $selected_var]
    set y_min  [lindex $yrange 0]
    set y_max  [lindex $yrange 1]
    set y_step [expr {($y_max - $y_min) / 5.0}]
    set x_step [expr {($t_end - $t_start) / 5.0}]

    set plot [::Plotchart::createXYPlot .plot \
        [list $t_start $t_end $x_step] \
        [list $y_min   $y_max $y_step] \
    ]

    $plot dataconfig series1 -colour cyan
    $plot yconfig -format "%.0f"
    $plot xconfig -format "%.2f"

    for {set i 0} {$i < $n} {incr i} {
        $plot plot series1 [lindex $time_data $i] [lindex $data $i]
    }
}

proc draw_axis {canvas w h x_margin y_margin min_val max_val var_label {sample_count 0}} {
    global time_data

    set plot_h [expr {$h - 2*$y_margin}]
    set plot_w [expr {$w - 2*$x_margin}]
    set num_ticks 5

    # ── Y-axis ──
    for {set i 0} {$i <= $num_ticks} {incr i} {
        set frac [expr {double($i) / $num_ticks}]
        set val  [expr {$min_val + $frac * ($max_val - $min_val)}]
        set y    [expr {$y_margin + $plot_h - $frac * $plot_h}]

        $canvas create line \
            $x_margin [expr {int($y)}] \
            [expr {$x_margin + 5}] [expr {int($y)}] \
            -fill #888888

        $canvas create text \
            [expr {$x_margin - 2}] [expr {int($y)}] \
            -text [format "%.1f" $val] \
            -fill #aaaaaa \
            -anchor e \
            -font {Helvetica 8}
    }

    # ── X-axis ──
    if {$sample_count > 0} {

        # DB mode (time from samples)
        set dt 0.1

        for {set i 0} {$i <= 5} {incr i} {
            set frac   [expr {double($i) / 5}]
            set x      [expr {$x_margin + int($frac * $plot_w)}]
            set sample [expr {int($frac * $sample_count)}]
            set t      [expr {$sample * $dt}]

            $canvas create line \
                $x [expr {$y_margin + $plot_h}] \
                $x [expr {$y_margin + $plot_h + 5}] \
                -fill #888888

            $canvas create text \
                $x [expr {$y_margin + $plot_h + 8}] \
                -text [format "%.1fs" $t] \
                -fill #aaaaaa \
                -anchor n \
                -font {Helvetica 8}
        }

    } elseif {[llength $time_data] >= 2} {

        # Live time axis
        set t_start   [expr {[lindex $time_data 0] }]
        set t_end     [expr {[lindex $time_data end] }]
        set t_elapsed [expr {$t_end - $t_start}]
        set t_window  30.0

        if {$t_elapsed < $t_window} {
            # 🔥 FIX: grow from 0 → current time
            set x_min 0.0
            set x_max $t_elapsed

            # Prevent collapse at startup
            if {$x_max < 1.0} { set x_max 1.0 }

        } else {
            # 🔥 Scroll window after full
            set x_max $t_elapsed
            set x_min [expr {$t_elapsed - $t_window}]
        }

        for {set i 0} {$i <= 5} {incr i} {
            set frac [expr {double($i) / 5}]
            set x    [expr {$x_margin + int($frac * $plot_w)}]
            set t    [expr {$x_min + $frac * ($x_max - $x_min)}]

            $canvas create line \
                $x [expr {$y_margin + $plot_h}] \
                $x [expr {$y_margin + $plot_h + 5}] \
                -fill #888888

            $canvas create text \
                $x [expr {$y_margin + $plot_h + 8}] \
                -text [format "%.1fs" $t] \
                -fill #aaaaaa \
                -anchor n \
                -font {Helvetica 8}
        }
    }

    # Y-axis label
    $canvas create text \
        15 [expr {$h / 2}] \
        -text $var_label \
        -fill #00bfff \
        -anchor w \
        -font {Helvetica 9 bold}
}

set db_plot_active 0
# ─── DB PLOT FUNCTION ───
proc plot_from_db {} {
    global selected_var selected_run db_path db_plot_active

    set db_plot_active 1

    package require sqlite3

    if {![file exists $db_path]} {
        puts "ERROR: DB not found at $db_path"
        return
    }

    switch $selected_var {
        "rpm"     { set col "rpm" }
        "current" { set col "current" }
        "power"   { set col "power" }
        "bemf"    { set col "back_emf" }
        default   {
            puts "Unknown variable: $selected_var"
            return
        }
    }

    sqlite3 db_conn $db_path -readonly true

    set times  {}
    set values {}

    db_conn eval "SELECT time, $col FROM motor_data 
                  WHERE run_id = $selected_run
                  ORDER BY time" row {
        lappend times  $row(time)
        lappend values $row($col)
    }

    db_conn close

    # Prepend origin only for vars that start at 0
    switch $selected_var {
        "rpm" - "bemf" {
            set times  [linsert $times  0 0.0 [lindex $times 0]]
            set values [linsert $values 0 0.0 0.0]
        }
    }

    set n [llength $values]
    if {$n < 2} {
        puts "No data for run_id=$selected_run var=$col"
        return
    }

    puts "Plotting $n points: var=$col run=$selected_run"

    .plot delete all

    set t_start 0.0
    set t_end   [lindex $times end]
    if {$t_end <= $t_start} { set t_end [expr {$t_start + 1}] }

    set yrange [get_fixed_range $selected_var]
    set y_min  [lindex $yrange 0]
    set y_max  [lindex $yrange 1]
    set y_step [expr {($y_max - $y_min) / 5.0}]
    set x_step [expr {($t_end - $t_start) / 5.0}]

    set p [::Plotchart::createXYPlot .plot \
        [list $t_start $t_end $x_step] \
        [list $y_min   $y_max $y_step] \
    ]

    $p dataconfig series1 -colour cyan
    $p yconfig -format "%.0f"
    $p xconfig -format "%.2f"

    for {set i 0} {$i < $n} {incr i} {
        $p plot series1 [lindex $times $i] [lindex $values $i]
    }
}

proc safe_double {val} {
    set val [string trim $val]

    if {$val eq ""} {
        return 0.0
    }

    if {[string is double -strict $val]} {
        return [expr {double($val)}]
    }

    return 0.0
}

proc handle_data {} {
    global sock
    global time_data rpm_data current_data power_data bemf_data

    if {[catch {gets $sock line} err] || [eof $sock]} {
        catch {fileevent $sock readable {}}
        catch {close $sock}
        return
    }

    if {$line eq ""} { return }

    set fields [split $line "\t"]

    # Ensure correct format
    if {[llength $fields] != 8 || [lindex $fields 0] != 0} {
        return
    }

    set sim_time [safe_double [string trim [lindex $fields 1]]]
    set rpm      [safe_double [string trim [lindex $fields 2]]]
    set cur      [safe_double [string trim [lindex $fields 3]]]
    set tq       [safe_double [string trim [lindex $fields 4]]]
    set bemf     [safe_double [string trim [lindex $fields 5]]]
    set pwr      [safe_double [string trim [lindex $fields 6]]]
    set volt     [safe_double [string trim [lindex $fields 7]]]

    # UI update (safe now)
    .readout.rpm.value     configure -text [format "%.1f" $rpm]
    .readout.current.value configure -text [format "%.3f" $cur]
    .readout.torque.value  configure -text [format "%.4f" $tq]
    .readout.backemf.value configure -text [format "%.3f" $bemf]
    .readout.power.value   configure -text [format "%.2f" $pwr]
    .readout.voltage.value configure -text [format "%.1f" $volt]

    # Store numeric values only
    lappend time_data $sim_time
    lappend rpm_data $rpm
    lappend current_data $cur
    lappend power_data $pwr
    lappend bemf_data $bemf

    # Limit buffer
    if {[llength $time_data] > 300} {
        set time_data     [lrange $time_data end-300 end]
        set rpm_data      [lrange $rpm_data end-300 end]
        set current_data  [lrange $current_data end-300 end]
        set power_data    [lrange $power_data end-300 end]
        set bemf_data     [lrange $bemf_data end-300 end]
    }

    draw_plot
}

# rebind socket to new handler
fileevent $sock readable handle_data

# ─────────────────────────────────────────────
# UI ADDITION (BOTTOM ONLY)
# ─────────────────────────────────────────────

frame .plotframe -bg #1e1e1e
pack .plotframe -fill both -expand true -padx 10 -pady 10

frame .plotctrl -bg #2b2b2b
pack .plotctrl -fill x -pady 5

ttk::combobox .plotctrl.combo \
    -values {"rpm" "current" "power" "bemf"} \
    -textvariable selected_var \
    -state readonly
pack .plotctrl.combo -side left -padx 5

entry .plotctrl.run -textvariable selected_run -width 5
pack .plotctrl.run -side left -padx 5

button .plotctrl.db \
    -text "Plot DB" \
    -command plot_from_db
pack .plotctrl.db -side left -padx 5

button .plotctrl.clear \
    -text "Clear" \
    -command {
        set ::time_data {}
        set ::rpm_data {}
        set ::current_data {}
        set ::power_data {}
        set ::bemf_data {}
        .plot delete all
    }
pack .plotctrl.clear -side left -padx 5

canvas .plot -width 550 -height 250 -bg black
pack .plot -pady 5