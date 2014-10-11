//
//  TableAppCellView.m
//  IPAExporter
//
//  Created by Tue Nguyen on 10/11/14.
//  Copyright (c) 2014 HOME. All rights reserved.
//

#import "TableAppCellView.h"

@implementation TableAppCellView
- (void) setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
    [super setBackgroundStyle:backgroundStyle];
    
    NSTableRowView *row = (NSTableRowView*)self.superview;
    if (row.isSelected) {
        self.creationLabel.textColor = [NSColor alternateSelectedControlTextColor];
    } else {
        self.creationLabel.textColor = [NSColor grayColor];
    }
    
}
@end
