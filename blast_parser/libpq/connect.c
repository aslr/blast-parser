//
//  connect.c
//  blast_parser
//
//  Created by João Varela on 01/09/2024.
//

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>
#include "globals-bp.h"
#include "connect.h"

#pragma mark **** private vars ****
static PGconn *sConn = NULL;

#pragma mark **** private functions ****
void PSDConnectToDBPv(const char *conninfo);

const char* PSDGetCurrentDB(void) {
    if (sConn == NULL) {return NULL;}
    return PQdb(sConn);
}

#pragma mark **** Connection to the database ****
void PSDConnectToMainDB(void) {
    PSDConnectToDB(kPSDMainDB);
}

#define kConnectionBufferSize 80

// NOTE: It must be paired with a PSDCloseConnection()
void PSDConnectToDB(const char *database) {
    char conninfo[kConnectionBufferSize];
    int charNumber = snprintf(conninfo, kConnectionBufferSize - 1, "dbname = %s", database);
    if (sConn == NULL && charNumber > 9) {
        PSDConnectToDBPv(conninfo);
    } else {
        if (strcmp(PSDGetCurrentDB(), database) != 0) {
            PSDCloseConnectionToDB();
            PSDConnectToDBPv(conninfo);
        }
    }
}

/// Private method
void PSDConnectToDBPv(const char *conninfo) {
    /* Make a connection to the database */
    sConn = PQconnectdb(conninfo);

    /* Check to see that the backend connection was successfully made */
    if (PQstatus(sConn) != CONNECTION_OK) {
        fprintf(stderr, "%s", PQerrorMessage(sConn));
        PSDHandleFatalError();
    }
}

// NOTE: It must be paired with a PSDConnectToDB()
void PSDCloseConnectionToDB(void) {
    if (sConn != NULL) {
        PQfinish(sConn);
        sConn = NULL;
    }
}

#pragma mark **** Execution ****
void PSDExecute(const char *command) {
    assert(sConn != NULL);
    PGresult *result = PQexec(sConn, command);
    ExecStatusType status = PQresultStatus(result);
    
    if (status != PGRES_TUPLES_OK && status != PGRES_COMMAND_OK) {
        fprintf(stderr, "SET failed: %s", PQerrorMessage(sConn));
        PQclear(result);
        PSDHandleFatalError();
    }
    
    // Avoid memory leaks
    PQclear(result);
}

PGresult* PSDExecuteWithResult(const char *command) {
    assert(sConn != NULL);
    PGresult *result = PQexec(sConn, command);
    ExecStatusType status = PQresultStatus(result);
    
    if (status != PGRES_TUPLES_OK && status != PGRES_COMMAND_OK) {
        fprintf(stderr, "SET failed: %s", PQerrorMessage(sConn));
        PQclear(result);
        PSDHandleFatalError();
    }
   
    return(result);
}

void PSDHandleFatalError(void) {
    if (sConn != NULL) {
        PQfinish(sConn);
        sConn = NULL;
    }
    
    exit(1);
}

