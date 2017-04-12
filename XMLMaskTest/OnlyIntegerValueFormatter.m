//
//  OnlyIntegerValueFormatter.m
//  XMLMaskTest
//
//  Created by Mostafizur Rahman on 8/31/16.
//  Copyright © 2016 Mostafizur Rahman. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import "OnlyIntegerValueFormatter.h"

@implementation OnlyIntegerValueFormatter
- (BOOL)isPartialStringValid:(NSString*)partialString newEditingString:(NSString**)newString errorDescription:(NSString**)error
{
    if([partialString length] == 0) {
        return YES;
    }
    
    NSScanner* scanner = [NSScanner scannerWithString:partialString];
    
    if(!([scanner scanInt:0] && [scanner isAtEnd])) {
        NSBeep();
        return NO;
    }
    
    return YES;
}@end
