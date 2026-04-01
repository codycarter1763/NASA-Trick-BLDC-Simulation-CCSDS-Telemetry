#include <stdio.h>
#include <stdlib.h>
#include "../include/bldc.h"

void log_to_php(BLDC_MOTOR *m) {

    static double last_log_time = -1.0;   // persists across calls
    double dt = 0.05;                    // desired logging interval

    // Skip startup transient 
    if (m->time < 0.10) {
        return;
    }

    // Skip if not enough time has passed
    if (last_log_time >= 0 && (m->time - last_log_time) < dt) {
        return;
    }

    last_log_time = m->time;

    char cmd[512];

    snprintf(cmd, sizeof(cmd),
        "php /home/cody/trick_sims/SIM_BLDC_Motor/www/logger.php %f %f %f %f %f %f %f > /dev/null 2>&1 &",
        m->time,
        m->rpm,
        m->current,
        m->init_voltage,
        m->torque,
        m->power,
        m->back_emf
    );

    int ret = system(cmd);

    printf("Logging at time: %f\n", m->time);

    if (ret != 0) {
        printf("PHP logger failed\n");
    }
}