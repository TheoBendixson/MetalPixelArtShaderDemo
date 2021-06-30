
struct game_memory 
{
    b32 IsInitialized;
    u64 PermanentStorageSize;
    void *PermanentStorage;

    u64 TransientStorageSize;
    void *TransientStorage;
};

struct memory_arena
{
    memory_index Size;
    u8* Base;
    memory_index Used; 
};

internal void
InitializeArena(memory_arena *Arena, memory_index Size, u8* Base)
{
    Arena->Size = Size;
    Arena->Base = Base;
    Arena->Used = 0; 
}

#define PushStruct(Arena, type) (type *)PushSize_(Arena, sizeof(type)) 
#define PushArray(Arena, Count, type) (type *)PushSize_(Arena, (Count)*sizeof(type)) 

void *
PushSize_(memory_arena *Arena, memory_index Size)
{
    Assert((Arena->Used + Size) <= Arena->Size);
    void *Result = Arena->Base + Arena->Used;
    Arena->Used += Size;
    return (Result);
}
