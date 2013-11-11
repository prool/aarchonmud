#ifndef LUA_OBJECT_TYPE_H
#define LUA_OBJECT_TYPE_H

#define NO_OFF -1

#define PTYPE_NONE 0
#define PTYPE_INT 1
#define PTYPE_STR 2
#define PTYPE_FUN 3

typedef void * CHECK_FUN ( struct obj_type *self, lua_State *LS, int index );
typedef int PROP_FUNC( lua_State *LS, void *gobj );
typedef struct prop_type
{
    char *field;
    int ptype;
    size_t offset;
    PROP_FUNC *func;
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

#endif
