//
//  XcodeArchive.m
//  IPAExporter
//
//  Created by Tue Nguyen on 10/11/14.
//  Copyright (c) 2014 HOME. All rights reserved.
//

#import "XcodeArchive.h"
#import <AppKit/AppKit.h>
@interface XcodeArchive()
@property (nonatomic, strong) NSString *applicationPath;
@end
@implementation XcodeArchive
- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        self.path = path;
        [self _loadArchiveInfo];
    }
    return self;
}
- (void)_loadArchiveInfo {
    NSString *archivePlist = [self.path stringByAppendingPathComponent:@"Info.plist"];
    NSDictionary *infoDictionary = [NSDictionary dictionaryWithContentsOfFile:archivePlist];
    if (infoDictionary) {
        
        
        self.name = infoDictionary[@"Name"];
        self.creationDate = infoDictionary[@"CreationDate"];
        NSDictionary *applicationProperties = infoDictionary[@"ApplicationProperties"];
        self.applicationPath = applicationProperties[@"ApplicationPath"];
        
        self.bundleID = applicationProperties[@"CFBundleIdentifier"];
        self.version = applicationProperties[@"CFBundleVersion"];
        self.iconPaths = applicationProperties[@"IconPaths"];
        self.isValidArchive = YES;
        
        [self _readApplicationInfo];
        [self _findBestIcons];
    } else {
        self.isValidArchive = NO;
    }
}
- (void)_readApplicationInfo {
    NSString *productsPath = [self.path stringByAppendingPathComponent:@"Products"];
    self.absoluteApplicationPath = [productsPath stringByAppendingPathComponent:self.applicationPath];
    NSString *applicationInfoPath = [self.absoluteApplicationPath stringByAppendingPathComponent:@"Info.plist"];
    NSDictionary *appInfo = [NSDictionary dictionaryWithContentsOfFile:applicationInfoPath];
    self.applicationName = appInfo[@"CFBundleDisplayName"];
    
    if (!self.applicationName) {
        self.applicationName = appInfo[@"CFBundleName"];
    }
    
    if ([appInfo[@"DTPlatformName"] isEqualTo:@"iphoneos"]) {
        self.isIOSArchive = YES;
    } else {
        self.isIOSArchive = NO;
    }
}
- (void)_findBestIcons {
    NSString *productsPath = [self.path stringByAppendingPathComponent:@"Products"];
    NSImage *bestImage = nil;
    for (NSString *iconSubPath in self.iconPaths) {
        NSString *iconPath = [productsPath stringByAppendingPathComponent:iconSubPath];
        
        NSImage *image = [[NSImage alloc] initWithContentsOfFile:iconPath];
        if (!bestImage) bestImage = image;
        else if (bestImage.size.width < image.size.width) {
            bestImage = image;
        }
    }
    self.applicationIcon = bestImage;
}
@end
