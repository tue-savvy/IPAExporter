//
//  Provisioning.h
//  IPAExporter
//
//  Created by Tue Nguyen on 10/10/14.
//  Copyright (c) 2014 HOME. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SigningIdentity.h"

@interface Provisioning : NSObject

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, strong) NSDate *expirationDate;
@property (nonatomic, strong) NSString *applicationIdentifier;
@property (nonatomic, strong) NSArray *provisionedDevices;
@property (nonatomic, strong) NSArray *developerCertificates;
@property (nonatomic, strong) NSArray *signingIdentities;
- (instancetype)initWithPath:(NSString *)path;

- (BOOL)isExpired;
@end
