#include <stdio.h>
#include <stdlib.h>
#include "../include/bldc.h"   // for BLDC_MOTOR

void log_to_php(BLDC_MOTOR *m) {

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
    system(cmd);

    if (ret != 0) {
        printf("PHP logger failed\n");
    }
}