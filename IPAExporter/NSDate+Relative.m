//
//  DateHelper.m
//  IPAExporter
//
//  Created by Tue Nguyen on 10/11/14.
//  Copyright (c) 2014 HOME. All rights reserved.
//

#import "NSDate+Relative.h"

@implementation NSDate(Relative)
- (NSString *)relativeTime {
    return [[self class] relativeTime:self];
}
+ (NSString *)relativeTime:(NSDate *)aDate {
    static dispatch_once_t onceToken;
    static NSDateFormatter *todayFormatter;
    static NSDateFormatter *yesterdayFormatter;
    static NSDateFormatter *weekFormatter;
    static NSDateFormatter *monthFormatter;
    static NSDateFormatter *yearFormatter;
    dispatch_once(&onceToken, ^{
        todayFormatter = [NSDateFormatter new];
        todayFormatter.dateFormat = @"h:mm a";
        
        yesterdayFormatter = [NSDateFormatter new];
        yesterdayFormatter.dateFormat = @"'Yesterday at' h:mm a";
        
        weekFormatter = [NSDateFormatter new];
        weekFormatter.dateFormat = @"EEEE 'at' h:mm a";
        
        monthFormatter = [NSDateFormatter new];
        monthFormatter.dateFormat = @"MMM dd 'at' h:mm a";
        
        yearFormatter = [NSDateFormatter new];
        yearFormatter.dateFormat = @"MMM dd yyyy";
    });
    
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    unsigned int unitFlags =  NSYearCalendarUnit|NSMonthCalendarUnit|NSWeekCalendarUnit|NSWeekdayOrdinalCalendarUnit|NSWeekdayCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit;
    NSDateComponents *messageDateComponents = [calendar components:unitFlags fromDate:aDate];
    NSDateComponents *todayDateComponents = [calendar components:unitFlags fromDate:[NSDate date]];
    
    NSUInteger dayOfYearForMessage = [calendar ordinalityOfUnit:NSDayCalendarUnit inUnit:NSYearCalendarUnit forDate:aDate];
    NSUInteger dayOfYearForToday = [calendar ordinalityOfUnit:NSDayCalendarUnit inUnit:NSYearCalendarUnit forDate:[NSDate date]];
    
    
    NSString *dateString;
    //Same day
    if ([messageDateComponents year] == [todayDateComponents year] &&
        [messageDateComponents month] == [todayDateComponents month] &&
        [messageDateComponents day] == [todayDateComponents day])
    {
        dateString = [todayFormatter stringFromDate:aDate];
    } else if ([messageDateComponents year] == [todayDateComponents year] &&
               dayOfYearForMessage == (dayOfYearForToday-1))
    {
        dateString = [yesterdayFormatter stringFromDate:aDate];
    } else if ([messageDateComponents year] == [todayDateComponents year] &&
               dayOfYearForMessage > (dayOfYearForToday-6))
    {
        dateString = [weekFormatter stringFromDate:aDate];
        
    } else if ([messageDateComponents year] == [todayDateComponents year]) {
        dateString = [monthFormatter stringFromDate:aDate];
    } else {
        dateString = [yearFormatter stringFromDate:aDate];
    }
    
    return dateString;
}
@end
