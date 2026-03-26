#include "CivetServer.h"
#include "civetweb.h"
#include "bldc/include/bldc.h"
#include <string.h>
#include <stdio.h>

/* Reference to your BLDC motor object */
extern BLDC_MOTOR bldc_sim_motor;

void handle_HTTP_GET_bldc(struct mg_connection *nc, void *hm) {
    char json_text[512];

    /* Build JSON response with live motor data */
    snprintf(json_text, sizeof(json_text),
        "{"
        "\"rpm\": %.4f,"
        "\"torque\": %.4f,"
        "\"current\": %.4f,"
        "\"voltage\": %.4f,"
        "\"temperature\": %.4f"
        "}",
        bldc_sim_motor.rpm,
        bldc_sim_motor.torque,
        bldc_sim_motor.current,
        bldc_sim_motor.voltage,
        bldc_sim_motor.temperature
    );

    mg_printf(nc, "%s", "HTTP/1.1 200 OK\r\n"
                        "Content-Type: application/json\r\n"
                        "Transfer-Encoding: chunked\r\n\r\n");
    mg_send_chunk(nc, json_text, strlen(json_text));
    mg_send_chunk(nc, "", 0);
}