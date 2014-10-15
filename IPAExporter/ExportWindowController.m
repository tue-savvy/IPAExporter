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
#import "NSDate+Relative.h"

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

@property (weak) IBOutlet NSImageView *selectedArchiveImageView;
@property (weak) IBOutlet NSTextField *selectedAppName;
@property (weak) IBOutlet NSTextField *selectedProjectName;
@property (weak) IBOutlet NSTextField *selectedCreationDate;
@property (weak) IBOutlet NSTextField *selectedVersion;
@property (weak) IBOutlet NSTextField *selectedIdentifier;

@property (nonatomic, strong) NSTask *exportingTask;
@end

@implementation ExportWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    self.provisioningArray = [NSMutableArray array];
    
    [self buildListIdentity];
    
    [self updateArchiveInfo:self.archive];
    [self lookupBestIdentity];
}

- (void)setArchive:(XcodeArchive *)archive {
    _archive = archive;
    if ([self isWindowLoaded]) {
        [self updateArchiveInfo:_archive];
        [self lookupBestIdentity];
    }
}

- (void)updateArchiveInfo:(XcodeArchive *)selectedArchive {
    self.selectedArchiveImageView.image = selectedArchive.applicationIcon;
    self.selectedAppName.stringValue = selectedArchive.applicationName;
    self.selectedProjectName.stringValue = selectedArchive.name;
    
    self.selectedCreationDate.attributedStringValue = [self attributedStringWithTitle:@"Creation Date: " value:[selectedArchive.creationDate relativeTime]];
    self.selectedVersion.attributedStringValue = [self attributedStringWithTitle:@"Version: " value:selectedArchive.version];
    self.selectedIdentifier.attributedStringValue = [self attributedStringWithTitle:@"Identifier: " value:selectedArchive.bundleID];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:LastSelectPathKey]) {
        self.destinationTextField.stringValue = [[NSUserDefaults standardUserDefaults] objectForKey:LastSelectPathKey];
    } else {
        NSString *desktop = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) firstObject];
        self.destinationTextField.stringValue = [desktop stringByAppendingPathComponent:[self.archive.name stringByAppendingPathExtension:@"ipa"]];
    }
}
- (NSAttributedString *)attributedStringWithTitle:(NSString *)title value:(NSString *)value {
    if (value == nil) value = @"";
    
    NSFont *boldFont = [NSFont boldSystemFontOfSize:12];
    NSFont *normalFont = [NSFont systemFontOfSize:12];
    NSDictionary *boldStyle = @{NSFontAttributeName:boldFont};
    NSDictionary *normalStyle = @{NSFontAttributeName:normalFont};
    
    NSAttributedString *titleAttr = [[NSAttributedString alloc] initWithString:title attributes:boldStyle];
    NSAttributedString *valueAttr = [[NSAttributedString alloc] initWithString:value attributes:normalStyle];
    NSMutableAttributedString *finalString = [[NSMutableAttributedString alloc] initWithAttributedString:titleAttr];
    [finalString appendAttributedString:valueAttr];
    return finalString;
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
    
    NSArray *keychainsIdentities = [SigningIdentity keychainsIdenities];
    
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
    NSString *archiveBundleID = self.archive.bundleID;
    
    for (Provisioning *provision in self.provisioningArray) {
        //Ignore expired provisioning
        if (provision.isExpired) continue;
        
        if ([provision.applicationIdentifier hasSuffix:@"*"]) {//wildcast appid
            NSString *provisionAppPrefix = [provision.applicationIdentifier substringToIndex:provision.applicationIdentifier.length - 1];
            if (![archiveBundleID hasPrefix:provisionAppPrefix] && provisionAppPrefix.length > 0) {
                continue;
            }
        } else if (![provision.applicationIdentifier isEqual:archiveBundleID]) {
            continue;
        }
        
        NSMenuItem *item = [[NSMenuItem alloc] init];
        item.title = [NSString stringWithFormat:@"%@ (%@)", provision.name, provision.applicationIdentifier];
        
        [item setEnabled:NO];
        [self.popupMenu addItem:item];
        for (SigningIdentity *identity in provision.signingIdentities) {
            BOOL matchInKeychains = NO;
            for (SigningIdentity *keyhainsIdentity in keychainsIdentities) {
                if ([identity.certificateData isEqualToData:keyhainsIdentity.certificateData]) {
                    matchInKeychains = YES;
                    break;
                }
            }
            //The signing identity no found in keychains. So we skip it
            if (!matchInKeychains) continue;
            
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
- (IBAction)reloadIdentities:(id)sender {
    [self buildListIdentity];
    [self lookupBestIdentity];
}
- (void)lookupBestIdentity {
    
    NSString *applicationPath = [self.archive absoluteApplicationPath];
    NSString *embededProvision = [applicationPath stringByAppendingPathComponent:@"embedded.mobileprovision"];
    Provisioning *embed = [[Provisioning alloc] initWithPath:embededProvision];
    SigningIdentity *identity = [embed.signingIdentities firstObject];
    if (!identity) return;
    
    for (NSInteger index = 0; index < self.popupButton.numberOfItems; index++) {
        NSMenuItem *item = [self.popupButton itemAtIndex:index];
        SigningIdentity *itemSigning = item.representedObject;
        if (!itemSigning) continue;
        
        if ([identity.commonName isEqualTo:itemSigning.commonName]) {
            [self.popupButton selectItemAtIndex:index];
            break;
        }
    }
}
@end
