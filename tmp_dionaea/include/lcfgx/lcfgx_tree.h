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
#ifndef LCFGX_TREE_H
#define LCFGX_TREE_H

#include <lcfg/lcfg.h>

enum lcfgx_type
{
	lcfgx_string,
	lcfgx_list,
	lcfgx_map,
};

struct lcfgx_tree_node
{
	enum lcfgx_type type;
	char *key; /* NULL for root node */

	union
	{
		struct
		{
			void *data;
			size_t len;
		} string;
		struct lcfgx_tree_node *elements; /* in case of list or map type */
	} value;

	struct lcfgx_tree_node *next;
};

struct lcfgx_tree_node *lcfgx_tree_new(struct lcfg *);

void lcfgx_tree_delete(struct lcfgx_tree_node *);
void lcfgx_tree_dump(struct lcfgx_tree_node *node, int depth);

enum lcfgx_path_access
{
	LCFGX_PATH_NOT_FOUND,
	LCFGX_PATH_FOUND_WRONG_TYPE_BAD,
	LCFGX_PATH_FOUND_TYPE_OK,
};

extern const char *lcfgx_path_access_strings[];


enum lcfgx_path_access lcfgx_get(struct lcfgx_tree_node *root, struct lcfgx_tree_node **n, const char *key, enum lcfgx_type type);
enum lcfgx_path_access lcfgx_get_list(struct lcfgx_tree_node *root, struct lcfgx_tree_node **n, const char *key);
enum lcfgx_path_access lcfgx_get_map(struct lcfgx_tree_node *root, struct lcfgx_tree_node **n, const char *key);
enum lcfgx_path_access lcfgx_get_string(struct lcfgx_tree_node *root, struct lcfgx_tree_node **n, const char *key);


#endif

