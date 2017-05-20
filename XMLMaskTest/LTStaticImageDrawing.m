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
    NSRect imgRect = NSMakeRect(0.0, 0.0, width, height);
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
     
        if(!faceLandmarks.inputImage)
        {
            faceLandmarks.inputImage = [[NSImage alloc] initWithContentsOfFile:faceLandmarks.maskImageName];
        }
        CFDataRef cfdRef = (__bridge CFDataRef)[faceLandmarks.inputImage TIFFRepresentation];
        source = CGImageSourceCreateWithData(cfdRef, NULL);
        CGImageRef imgRef =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
        CGContextDrawImage(contextRef, imgRect, imgRef);
        CGImageRelease(imgRef);
        CFRelease(cfdRef);
        source = NULL;
    }
    CGFontRef font = CGFontCreateWithFontName((CFStringRef)@"Courier Bold");
    [[NSColor magentaColor] setStroke];
    CGContextSetFont(contextRef, font);
   
    for (int i = 0; i < numObjects; i++)
    {
        [graphicsContext saveGraphicsState];
        Landmarks *faceLandmarks = [landmarksArray objectAtIndex:i];
        if (faceLandmarks.isEdited) {
            CGContextSetLineWidth(contextRef, 2.5); // set the line width
            CGContextSetRGBStrokeColor(contextRef, 255, 101.0 / 255.0, 18.0 / 255.0, 1.0);
            CGContextAddArc(contextRef, faceLandmarks.xCoodinate,height - faceLandmarks.yCoodinate, 10, -3.1416, 3.1416, 0); // create an arc the +4 just adds some pixels because of the polygon line thickness
            CGContextStrokePath(contextRef);
            NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:25], NSFontAttributeName,textColor, NSForegroundColorAttributeName, nil];
            NSAttributedString * currentText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld",(long)faceLandmarks.landmarkIndex] attributes: attributes];
            [currentText drawAtPoint:NSMakePoint(faceLandmarks.xCoodinate, height - faceLandmarks.yCoodinate)];
            //            faceLandmarks.isEdited = false;
        }
        else if(sampleType == 1){
            NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:25], NSFontAttributeName, textColor, NSForegroundColorAttributeName, nil];
            NSAttributedString *currentText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld",(long)faceLandmarks.landmarkIndex] attributes: attributes];
            [currentText drawAtPoint:NSMakePoint(faceLandmarks.xCoodinate, height - faceLandmarks.yCoodinate)];
        }
        [graphicsContext restoreGraphicsState];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate y: faceLandmarks.yCoodinate];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate+1 y: faceLandmarks.yCoodinate+1];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate-1 y: faceLandmarks.yCoodinate-1];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate+1 y: faceLandmarks.yCoodinate-1];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate-1 y: faceLandmarks.yCoodinate+1];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate y: faceLandmarks.yCoodinate+1];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate-1 y: faceLandmarks.yCoodinate];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate+1 y: faceLandmarks.yCoodinate];
        [offscreenRep setColor:dotColor atX:faceLandmarks.xCoodinate y: faceLandmarks.yCoodinate-1];
    }
    CGContextBeginPath(contextRef);
    
    float topBox = (float)height - (float)faceLandmarks.box.top;
    float bottomHeight = (float)height - (float)faceLandmarks.box.height - (float)faceLandmarks.box.top;
    
    
    
    
    CGContextMoveToPoint(contextRef, faceLandmarks.box.left, topBox);
    CGContextAddLineToPoint(contextRef, faceLandmarks.box.left + faceLandmarks.box.width, topBox);
    CGContextAddLineToPoint(contextRef, faceLandmarks.box.left + faceLandmarks.box.width, bottomHeight );
    CGContextAddLineToPoint(contextRef, faceLandmarks.box.left, bottomHeight);
    CGContextAddLineToPoint(contextRef, faceLandmarks.box.left, topBox);
    
    
    
    CGContextClosePath(contextRef);
    CGContextStrokePath(contextRef);
    [NSGraphicsContext restoreGraphicsState];
    CFRelease(contextRef);
    NSImage *img = [[NSImage alloc] initWithSize:imgSize] ;
    [img addRepresentation:offscreenRep];
    offscreenRep = nil;
    return img;
}
@end
