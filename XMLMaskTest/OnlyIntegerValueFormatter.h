//
//  OnlyIntegerValueFormatter.h
//  XMLMaskTest
//
//  Created by Mostafizur Rahman on 8/31/16.
//  Copyright © 2016 Mostafizur Rahman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OnlyIntegerValueFormatter : NSNumberFormatter
- (BOOL)isPartialStringValid:(NSString*)partialString newEditingString:(NSString**)newString errorDescription:(NSString**)error;

@end
