/*************************************************************************
PURPOSE: (BLDC motor HTTP GET handler prototypes)
**************************************************************************/
#ifndef BLDC_HTTP_HANDLERS_H
#define BLDC_HTTP_HANDLERS_H

#include "bldc/include/bldc.h"

#ifndef SWIG

/* Set the motor pointer so handlers can access live sim data */
void bldc_http_set_motor(BLDC_MOTOR* m);

/* Handler for /api/http/motor/data — returns JSON */
void handle_HTTP_GET_motor_data(struct mg_connection *nc, void *hm);

/* Handler for /api/http/motor/control — sets voltage/load */
void handle_HTTP_GET_motor_control(struct mg_connection *nc, void *hm);

#endif

#endif /* BLDC_HTTP_HANDLERS_H */