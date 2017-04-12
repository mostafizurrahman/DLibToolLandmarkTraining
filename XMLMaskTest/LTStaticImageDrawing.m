//
//  LTStaticImageDrawing.m
//  LandmarkTesting
//
//  Created by Mostafizur Rahman on 4/10/17.
//  Copyright © 2017 Mostafizur Rahman. All rights reserved.
//

#import "LTStaticImageDrawing.h"

@implementation LTStaticImageDrawing

+(NSImage *)drawImage:(NSColor *)textColor dotColor:(NSColor *)dotColor
        landmark:(FaceLandmarks *)faceLandmarks height:(NSUInteger) height
           width:(NSUInteger)width type:(NSUInteger)sampleType
{
    NSMutableArray *landmarksArray = faceLandmarks.landmarksArray;
    NSUInteger numObjects = [landmarksArray count];
    if (!numObjects) {
        return nil;
    }
    NSRect imgRect = NSMakeRect(0.0, 0.0, height, height);
    NSSize imgSize = imgRect.size;
    __block NSBitmapImageRep *offscreenRep = [[NSBitmapImageRep alloc]
                                              initWithBitmapDataPlanes:NULL
                                              pixelsWide:width
                                              pixelsHigh:height
                                              bitsPerSample:8
                                              samplesPerPixel:4
                                              hasAlpha:YES
                                              isPlanar:NO
                                              colorSpaceName:NSDeviceRGBColorSpace
                                              bitmapFormat:NSAlphaFirstBitmapFormat
                                              bytesPerRow:0
                                              bitsPerPixel:0];
    NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:offscreenRep];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:graphicsContext];
    CGContextRef contextRef = [NSGraphicsContext.currentContext graphicsPort];
    CFRetain(contextRef);
    if (sampleType == 0 || sampleType == 1) {
        CGImageSourceRef source;
        CFDataRef cfdRef = (__bridge CFDataRef)[faceLandmarks.inputImage TIFFRepresentation];
        source = CGImageSourceCreateWithData(cfdRef, NULL);
        CGImageRef imgRef =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
        CGContextDrawImage(contextRef, imgRect, imgRef);
        CGImageRelease(imgRef);
        CFRelease(cfdRef);
        source = NULL;
    }
    int i;
    CGFontRef font = CGFontCreateWithFontName((CFStringRef)@"Courier Bold");
    CGContextSetFont ( contextRef, font );
    for (i = 0; i < numObjects; i++)
    {
        [graphicsContext saveGraphicsState];
        Landmarks *faceLandmarks = [landmarksArray objectAtIndex:i];
        if (faceLandmarks.isEdited) {
            CGContextSetLineWidth(contextRef, 2.5); // set the line width
            CGContextSetRGBStrokeColor(contextRef, 255, 101.0 / 255.0, 18.0 / 255.0, 1.0);
            CGContextAddArc(contextRef, faceLandmarks.xCoodinate, height - faceLandmarks.yCoodinate, 10, -3.1416, 3.1416, 0); // create an arc the +4 just adds some pixels because of the polygon line thickness
            CGContextStrokePath(contextRef);
            //            faceLandmarks.isEdited = false;
        }
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:13], NSFontAttributeName,textColor, NSForegroundColorAttributeName, nil];
        NSAttributedString * currentText=[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld",(long)faceLandmarks.landmarkIndex] attributes: attributes];
        [currentText drawAtPoint:NSMakePoint(faceLandmarks.xCoodinate, height - faceLandmarks.yCoodinate)];
        [graphicsContext restoreGraphicsState];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate y:faceLandmarks.yCoodinate];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate+1 y:faceLandmarks.yCoodinate+1];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate-1 y:faceLandmarks.yCoodinate-1];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate+1 y:faceLandmarks.yCoodinate-1];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate-1 y:faceLandmarks.yCoodinate+1];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate y:faceLandmarks.yCoodinate+1];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate-1 y:faceLandmarks.yCoodinate];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate+1 y:faceLandmarks.yCoodinate];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate y:faceLandmarks.yCoodinate-1];
        
        
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate+2 y:faceLandmarks.yCoodinate+2];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate-2 y:faceLandmarks.yCoodinate-2];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate+2 y:faceLandmarks.yCoodinate-2];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate-2 y:faceLandmarks.yCoodinate+2];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate y:faceLandmarks.yCoodinate+2];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate-2 y:faceLandmarks.yCoodinate];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate+2 y:faceLandmarks.yCoodinate];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate y:faceLandmarks.yCoodinate-2];
    }
    [NSGraphicsContext restoreGraphicsState];
    CFRelease(contextRef);
    NSImage *img = [[NSImage alloc] initWithSize:imgSize] ;
    [img addRepresentation:offscreenRep];
    offscreenRep = nil;
    return img;
}
@end
