//
//  XcodeArchive.h
//  IPAExporter
//
//  Created by Tue Nguyen on 10/11/14.
//  Copyright (c) 2014 HOME. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XcodeArchive : NSObject
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *bundleID;
@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSArray *iconPaths;
@property (nonatomic, assign) BOOL isValidArchive;
@property (nonatomic, assign) BOOL isIOSArchive;

@property (nonatomic, strong) NSImage *applicationIcon;
@property (nonatomic, strong) NSString *applicationName;
@property (nonatomic, strong) NSString *absoluteApplicationPath;
- (instancetype)initWithPath:(NSString *)path;
@end
