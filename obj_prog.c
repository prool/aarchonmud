#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/types.h>
#include <ctype.h>
#include "merc.h"
#include "tables.h"
#include "lookup.h"


/*
 * A general purpose percentage trigger. Checks if a random percentage
 * number is less than trigger phrase
 */
bool op_percent_trigger(
        OBJ_DATA *obj, OBJ_DATA *obj2, CHAR_DATA *ch1, CHAR_DATA *ch2, int type)
{
    if ( !HAS_OTRIG(obj, type) )
        return TRUE;

    OPROG_LIST *prg;

    for ( prg = obj->pIndexData->oprogs; prg != NULL; prg = prg->next )
    {
        if ( prg->trig_type == type
                && number_percent() <= atoi( prg->trig_phrase ) )
        {
            return lua_obj_program( NULL, prg->vnum, prg->code, obj, obj2, ch1, ch2);
        }
    }
    return TRUE;
}

bool op_act_trigger(
        OBJ_DATA *obj, CHAR_DATA *ch1, CHAR_DATA *ch2, char *trigger, int type)
{
    OPROG_LIST *prg;

    for ( prg = obj->pIndexData->oprogs; prg != NULL; prg = prg->next )
    {
        if ( prg->trig_type == type
                /* should be case-insensitive --Bobble
                   && strstr( argument, prg->trig_phrase ) != NULL )
                 */
            && ( strstr(cap_all(trigger), cap_all(prg->trig_phrase)) != NULL
                    ||   !strcmp(prg->trig_phrase, "*") ) )
                    {
                        return lua_obj_program( trigger, prg->vnum, prg->code, obj, NULL, ch1, NULL);
                    }
    }
    return TRUE;
}

bool op_try_trigger( char* argument, CHAR_DATA *ch )
{
    OBJ_DATA *obj;
    OBJ_DATA *next_obj;
    bool found = FALSE;

    for ( obj = ch->in_room->contents; obj != NULL; obj = next_obj )
    {
        next_obj = obj->next_content;

        if ( HAS_OTRIG(obj, OTRIG_TRY) )
        {
            op_act_trigger(obj, ch, NULL, argument, OTRIG_TRY); 
            found = TRUE;
        }
    }

    for ( obj = ch->carrying; obj != NULL; obj = next_obj )
    {
        next_obj = obj->next_content;

        if ( HAS_OTRIG(obj, OTRIG_TRY) )
        {
            op_act_trigger(obj, ch, NULL, argument, OTRIG_TRY); 
            found = TRUE;
        }
    }

    return found;
}

void op_speech_trigger( char *argument, CHAR_DATA *ch )
{
    OBJ_DATA *obj;
    OBJ_DATA *next_obj;

    for ( obj = ch->in_room->contents; obj != NULL; obj = next_obj )
    {
        next_obj = obj->next_content;

        if ( HAS_OTRIG(obj, OTRIG_SPEECH) )
        {
            op_act_trigger(obj, ch, NULL, argument, OTRIG_SPEECH);
        }
    }

    for ( obj = ch->carrying; obj != NULL; obj = next_obj )
    {
        next_obj = obj->next_content;

        if ( HAS_OTRIG(obj, OTRIG_SPEECH) )
        {
            op_act_trigger(obj, ch, NULL, argument, OTRIG_SPEECH);
        }
    }
}
