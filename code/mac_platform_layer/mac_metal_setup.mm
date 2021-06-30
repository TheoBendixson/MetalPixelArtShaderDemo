
id<MTLTexture>
SetupMetalTexture(MTKView *MetalKitView, u32 TextureWidth, u32 TextureHeight, 
                  u32 TextureCount, game_texture_buffer *TextureBuffer)
{
    MTLTextureDescriptor *TextureDescriptor = [[MTLTextureDescriptor alloc] init];
    TextureDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
    TextureDescriptor.width = TextureWidth;
    TextureDescriptor.height = TextureHeight;
    TextureDescriptor.arrayLength = TextureCount;
    TextureDescriptor.textureType = MTLTextureType2DArray;
    TextureDescriptor.usage = MTLTextureUsageShaderRead;

    MTLRegion TextureMetalRegion = {
        { 0, 0, 0 },
        { TextureWidth, TextureHeight, 1 }
    };

    id<MTLTexture> MetalTexture = [[MetalKitView.device newTextureWithDescriptor: TextureDescriptor] autorelease];

    for (u32 TextureIndex = 0;
         TextureIndex < TextureBuffer->TexturesLoaded;
         TextureIndex++)
    {
        game_texture GameTexture = TextureBuffer->Textures[TextureIndex];

        [MetalTexture replaceRegion: TextureMetalRegion 
                        mipmapLevel: 0
                              slice: TextureIndex
                          withBytes: (void *)GameTexture.Data
                          bytesPerRow: TextureWidth*sizeof(u32) 
                        bytesPerImage: 0];
    }

    return MetalTexture;
}
