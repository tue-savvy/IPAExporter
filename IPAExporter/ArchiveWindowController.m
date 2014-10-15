//
//  ArchiveWindowController.m
//  IPAExporter
//
//  Created by Tue Nguyen on 10/16/14.
//  Copyright (c) 2014 Pharaoh. All rights reserved.
//

#import "ArchiveWindowController.h"
#import <Security/Security.h>
#import "Provisioning.h"
#import "XcodeArchive.h"
#import "TableAppCellView.h"
#import "NSDate+Relative.h"
#import "ExportWindowController.h"
#import "DirectoryWatcher.h"

@interface ArchiveWindowController ()<NSTableViewDataSource, NSTableViewDelegate, DirectoryWatcherDelegate>
@property (nonatomic, strong) NSMutableArray *archives;
@property (weak) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) XcodeArchive *selectedArchive;
@property (weak) IBOutlet NSImageView *selectedArchiveImageView;
@property (weak) IBOutlet NSTextField *selectedAppName;
@property (weak) IBOutlet NSTextField *selectedProjectName;
@property (weak) IBOutlet NSTextField *selectedCreationDate;
@property (weak) IBOutlet NSTextField *selectedVersion;
@property (weak) IBOutlet NSTextField *selectedIdentifier;
@property (nonatomic, strong) NSMutableArray *archiveWatchers;
@property (nonatomic, strong) ExportWindowController *exportWindowController;
@end

@implementation ArchiveWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
