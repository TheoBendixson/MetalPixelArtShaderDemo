
#import <AppKit/AppKit.h>

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

    NSRect InitialFrame = NSMakeRect(0, 0, 1024, 1024);
}
