//
//  connect.h
//  blast_parser
//
//  Created by João Varela on 01/09/2024.
//

#ifndef connect_h
#define connect_h

#include <stdio.h>

#include <stdio.h>
#include "libpq-fe.h"

const char* PSDGetCurrentDB(void);
void PSDConnectToMainDB(void);
void PSDConnectToDB(const char *database);
void PSDCloseConnectionToDB(void);
void PSDExecute(const char *command);
PGresult* PSDExecuteWithResult(const char *command);
void PSDHandleFatalError(void);

#endif /* connect_h */
