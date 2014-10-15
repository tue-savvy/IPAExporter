//
//  SigningIdentity.h
//  IPAExporter
//
//  Created by Tue Nguyen on 10/11/14.
//  Copyright (c) 2014 HOME. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Provisioning;
@interface SigningIdentity : NSObject
@property (nonatomic, strong) NSString *commonName;
@property (nonatomic, weak) Provisioning *provision;
@property (nonatomic, strong, readonly) NSData *certificateData;
- (instancetype)initWithProvision:(Provisioning *)provision certificateData:(NSData *)certificateData;
/* Return only valid keychains certificate from Keychains */
+ (NSArray *)keychainsIdenities;
@end
