
struct y_component
{
    r32 Min;
    r32 Max;
};

inline
y_component InvertYAxis(int ViewportHeight, 
                        r32 YMin, r32 YMax)
{
    y_component Result = {};
    Result.Min = (r32)(ViewportHeight - YMin);
    Result.Max = (r32)(ViewportHeight - YMax);
    return (Result);
}

union v2
{
    struct
    {
        r32 X, Y;
    };
    r32 E[2];
};

inline v2 V2(r32 X, r32 Y)
{
    v2 Result;

    Result.X = X;
    Result.Y = Y;

    return (Result);
}

internal void
GameUpdateAndRender(game_memory *GameMemory, game_render_commands *RenderCommands)
{
    u32 TextureID = 0;

    v2 vMin = V2(0, 0);
    v2 vMax = V2(100, 100);

    y_component YComponent = InvertYAxis(RenderCommands->ViewportHeight, 
                                         vMin.Y, vMax.Y);

    game_texture_vertex QuadVertices[] =
    {
        // Pixel positions, Texture coordinates, TextureID
        { { vMin.X, YComponent.Min }, { 0.0f, 1.0f }, TextureID },
        { { vMin.X, YComponent.Max }, { 0.0f, 0.0f }, TextureID },
        { { vMax.X, YComponent.Max }, { 1.0f, 0.0f }, TextureID },

        { { vMin.X, YComponent.Min }, { 0.0f, 1.0f }, TextureID },
        { { vMax.X, YComponent.Min }, { 1.0f, 1.0f }, TextureID },
        { { vMax.X, YComponent.Max }, { 1.0f, 0.0f }, TextureID }
    };

    game_texture_command_buffer *TextureBuffer = &RenderCommands->TextureCommandBuffers[RenderCommands->FrameIndex];

    game_texture_vertex *Source = QuadVertices;
    game_texture_vertex *Dest = TextureBuffer->TextureVertices + TextureBuffer->NumberOfTextureVertices;

    for (uint32 Index = 0; Index < 6; Index++)
    {
        *Dest++ = *Source++;
        TextureBuffer->NumberOfTextureVertices++;
    }
}
