/*************************************************************************
PURPOSE: (Integrate BLDC motor state variables via Trick)
**************************************************************************/
#include "../include/bldc.h"
#include "/home/cody/trick/include/trick/integrator_c_intf.h"

int bldc_motor_integ(BLDC_MOTOR* M) {
    int trick_ret;

    /* Load states into Trick integrator */
    load_state(
        &M->current, /* index 0 */
        &M->omega, /* index 1*/
        &M->theta, /* index 2 */
        NULL
    );

    /* Perform integration step */
    trick_ret = integrate();

    /* Unload updated states */
    unload_state(
        &M->current,
        &M->omega,
        &M->theta,
        NULL
    );

    /* Update derived quantities after integration */
    M->torque   = M->Kt      * M->current;
    M->back_emf = M->Ke      * M->omega;
    M->power    = M->voltage * M->current;
    M->rpm      = M->omega   * (60.0 / (2.0 * 3.14));
    M->time    += 0.001;

    /* Stall detection: omega near zero after non-zero load */
    if (!M->stall && M->omega < 0.01 && M->tau_load > 0.0) {
        M->stall = 1;
        M->stallTime = M->time;
    }

    return trick_ret;
}