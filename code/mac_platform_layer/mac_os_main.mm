
#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#include "mac_os_main.h"
#include "mac_window.mm"
#include "mac_file.cpp"
#include "mac_metal_setup.mm"

#include "../cross_platform/code/pixel_shader_demo.cpp"

@interface PixelShaderDemoWindow: NSWindow

@end

@implementation PixelShaderDemoWindow

@end

@interface MetalViewDelegate: NSObject<MTKViewDelegate>

@property game_memory GameMemory;
@property game_render_commands RenderCommands;
@property (retain) id<MTLRenderPipelineState> PixelArtPipelineState;
@property (retain) id<MTLCommandQueue> CommandQueue;
@property (retain) id<MTLTexture> TextureAtlas;
@property (retain) NSMutableArray *VertexBuffers;

- (void)configureMetal;

@end

static const NSUInteger kMaxInflightBuffers = 3;

@implementation MetalViewDelegate
{
    dispatch_semaphore_t _frameBoundarySemaphore;
    NSUInteger _currentFrameIndex;
}

- (void)configureMetal
{
    _frameBoundarySemaphore = dispatch_semaphore_create(kMaxInflightBuffers);
    _currentFrameIndex = 0;
}

- (void)drawInMTKView:(MTKView *)view 
{
    dispatch_semaphore_wait(_frameBoundarySemaphore, DISPATCH_TIME_FOREVER);
    _currentFrameIndex = (_currentFrameIndex + 1) % kMaxInflightBuffers;

    game_render_commands *RenderCommandsPtr = &_RenderCommands;
    RenderCommandsPtr->FrameIndex = (uint32)_currentFrameIndex;

    game_memory *GameMemoryPtr = &_GameMemory;

    game_texture_command_buffer *TextureCommandBuffer = &RenderCommandsPtr->TextureCommandBuffers[RenderCommandsPtr->FrameIndex];
    TextureCommandBuffer->NumberOfTextureVertices = 0;

    GameUpdateAndRender(GameMemoryPtr, RenderCommandsPtr);

    CGFloat BackingScaleFactor = [[NSScreen mainScreen] backingScaleFactor];

    NSUInteger Width = (NSUInteger)(RenderCommandsPtr->ViewportWidth*BackingScaleFactor);
    NSUInteger Height = (NSUInteger)(RenderCommandsPtr->ViewportHeight*BackingScaleFactor);
    MTLViewport Viewport = (MTLViewport){0.0, 0.0, (r64)Width, (r64)Height, -1.0, 1.0 };

    @autoreleasepool {
        id<MTLCommandBuffer> CommandBuffer = [[self CommandQueue] commandBuffer];
        MTLRenderPassDescriptor *RenderPassDescriptor = [view currentRenderPassDescriptor];
        RenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;

        MTLClearColor ClearColor = MTLClearColorMake(0.183f, 0.211f, 0.249f, 1.0f);
        RenderPassDescriptor.colorAttachments[0].clearColor = ClearColor;

        vector_uint2 ViewportSize = { (uint32)RenderCommandsPtr->ViewportWidth, 
                                      (uint32)RenderCommandsPtr->ViewportHeight };

        id<MTLRenderCommandEncoder> RenderEncoder = [CommandBuffer renderCommandEncoderWithDescriptor: RenderPassDescriptor];
        RenderEncoder.label = @"2D Pixel Art Render Encoder";

        [RenderEncoder setViewport: Viewport];

        [RenderEncoder setVertexBytes:&ViewportSize
                               length:sizeof(ViewportSize)
                              atIndex:1];

        [RenderEncoder setRenderPipelineState: [self PixelArtPipelineState]];

        mac_texture_size TextureSize = {};

        NSUInteger VertexCount = (NSUInteger)TextureCommandBuffer->NumberOfTextureVertices;

        if (VertexCount > 0)
        {
            [RenderEncoder setFragmentTexture: [self TextureAtlas]
                                      atIndex: 0];
            
            id<MTLBuffer> VertexBuffer = [[self VertexBuffers] objectAtIndex: _currentFrameIndex];
            [RenderEncoder setVertexBuffer: VertexBuffer offset: 0 atIndex: 0];

            TextureSize.Width = 32;
            TextureSize.Height = 32;
            [RenderEncoder setVertexBytes:&TextureSize
                                   length:sizeof(TextureSize)
                                  atIndex:2];

            [RenderEncoder drawPrimitives: MTLPrimitiveTypeTriangle
                              vertexStart: 0
                              vertexCount: VertexCount];
        }

        [RenderEncoder endEncoding];

        id<CAMetalDrawable> NextDrawable = [view currentDrawable];
        [CommandBuffer presentDrawable: NextDrawable];

        __block dispatch_semaphore_t semaphore = _frameBoundarySemaphore;
        [CommandBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer) {
            dispatch_semaphore_signal(semaphore);
        }];

        [CommandBuffer commit];
    }
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{

}

@end

global_variable PixelShaderDemoWindow *Window;

void
SetupVertexAndCommandBuffer(MTKView *MetalKitView, uint32 VertexBufferSize, NSMutableArray *VertexBuffers, 
                           game_texture_command_buffer *CommandBuffers, uint32 FrameIndex)
{
    game_texture_command_buffer CommandBuffer = {};

    CommandBuffer.TextureVertices = (game_texture_vertex *) mmap(0, VertexBufferSize,
                                                                 PROT_READ | PROT_WRITE,
                                                                 MAP_PRIVATE | MAP_ANON, -1, 0);

    id<MTLBuffer> VertexBuffer = [MetalKitView.device newBufferWithBytesNoCopy: CommandBuffer.TextureVertices
                                                                        length: VertexBufferSize 
                                                                       options: MTLResourceStorageModeShared
                                                                   deallocator: nil];

    CommandBuffer.NumberOfTextureVertices = 0;
    CommandBuffers[FrameIndex] = CommandBuffer;
    [VertexBuffers addObject: VertexBuffer];
}

int main(int argc, const char * argv[]) 
{
    MainWindowDelegate *WindowDelegate = [[MainWindowDelegate alloc] init];

    r32 GlobalRenderWidth = 1024;
    r32 GlobalRenderHeight = 1024;

    NSRect InitialFrame = NSMakeRect(0, 0, GlobalRenderWidth, GlobalRenderHeight);

    Window = [[PixelShaderDemoWindow alloc] 
                initWithContentRect: InitialFrame
                styleMask: NSWindowStyleMaskTitled |
                           NSWindowStyleMaskClosable
                  backing: NSBackingStoreBuffered
                    defer: NO];    
    
    [Window setBackgroundColor: NSColor.blackColor];
    [Window setTitle: @"Metal Scaling Pixel Art Shader Demo"];

    [Window makeKeyAndOrderFront: nil];
    [Window setDelegate: WindowDelegate];

    MTKView *MetalKitView = [[MTKView alloc] init];
    MetalKitView.frame = CGRectMake(0, 0, 
                                    GlobalRenderWidth, GlobalRenderHeight); 

    MetalKitView.device = MTLCreateSystemDefaultDevice(); 
    MetalKitView.framebufferOnly = false;
    MetalKitView.layer.contentsGravity = kCAGravityCenter;
    MetalKitView.preferredFramesPerSecond = 60;

    [Window setContentView: MetalKitView];

    game_render_commands RenderCommands = {}; 
    RenderCommands.ViewportWidth = (s32)GlobalRenderWidth;
    RenderCommands.ViewportHeight = (s32)GlobalRenderHeight;
    RenderCommands.FrameIndex = 0;
    RenderCommands.ScreenScaleFactor = (r32)([[NSScreen mainScreen] backingScaleFactor]);

    uint32 PageSize = getpagesize();
    uint32 VertexBufferSize = PageSize*1000;

    NSMutableArray *VertexBuffers = [[NSMutableArray alloc] init];

    for (uint32 Index = 0; Index < 3; Index++)
    {
        SetupVertexAndCommandBuffer(MetalKitView, VertexBufferSize, VertexBuffers, 
                                    RenderCommands.TextureCommandBuffers, Index);
    }

    NSString *ShaderLibraryFilePath = [[NSBundle mainBundle] pathForResource: @"PixelArtShader" ofType: @"metallib"];
    id<MTLLibrary> ShaderLibrary = [MetalKitView.device newLibraryWithFile: ShaderLibraryFilePath error: nil];
    id<MTLFunction> VertexShader = [ShaderLibrary newFunctionWithName:@"vertexShader"];
    id<MTLFunction> FragmentShader = [ShaderLibrary newFunctionWithName:@"fragmentShader"];

    MTLRenderPipelineDescriptor *PipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    PipelineStateDescriptor.label = @"2D Pixel Art Graphics Pipeline";
    PipelineStateDescriptor.vertexFunction = VertexShader;
    PipelineStateDescriptor.fragmentFunction = FragmentShader;
    MTLRenderPipelineColorAttachmentDescriptor *RenderBufferAttachment = PipelineStateDescriptor.colorAttachments[0];
    RenderBufferAttachment.pixelFormat = MetalKitView.colorPixelFormat;

    NSError *error = NULL;
    id<MTLRenderPipelineState> PixelArtPipelineState = 
        [MetalKitView.device newRenderPipelineStateWithDescriptor: PipelineStateDescriptor
                                                            error: &error];

    if (error != nil)
    {
        NSLog(@"Error creating pixel art pipeline state");
    }

    id<MTLCommandQueue> CommandQueue = [MetalKitView.device newCommandQueue]; 

    MetalViewDelegate *ViewDelegate = [[MetalViewDelegate alloc] init];

    game_memory GameMemory = {};
    u64 TotalMemorySize = Megabytes(64);
    GameMemory.PermanentStorageSize = Megabytes(32);
    GameMemory.PermanentStorage = mmap(0, TotalMemorySize,
                                       PROT_READ | PROT_WRITE,
                                       MAP_PRIVATE | MAP_ANON, -1, 0);

    GameMemory.TransientStorageSize = Megabytes(32);
    GameMemory.TransientStorage = (u8*)GameMemory.PermanentStorage + GameMemory.TransientStorageSize;

    if (GameMemory.PermanentStorage == MAP_FAILED) {
		printf("mmap error: %d  %s", errno, strerror(errno));
        [NSException raise: @"Memory Not Allocated"
                     format: @"Failed to allocate memory"];
    }

    game_texture_buffer TextureBuffer = {};
    GameLoadTextures(&GameMemory, &TextureBuffer);

    id<MTLTexture> TextureAtlas = SetupMetalTexture(MetalKitView, 32, 32, TextureBuffer.MaxTextures, 
                                                    &TextureBuffer);

    // Wipe the scratch space
    u8* Byte = (u8*)GameMemory.TransientStorage;
    for (u32 Index = 0; 
         Index < GameMemory.TransientStorageSize; 
         Index++)
    {
        *Byte++ = 0;
    }

    ViewDelegate.GameMemory = GameMemory; 
    ViewDelegate.RenderCommands = RenderCommands; 
    ViewDelegate.PixelArtPipelineState = PixelArtPipelineState;
    ViewDelegate.CommandQueue = CommandQueue;
    ViewDelegate.VertexBuffers = VertexBuffers;
    ViewDelegate.TextureAtlas = TextureAtlas;

    [ViewDelegate configureMetal];
    [MetalKitView setDelegate: ViewDelegate];

    return NSApplicationMain(argc, argv);
}
