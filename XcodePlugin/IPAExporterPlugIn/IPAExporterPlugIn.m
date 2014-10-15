//
//  IPAExporterPlugIn.m
//  IPAExporterPlugIn
//
//  Created by Tue Nguyen on 10/16/14.
//    Copyright (c) 2014 Pharaoh. All rights reserved.
//

#import "IPAExporterPlugIn.h"
#import "ArchiveWindowController.h"

static IPAExporterPlugIn *sharedPlugin;

@interface IPAExporterPlugIn()
@property (nonatomic, strong) ArchiveWindowController *archiveController;
@property (nonatomic, strong, readwrite) NSBundle *bundle;
@end

@implementation IPAExporterPlugIn

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
}

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        NSLog(@"Bundle: %@", plugin.bundleURL);
        // reference to plugin's bundle, for resource access
        self.bundle = plugin;
        // Create menu items, initialize UI, etc.

        // Sample Menu Item:
        NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Window"];
        if (menuItem) {
            [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
            NSInteger organizerIndex = [[menuItem submenu] indexOfItemWithTitle:@"Organizer"];
            NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Export IPA" action:@selector(doMenuAction) keyEquivalent:@"8"];
            actionMenuItem.keyEquivalentModifierMask = NSCommandKeyMask | NSShiftKeyMask;
            [actionMenuItem setTarget:self];
            [[menuItem submenu] insertItem:actionMenuItem atIndex:organizerIndex + 1];
        }
    }
    return self;
}

// Sample Action, for menu item:
- (void)doMenuAction
{
    if (!self.archiveController) {
        self.archiveController = [[ArchiveWindowController alloc] initWithWindowNibName:@"ArchiveWindowController"];
    }
    
    [self.archiveController.window makeKeyAndOrderFront:self];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
