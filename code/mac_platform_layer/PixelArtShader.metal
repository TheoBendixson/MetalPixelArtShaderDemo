
#include <metal_stdlib>
#include <simd/simd.h>

typedef uint32_t u32;
typedef uint64_t u64;
typedef float r32;

#include "mac_texture_size.h"

using namespace metal;

typedef enum MacVertexInputIndex
{
    MacVertexInputIndexVertices     = 0,
    MacVertexInputIndexViewportSize = 1,
    MacVertexInputIndexTextureSize = 2
} MacVertexInputIndex;

typedef struct
{
    vector_float2 position;
    vector_float2 textureCoordinate;
    u32 textureID;

} MacTextureShaderVertex;

typedef struct
{
    float4 position [[position]];
    float2 textureCoordinate;
    
    float2 vUv;
    float2 textureSize;

    u32 textureID;

} RasterizerData;

vertex RasterizerData
vertexShader(uint vertexID [[ vertex_id ]],
             constant MacTextureShaderVertex *vertexArray [[ buffer(MacVertexInputIndexVertices) ]],
             constant vector_uint2 *viewportSizePointer  [[ buffer(MacVertexInputIndexViewportSize) ]],
             constant mac_texture_size *textureSize [[buffer(MacVertexInputIndexTextureSize) ]])
{
    RasterizerData out;

    // Index into the array of positions to get the current vertex.
    //   Positions are specified in pixel dimensions (i.e. a value of 100 is 100 pixels from
    //   the origin)
    float2 pixelSpacePosition = vertexArray[vertexID].position.xy;

    // Get the viewport size and cast to float.
    float2 viewportSize = float2(*viewportSizePointer);

    // To convert from positions in pixel space to positions in clip-space,
    //  divide the pixel coordinates by half the size of the viewport.
    // Z is set to 0.0 and w to 1.0 because this is 2D sample.
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);

    // NOTE: (Ted)  This would be the Open GL equivalent of mapping the projection matrix to
    //              the game's screen coordinates. For now, this is a 2D game.
    out.position.xy = (pixelSpacePosition / (viewportSize / 2.0)) - 1;

    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;

    out.textureSize = float2(textureSize->Width, textureSize->Height);
    out.vUv = out.textureSize*out.textureCoordinate;

    out.textureID = vertexArray[vertexID].textureID;

    return out;
}

// Fragment functions
fragment float4
fragmentShader(RasterizerData in [[stage_in]],
                           texture2d_array<half> texture_atlas [[ texture(0) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    float2 alpha = float2(0.07);
    float2 x = fract(in.vUv);

    float2 xprime = clamp(0.5/(alpha*x), 0.0, 0.5) +
                    clamp((0.5/(alpha*(x - 1.0))) + 0.5, 0.0, 0.5);

    float2 textureCoordinate = (floor(in.vUv) + xprime)/in.textureSize;

    const half4 colorSample = texture_atlas.sample(textureSampler, textureCoordinate, in.textureID);

    return float4(colorSample[0], colorSample[1], colorSample[2], colorSample[3]);
}

