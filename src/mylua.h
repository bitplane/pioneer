#ifndef _MYLUA_H
#define _MYLUA_H

/**
 * Use this header for including lua when you need it.
 * OOLUA is also your friend.
 */

#include "oolua/oolua.h"
#include "oolua/oolua_error.h"

// Copy of:
// LUALIB_API void *luaL_checkudata (lua_State *L, int ud, const char *tname)
// with typeerror commented out
static void *mylua_checkudata (lua_State *L, int ud, const char *tname) {
  void *p = lua_touserdata(L, ud);
  if (p != NULL) {  /* value is a userdata? */
    if (lua_getmetatable(L, ud)) {  /* does it have a metatable? */
      lua_getfield(L, LUA_REGISTRYINDEX, tname);  /* get correct metatable */
      if (lua_rawequal(L, -1, -2)) {  /* does it have the correct mt? */
        lua_pop(L, 2);  /* remove both metatables */
        return p;
      }
    }
  }
//  luaL_typerror(L, ud, tname);  /* else error */
  return NULL;  /* to avoid warnings */
}

#endif /* MYLUA_H */