//
//  LTStaticImageDrawing.h
//  LandmarkTesting
//
//  Created by Mostafizur Rahman on 4/10/17.
//  Copyright © 2017 Mostafizur Rahman. All rights reserved.
//


#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

#import "FaceLandmarks.h"
#import "Landmarks.h"
@interface LTStaticImageDrawing : NSObject

+(NSImage *)drawImage:(NSColor *)textColor dotColor:(NSColor *)dotColor
        landmark:(FaceLandmarks *)faceLandmarks height:(NSUInteger) height
           width:(NSUInteger)width type:(NSUInteger)sampleType;
@end
