//
//  DateHelper.h
//  IPAExporter
//
//  Created by Tue Nguyen on 10/11/14.
//  Copyright (c) 2014 HOME. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate(Relative)
- (NSString *)relativeTime;
+ (NSString *)relativeTime:(NSDate *)aDate;
@end
