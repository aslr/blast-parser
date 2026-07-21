//
//  parser.h
//  blast_parser
//
//  Created by João Varela on 02/09/2024.
//

#ifndef parser_h
#define parser_h

#include <stdio.h>

bool PSDParseBool(PGresult *result);
void PSDParseString(PGresult *result, char *stringResult);

#endif /* parser_h */
