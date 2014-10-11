//
//  ExportWindowController.m
//  IPAExporter
//
//  Created by Tue Nguyen on 10/11/14.
//  Copyright (c) 2014 HOME. All rights reserved.
//

#import "ExportWindowController.h"
#import "Provisioning.h"
#import "XcodeArchive.h"

#define LastSelectPathKey @"LastPath"

@interface ExportWindowController ()

@property (strong) IBOutlet NSMenu *popupMenu;
@property (nonatomic, strong) NSMutableArray *provisioningArray;
@property (strong) IBOutlet NSPopUpButton *popupButton;
@property (strong) IBOutlet NSProgressIndicator *progressView;
@property (strong) IBOutlet NSButton *exportButton;
@property (strong) IBOutlet NSTextField *destinationTextField;
@property (strong) IBOutlet NSButton *changeDestButton;
@property (strong) IBOutlet NSButton *cancelButton;
@property (nonatomic, strong) NSTask *exportingTask;
@end

@implementation ExportWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    self.provisioningArray = [NSMutableArray array];
    [self buildListIdentity];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:LastSelectPathKey]) {
        self.destinationTextField.stringValue = [[NSUserDefaults standardUserDefaults] objectForKey:LastSelectPathKey];
    } else {
        NSString *desktop = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) firstObject];
        self.destinationTextField.stringValue = [desktop stringByAppendingPathComponent:[self.archive.name stringByAppendingPathExtension:@"ipa"]];
    }
}

- (IBAction)export:(id)sender {
    [self updateUIWhenTaskRunning:YES];
    [self runExportTaskWithCompletion:^{
        [self updateUIWhenTaskRunning:NO];
        [[NSUserDefaults standardUserDefaults] setObject:self.destinationTextField.stringValue forKey:LastSelectPathKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self.window.sheetParent endSheet:self.window returnCode:NSOKButton];
    }];
}


- (IBAction)cancel:(id)sender {
    if (self.exportingTask.isRunning) {
        [self.exportingTask terminate];
        self.exportingTask = nil;
    } else {
        [self.window.sheetParent endSheet:self.window returnCode:NSCancelButton];
    }
}

- (void)buildListIdentity {
    [self.popupMenu removeAllItems];
    
    NSString *library = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    
    NSString *mobileProvisioningFolder = [library stringByAppendingPathComponent:@"MobileDevice/Provisioning Profiles"];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *contents = [fm contentsOfDirectoryAtPath:mobileProvisioningFolder error:nil];
    [self.provisioningArray removeAllObjects];
    
    for (NSString *name in contents) {
        if ([name hasPrefix:@"."]) continue;
        if ([name.pathExtension caseInsensitiveCompare:@"mobileprovision"] != NSOrderedSame) continue;
        
        NSString *path = [mobileProvisioningFolder stringByAppendingPathComponent:name];
        Provisioning *provisioning = [[Provisioning alloc] initWithPath:path];
        [self.provisioningArray addObject:provisioning];
    }
    [self.provisioningArray sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]]];
    for (Provisioning *provision in self.provisioningArray) {
        NSMenuItem *item = [[NSMenuItem alloc] init];
        item.title = [NSString stringWithFormat:@"%@ (%@)", provision.name, provision.applicationIdentifier];
        
        [item setEnabled:NO];
        [self.popupMenu addItem:item];
        for (SigningIdentity *identity in provision.signingIdentities) {
            NSMenuItem *itemIdentity = [[NSMenuItem alloc] init];
            itemIdentity.title = identity.commonName;
            itemIdentity.indentationLevel = 1;
            itemIdentity.representedObject = identity;
            [self.popupMenu addItem:itemIdentity];
        }
        [self.popupMenu addItem:[NSMenuItem separatorItem]];
    }
    if (self.popupButton.numberOfItems > 0) {
        [self.popupButton selectItemAtIndex:1];
    }
}
- (void)runExportTaskWithCompletion:(dispatch_block_t)completion {
    SigningIdentity *selectedIdentity = [self.popupButton selectedItem].representedObject;
    NSString *exportCommand = [[NSBundle mainBundle] pathForResource:@"Export" ofType:@"sh"];
    NSString *appPath = self.archive.absoluteApplicationPath;
    NSString *desticationPath = self.destinationTextField.stringValue;
    NSString *provisionName = selectedIdentity.provision.path;
    NSString *identityName = selectedIdentity.commonName;
    
    NSTask *exportTask = [NSTask new];
    self.exportingTask = exportTask;
    [exportTask setLaunchPath:exportCommand];
    [exportTask setArguments:@[appPath, desticationPath, identityName, provisionName]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [exportTask launch];
        [exportTask waitUntilExit];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion();
        });
    });
}
- (void)updateUIWhenTaskRunning:(BOOL)running {
    if (running) {
        [self.progressView startAnimation:nil];
        [self.exportButton setEnabled:NO];
    } else {
        [self.progressView stopAnimation:nil];
        [self.exportButton setEnabled:YES];
    }
}
- (IBAction)chageDestination:(id)sender {
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.allowedFileTypes = @[@"ipa"];
    savePanel.allowsOtherFileTypes = NO;
    NSString *destPath = self.destinationTextField.stringValue;
    
    savePanel.directoryURL = [NSURL fileURLWithPath:destPath.stringByDeletingLastPathComponent];
    [savePanel setNameFieldStringValue:destPath.lastPathComponent];
    
    [savePanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            self.destinationTextField.stringValue = savePanel.URL.path;
        }
    }];
    
}
@end
