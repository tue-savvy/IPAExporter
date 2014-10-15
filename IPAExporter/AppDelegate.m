//
//  AppDelegate.m
//  IPAExporter
//
//  Created by Tue Nguyen on 10/10/14.
//  Copyright (c) 2014 HOME. All rights reserved.
//

#import "AppDelegate.h"
#import "ArchiveWindowController.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (nonatomic, strong) ArchiveWindowController *mainWindowController;
@end

@implementation AppDelegate
- (void)awakeFromNib {
    self.mainWindowController = [[ArchiveWindowController alloc] initWithWindowNibName:@"ArchiveWindowController"];
    self.window = self.mainWindowController.window;
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
}
- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag{
    
    if(flag == NO){
        [self.window makeKeyAndOrderFront:self];
    }
    return YES;	
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
