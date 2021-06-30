
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

enum axis_flip_mode
{
    AxisFlipModeNone,
    AxisFlipModeX
};

struct spritesheet
{
    u32 *Data;
    u32 TextureWidthHeight;
    u32 TexturesPerRow;
    u32 TexturesPerColumn;
};

struct spritesheet_section
{
    s32 XOffset;
    s32 YOffset;
    u32 SamplingWidth;
    u32 SamplingHeight;
};

struct spritesheet_position
{
    s32 Row;
    s32 Column;
};

void
InitializeTextureBuffer(memory_arena *ScratchArena, game_texture_buffer *TextureBuffer, u32 MaxTextures)
{
    TextureBuffer->TexturesLoaded = 0;
    TextureBuffer->MaxTextures = MaxTextures;
    TextureBuffer->Textures = PushArray(ScratchArena, TextureBuffer->MaxTextures, game_texture);
}

void 
LoadTextureFromSpritesheet(memory_arena *ScratchArena, u32 PixelsToAllocate,
                           spritesheet *SpriteSheet, game_texture_buffer *TextureBuffer, 
                           spritesheet_section SpriteSheetSection, axis_flip_mode AxisFlipMode, 
                           spritesheet_position Position)
{
    game_texture Texture = TextureBuffer->Textures[TextureBuffer->TexturesLoaded];
    Texture.Width = SpriteSheetSection.SamplingWidth;
    Texture.Height = SpriteSheetSection.SamplingHeight;
    Texture.Data = PushArray(ScratchArena, PixelsToAllocate, u32);

    u32 *PixelDest = (u32 *)Texture.Data;
    u32 *PixelSource = SpriteSheet->Data;

    u32 TextureWidthHeight = SpriteSheet->TextureWidthHeight;
    u32 RowSizeInPixels = SpriteSheet->TexturesPerRow*TextureWidthHeight;

    s32 StartingXOffsetInPixels = Position.Column*TextureWidthHeight;

    u32 DestRowCount = 0;

    for (s32 Row = (Position.Row*TextureWidthHeight + (SpriteSheetSection.YOffset - 1 + SpriteSheetSection.SamplingHeight)); 
         Row >= (Position.Row*TextureWidthHeight + SpriteSheetSection.YOffset); 
         Row--)
    {
        u32 *DestRow = PixelDest + (DestRowCount*Texture.Width);

        if (AxisFlipMode == AxisFlipModeNone)
        {
            for (s32 Column = SpriteSheetSection.XOffset; 
                 Column <= (SpriteSheetSection.SamplingWidth + SpriteSheetSection.XOffset); 
                 Column++)
            {
                *DestRow++ = PixelSource[StartingXOffsetInPixels + (Row*RowSizeInPixels) + Column];
            }

        } else if (AxisFlipMode == AxisFlipModeX)
        {
            for (s32 Column = (SpriteSheetSection.XOffset + SpriteSheetSection.SamplingWidth - 1); 
                 Column >= SpriteSheetSection.XOffset; 
                 Column--)
            {
                *DestRow++ = PixelSource[StartingXOffsetInPixels + (Row*RowSizeInPixels) + Column];
            }
        }

        DestRowCount++;
    }

   TextureBuffer->Textures[TextureBuffer->TexturesLoaded] = Texture; 
   TextureBuffer->TexturesLoaded++;
}

internal void
GameLoadTextures(game_memory *Memory, game_texture_buffer *TextureBuffer)
{
    game_state *GameState = (game_state *)Memory->PermanentStorage;
    memory_arena *ScratchArena = &GameState->ScratchArena;
    InitializeArena(ScratchArena, Memory->TransientStorageSize,
                    (u8*)Memory->TransientStorage);

    InitializeTextureBuffer(ScratchArena, TextureBuffer, 8);

    read_file_result AssetFile = PlatformReadEntireFile("animation.asset");

    if (AssetFile.ContentsSize > 0)
    {
        u32 *TextureData = (u32*)AssetFile.Contents;

        spritesheet GameCharacterSpriteSheet = {};
        GameCharacterSpriteSheet.TextureWidthHeight = 32;
        GameCharacterSpriteSheet.TexturesPerRow = 8;
        GameCharacterSpriteSheet.TexturesPerColumn = 7;

        spritesheet_section PlayerSection = {};
        PlayerSection.XOffset = 0; 
        PlayerSection.YOffset = 0;
        PlayerSection.SamplingWidth = 32;
        PlayerSection.SamplingHeight = 32;

        spritesheet_position TexturePosition = {};
        TexturePosition.Row = 0;
        uint32 PlayerPixelsPerTexture = 32*32;

        for (uint32 Column = 0; Column < 8; Column++)
        {
            TexturePosition.Column = Column;

            LoadTextureFromSpritesheet(ScratchArena, PlayerPixelsPerTexture,
                                       &GameCharacterSpriteSheet, TextureBuffer, 
                                       PlayerSection, AxisFlipModeNone, TexturePosition);
        }
    }
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
