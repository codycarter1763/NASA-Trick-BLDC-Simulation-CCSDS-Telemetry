/*************************************************************************
PURPOSE: (CivetWeb handler — executes motor_data.php via PHP CLI and
          streams the output back to the browser in chunks.
          Fixed: replaced fixed 4096-byte stack buffer with chunked
          streaming to prevent stack smashing on large PHP output.)
**************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
 
#include "trick/MyCivetServer.hh"
 
#ifdef __cplusplus
extern "C" {
#endif
 
void handle_HTTP_GET_php(struct mg_connection *conn, void *cbdata) {
 
    FILE *fp;
    char buffer[1024];
 
    fp = popen("php /home/cody/trick_sims/SIM_BLDC_Motor/www/motor_data.php", "r");
 
    if (!fp) {
        mg_printf(conn,
            "HTTP/1.1 500 Internal Server Error\r\n"
            "Content-Type: application/json\r\n\r\n"
            "{\"error\":\"popen failed\"}");
        return;
    }
 
    /* Send headers first — use chunked transfer so we don't need Content-Length */
    mg_printf(conn,
        "HTTP/1.1 200 OK\r\n"
        "Content-Type: text/html; charset=utf-8\r\n"
        "Access-Control-Allow-Origin: *\r\n"
        "Transfer-Encoding: chunked\r\n\r\n");
 
    /* Stream PHP output to browser one read-buffer at a time */
    while (fgets(buffer, sizeof(buffer), fp)) {
        mg_send_chunk(conn, buffer, strlen(buffer));
    }
 
    /* Terminate the chunked response */
    mg_send_chunk(conn, "", 0);
 
    pclose(fp);
}
 
#ifdef __cplusplus
}
#endif
 