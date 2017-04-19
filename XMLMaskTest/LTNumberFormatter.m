//
//  LTNumberFormatter.m
//  LandmarkTesting
//
//  Created by Mostafizur Rahman on 4/16/17.
//  Copyright © 2017 Mostafizur Rahman. All rights reserved.
//

#import "LTNumberFormatter.h"

@implementation LTNumberFormatter
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
}

@end
