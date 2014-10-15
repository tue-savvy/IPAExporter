//
//  IPAExporterPlugIn.h
//  IPAExporterPlugIn
//
//  Created by Tue Nguyen on 10/16/14.
//  Copyright (c) 2014 Pharaoh. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface IPAExporterPlugIn : NSObject

+ (instancetype)sharedPlugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end