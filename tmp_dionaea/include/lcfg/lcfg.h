/*
  Copyright (c) 2012, Paul Baecher
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
      * Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in the
        documentation and/or other materials provided with the distribution.
      * Neither the name of the <organization> nor the
        names of its contributors may be used to endorse or promote products
        derived from this software without specific prior written permission.
  
  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL <THE COPYRIGHT HOLDER> BE LIABLE FOR ANY
  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
#ifndef LCFG_H
#define LCFG_H

#include <stdlib.h>

struct lcfg;

enum lcfg_status { lcfg_status_ok, lcfg_status_error };

typedef enum lcfg_status (*lcfg_visitor_function)(const char *key, void *data, size_t size, void *user_data);


/* open a new config file */
struct lcfg *        lcfg_new(const char *filename);

/* parse config into memory */
enum lcfg_status     lcfg_parse(struct lcfg *);

/* visit all configuration elements */
enum lcfg_status     lcfg_accept(struct lcfg *, lcfg_visitor_function, void *);

/* access a value by path */
enum lcfg_status     lcfg_value_get(struct lcfg *, const char *, void **, size_t *);

/* return the last error message */
const char *         lcfg_error_get(struct lcfg *);

/* set error */
void                 lcfg_error_set(struct lcfg *, const char *fmt, ...);

/* destroy lcfg context */
void                 lcfg_delete(struct lcfg *);


#endif
