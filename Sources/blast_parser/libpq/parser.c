//
//  parser.c
//  blast_parser
//
//  Created by João Varela on 02/09/2024.
//

#include <stdbool.h>
#include <string.h>
#include "libpq-fe.h"
#include "globals-bp.h"
#include "parser.h"

bool PSDParseBool(PGresult *result) {
    int nFields = 0, nTuples = 0;
    char *boolStr = NULL;
    bool boolResult = false;
    
    /* first, print out the attribute names */
    nFields = PQnfields(result);
    nTuples = PQntuples(result);
    if (nFields == 1 && nTuples == 1) {
        boolStr = PQgetvalue(result, 0, 0);
    }
    
    if (boolStr != NULL ) {
        if (strcmp(boolStr, "t") == 0) {
            boolResult = true;
        }
    }
    
    PQclear(result);
    return boolResult;
}

void PSDParseString(PGresult *result, char *stringResult) {
    int nFields = 0, nTuples = 0;
    
    nFields = PQnfields(result);
    nTuples = PQntuples(result);
    
    const char* header = PQgetvalue(result, 0, 0);
    if (header != NULL) {
        size_t length = strlen(header) + 1; /* + 1 for terminating NULL */
        strncat(stringResult, header, length);
        
        if (nFields == kPSDQueryRealFieldNumber && nTuples == 1 && stringResult != NULL) {
            for(int i=1; i < kPSDQueryFieldNumber; i++) {
                const char* value = PQgetvalue(result, 0, i);
                if (value != NULL) {
                    length += strlen(value) + 1; /* + 1 for the separator */
                    strncat(stringResult, kPSDQueryResultSeparator, length);
                    strncat(stringResult, value, length);
                }
            }
        }
    }

    PQclear(result);
}


