#include "base_types.h"

#define Assert(Expression) if(!(Expression)) { __builtin_trap(); }

#include "game_memory.h"
#include "game_render_commands.h"

#define Kilobytes(Value) ((Value)*1024LL)
#define Megabytes(Value) (Kilobytes(Value)*1024LL)
#define Gigabytes(Value) (Megabytes(Value)*1024LL)

struct game_state
{
    memory_arena ScratchArena;
    u8 TextureIndex;
    u8 FrameIndex;
};
