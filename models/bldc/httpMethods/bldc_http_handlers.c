/*************************************************************************
PURPOSE: (BLDC motor HTTP GET handlers for Trick CivetWeb server)
**************************************************************************/
#include "CivetServer.h"
#include "civetweb.h"
#include "bldc/include/bldc.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* Global pointer to live motor struct */
static BLDC_MOTOR* g_motor = NULL;

void bldc_http_set_motor(BLDC_MOTOR* m) {
    g_motor = m;
}

/* ── /api/http/motor/data — returns motor state as JSON ── */
void handle_HTTP_GET_motor_data(struct mg_connection *nc, void *hm) {
    char json[512];

    if (g_motor == NULL) {
        const char* err = "{ \"error\": \"motor not initialized\" }";
        mg_printf(nc, "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n");
        mg_send_chunk(nc, err, strlen(err));
        mg_send_chunk(nc, "", 0);
        return;
    }

    snprintf(json, sizeof(json),
        "{"
        "\"rpm\":%.1f,"
        "\"current\":%.4f,"
        "\"voltage\":%.2f,"
        "\"torque\":%.6f,"
        "\"back_emf\":%.4f,"
        "\"power\":%.2f,"
        "\"omega\":%.4f,"
        "\"theta\":%.4f,"
        "\"time\":%.4f,"
        "\"stall\":%d"
        "}",
        g_motor->rpm,
        g_motor->current,
        g_motor->voltage,
        g_motor->torque,
        g_motor->back_emf,
        g_motor->power,
        g_motor->omega,
        g_motor->theta,
        g_motor->time,
        g_motor->stall
    );

    mg_printf(nc, "HTTP/1.1 200 OK\r\n"
                  "Content-Type: application/json\r\n"
                  "Access-Control-Allow-Origin: *\r\n"
                  "Transfer-Encoding: chunked\r\n\r\n");
    mg_send_chunk(nc, json, strlen(json));
    mg_send_chunk(nc, "", 0);
}

/* ── /api/http/motor/control — set voltage and load ── */
void handle_HTTP_GET_motor_control(struct mg_connection *nc, void *hm) {
    if (g_motor == NULL) return;

    /* Get query string from request */
    const struct mg_request_info *info = mg_get_request_info(nc);
    const char *query = info->query_string;

    if (query) {
        char val[32];

        /* Parse voltage= */
        if (mg_get_var(query, strlen(query), "voltage", val, sizeof(val)) > 0) {
            g_motor->voltage = atof(val);
        }

        /* Parse load= */
        if (mg_get_var(query, strlen(query), "load", val, sizeof(val)) > 0) {
            g_motor->tau_load = atof(val);
        }
    }

    const char* resp = "{ \"status\": \"ok\" }";
    mg_printf(nc, "HTTP/1.1 200 OK\r\n"
                  "Content-Type: application/json\r\n"
                  "Access-Control-Allow-Origin: *\r\n"
                  "Transfer-Encoding: chunked\r\n\r\n");
    mg_send_chunk(nc, resp, strlen(resp));
    mg_send_chunk(nc, "", 0);
}