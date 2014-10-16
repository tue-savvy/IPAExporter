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
    [self loadXcodeArchives];
    [self registerDirectoryWatcher];
}

- (NSString *)archiveDirectoryPath {
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    NSString *archivesFolderPath = [libraryPath stringByAppendingPathComponent:@"Developer/Xcode/Archives"];
    return archivesFolderPath;
}

- (void)loadXcodeArchives {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *archivesFolderPath = [self archiveDirectoryPath];
        NSArray *contents = [fm contentsOfDirectoryAtPath:archivesFolderPath error:nil];
        
        NSMutableArray *allArchives = [NSMutableArray array];
        for (NSString *folder in contents) {
            NSString *subfolder = [archivesFolderPath stringByAppendingPathComponent:folder];
            NSArray *archiveFiles = [fm contentsOfDirectoryAtPath:subfolder error:nil];
            for (NSString *archiveName in archiveFiles) {
                NSString *archivePath = [subfolder stringByAppendingPathComponent:archiveName];
                XcodeArchive *archive = [[XcodeArchive alloc] initWithPath:archivePath];
                if (archive.isValidArchive && archive.isIOSArchive) {
                    [allArchives addObject:archive];
                }
            }
        }
        [allArchives sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]]];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.archives = allArchives;
            [self.tableView reloadData];
            NSInteger selectedRow = [self.tableView selectedRow];
            if (selectedRow >= 0 && selectedRow < self.archives.count) {
                self.selectedArchive = self.archives[selectedRow];
            } else {
                self.selectedArchive = nil;
            }
        });
    });
}
- (void)registerDirectoryWatcher {
    if (!self.archiveWatchers) self.archiveWatchers = [NSMutableArray array];
    for (DirectoryWatcher *watcher in self.archiveWatchers) {
        [watcher invalidate];
    }
    NSString *archiveFolder = [self archiveDirectoryPath];
    DirectoryWatcher *watcher = [DirectoryWatcher watchFolderWithPath:archiveFolder delegate:self];
    [self.archiveWatchers addObject:watcher];
    
    NSArray *subfolders = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:archiveFolder error:nil];
    for (NSString *name in subfolders) {
        if ([name hasPrefix:@"."]) continue;
        NSString *subPath = [archiveFolder stringByAppendingPathComponent:name];
        BOOL isDirectory = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:subPath isDirectory:&isDirectory] && isDirectory) {
            watcher = [DirectoryWatcher watchFolderWithPath:subPath delegate:self];
            [self.archiveWatchers addObject:watcher];
        }
    }
}

#pragma mark - DirectoryWatcherDelegate
- (void)directoryDidChange:(DirectoryWatcher *)folderWatcher {
    [self loadXcodeArchives];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self registerDirectoryWatcher];
    });
}

#pragma mark - NSTableView
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.archives count];
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return self.archives[row];
}
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    TableAppCellView *view = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:self];
    XcodeArchive *archive = [self tableView:tableView objectValueForTableColumn:tableColumn row:row];
    view.textField.stringValue = archive.applicationName;
    view.creationLabel.stringValue = [archive.creationDate relativeTime];
    view.imageView.image = archive.applicationIcon;
    return view;
}
- (void)tableViewSelectionIsChanging:(NSNotification *)notification {
    NSInteger selectedRow = [self.tableView selectedRow];
    if (selectedRow >= 0 && selectedRow < self.archives.count) {
        self.selectedArchive = self.archives[selectedRow];
    } else {
        self.selectedArchive = nil;
    }
}
#pragma mark - SelectedArchive
- (void)setSelectedArchive:(XcodeArchive *)selectedArchive {
    _selectedArchive = selectedArchive;
    self.selectedArchiveImageView.image = _selectedArchive.applicationIcon;
    self.selectedAppName.stringValue = _selectedArchive.applicationName;
    self.selectedProjectName.stringValue = _selectedArchive.name;
    
    self.selectedCreationDate.attributedStringValue = [self attributedStringWithTitle:@"Creation Date: " value:[_selectedArchive.creationDate relativeTime]];
    self.selectedVersion.attributedStringValue = [self attributedStringWithTitle:@"Version: " value:_selectedArchive.version];
    self.selectedIdentifier.attributedStringValue = [self attributedStringWithTitle:@"Identifier: " value:_selectedArchive.bundleID];
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

- (IBAction)exportIPA:(id)sender {
    if (!self.selectedArchive) return;
    
    
    if (!self.exportWindowController) {
        self.exportWindowController = [[ExportWindowController alloc] initWithWindowNibName:@"ExportWindowController"];
        self.exportWindowController.plugInBundle = self.plugInBundle;
    }
    self.exportWindowController.archive = self.selectedArchive;
    [self.window beginSheet:self.exportWindowController.window completionHandler:^(NSModalResponse returnCode) {
        
    }];
}

@end
