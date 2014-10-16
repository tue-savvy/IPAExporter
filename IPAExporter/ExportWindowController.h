//
//  ExportWindowController.h
//  IPAExporter
//
//  Created by Tue Nguyen on 10/11/14.
//  Copyright (c) 2014 HOME. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class XcodeArchive;
@interface ExportWindowController : NSWindowController
@property (nonatomic, strong) XcodeArchive *archive;
@property (strong, nonatomic) NSBundle *plugInBundle;
@end
