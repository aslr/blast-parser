//
//  libpq-bp.h
//  blast_parser
//
//  Created by João Varela on 01/09/2024.
//

#ifndef libpq_h
#define libpq_h

#include <stdbool.h>
#include "globals-bp.h"

void PSDBegin(const char *database);
void PSDBeginWithDefaultDB(void);
void PSDEnd(void);

void PSDCreateDB(const char *database);

// table can be NULL
void PSDCreateDatabase(const char *database,
                       const char *table,
                       const char *columns);

void PSDDeleteDatabase(const char *database);

void PSDCreateTable(const char *table,
                    const char *columns);

bool PSDDoesExist(const char *database);

void PSDCopyToDB(const char *table,
                 const char* pathToCSVFile);

void PSDQuery(const char *table,
              const char *query,
              char *result);

#endif /* libpq_h */
