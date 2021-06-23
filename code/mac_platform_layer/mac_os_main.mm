
#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#include "mac_os_main.h"
#include "mac_window.mm"

@interface PixelShaderDemoWindow: NSWindow

@end

@implementation PixelShaderDemoWindow

@end

global_variable PixelShaderDemoWindow *Window;

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

    return NSApplicationMain(argc, argv);
}
