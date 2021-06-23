
typedef vector_float2 game_2d_vertex;
typedef vector_float2 game_2d_texture_coordinate;

struct game_texture_vertex
{
    game_2d_vertex Position;
    game_2d_texture_coordinate TextureCoordinate;
    u32 TextureID;
};

struct game_texture_command_buffer
{
    game_texture_vertex *TextureVertices;
    u32 NumberOfTextureVertices;
};

struct game_render_commands
{
    // NOTE: (Ted)  This is used in triple-buffering on Apple platforms.
    u32 FrameIndex;

    game_texture_command_buffer TextureCommandBuffers[3];

    s32 ViewportWidth;
    s32 ViewportHeight;

    r32 ScreenScaleFactor;
};
