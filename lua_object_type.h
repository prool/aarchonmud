#ifndef LUA_OBJECT_TYPE_H
#define LUA_OBJECT_TYPE_H

#define NO_OFF -1

#define PTYPE_NONE 0
#define PTYPE_INT 1
#define PTYPE_STR 2
#define PTYPE_FUN 3

typedef void * CHECK_FUN ( struct obj_type *self, lua_State *LS, int index );
typedef int PROP_FUNC( lua_State *LS, void *gobj );

typedef struct luahelp_topic
{
    char *key;
    char *summary;
    char *arguments;
    char *syntax;
    char *notes;
} LUAHELP_TOPIC;

typedef struct prop_type
{
    char *field;
    PROP_FUNC *func;
    int security;
    LUAHELP_TOPIC *help;
} LUA_PROP_TYPE;

/* base functionality for lua object types */
typedef struct obj_type
{
    int udtype; /* unique type ID */
    char *type_name;
    bool (*make)();

    CHECK_FUN *check;

    bool (*is)();

    LUA_PROP_TYPE *get_table;
    LUA_PROP_TYPE *set_table;
    LUA_PROP_TYPE *method_table;

} OBJ_TYPE;

OBJ_TYPE *CH_init( lua_State *LS);
OBJ_TYPE *OBJ_init( lua_State *LS);
OBJ_TYPE *AREA_init( lua_State *LS);
OBJ_TYPE *ROOM_init( lua_State *LS);
OBJ_TYPE *EXIT_init( lua_State *LS);
OBJ_TYPE *RESET_init( lua_State *LS);
OBJ_TYPE *OBJPROTO_init( lua_State *LS);
OBJ_TYPE *MOBPROTO_init( lua_State *LS);
#endif
