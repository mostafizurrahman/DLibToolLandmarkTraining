//
//  LTDetailsImageView.m
//  LandmarkTesting
//
//  Created by Mostafizur Rahman on 4/10/17.
//  Copyright © 2017 Mostafizur Rahman. All rights reserved.
//

#import "LTDetailsImageView.h"
#import "LTStaticImageDrawing.h"
#import "LTDlibLandmarksHandler.h"

#define ZOOM_IN_FACTOR  1.414214 // doubles the area
#define ZOOM_OUT_FACTOR 0.7071068 // halves the area
@interface LTDetailsImageView (){
    CFDictionaryRef imageProperties;
    BOOL isLoaded;
    LTDlibLandmarksHandler *landmarkHandler;
    CGSize imageSize;
    NSURL *imageUrl;
}

@end

@implementation LTDetailsImageView

-(void)drawRect:(NSRect)dirtyRect{
    if(!isLoaded){
        isLoaded = YES;
                [[NSCursor arrowCursor] set];
//        [[NSCursor pointingHandCursor] set];
    }
}

-(void)awakeFromNib{
    [self setDoubleClickOpensImageEditPanel: YES];
    [self setCurrentToolMode: IKToolModeMove];
    [self zoomImageToFit: self];
    [self registerForDraggedTypes:@[NSFileType,NSFilenamesPboardType,NSFileTypeSymbolicLink,NSURLPboardType]];
    self.supportsDragAndDrop = YES;
    self.delegate = self;
    self.hasHorizontalScroller = YES;
    self.hasVerticalScroller = YES;
//    self.currentToolMode = IKToolModeMove;
}



-(void)loadFaceLanmark:(NSString *)filePath {
    landmarkHandler = [[LTDlibLandmarksHandler alloc] initWithFilePath:filePath];
    landmarkHandler.currentFaceIndex = 0;
   
}

-(void)updateLandmark {
    [landmarkHandler updateTrainFile];
}

-(void)deleteImage {
    [landmarkHandler deleteImage];
    [self loadNextImage];
}

-(FaceLandmarks *)getCurrentFaceLandmark {
    return [landmarkHandler.trainMaskArray objectAtIndex:landmarkHandler.currentFaceIndex];
}

-(CGSize)getSize{
    return imageSize;
}


-(void)zoomImage:(NSUInteger)zoom
{
    CGFloat   zoomFactor;
    switch (zoom)
    {
        case 0:
            zoomFactor = [self zoomFactor];
            [self setZoomFactor: zoomFactor * ZOOM_OUT_FACTOR];
            break;
        case 1:
            zoomFactor = [self zoomFactor];
            [self setZoomFactor: zoomFactor * ZOOM_IN_FACTOR];
            break;
        case 2:
            [self zoomImageToActualSize: self];
            break;
        case 3:
            [self zoomImageToFit: self];
            break;
    }
}
-(void)setImage:(NSString *)imagePath{
    [self openImageURL:[NSURL fileURLWithPath:imagePath]];
}

-(void)updateIndex:(int)value {
    
    landmarkHandler.currentFaceIndex += value;
    NSInteger indexCount = landmarkHandler.trainMaskArray.count - 1;
    if(landmarkHandler.currentFaceIndex > indexCount){
        landmarkHandler.currentFaceIndex = landmarkHandler.trainMaskArray.count - 1;
    }
    if(landmarkHandler.currentFaceIndex < 0)
    {
        landmarkHandler.currentFaceIndex = 0;
    }
}

-(void)jumpToIndex:(NSUInteger)index{
    landmarkHandler.currentFaceIndex = index;
}

-(NSUInteger)getCurrentIndex {
    return landmarkHandler.currentFaceIndex;
}

-(void)loadNextImage {
    
    [self setImage:((FaceLandmarks *)[landmarkHandler.trainMaskArray objectAtIndex:landmarkHandler.currentFaceIndex]).maskImageName];
}

-(void)updateImage:(CGImageRef)inputImageRef {
    [self setImage:inputImageRef imageProperties:(__bridge NSDictionary *)imageProperties];
}

- (void)openImageURL:(NSURL*)url {
    
    imageUrl = url;
    CGImageRef          image = NULL;
//    CGImageRelease(image);
    CGImageSourceRef    isr = CGImageSourceCreateWithURL( (CFURLRef)imageUrl, NULL);
    if (isr)
    {
        image = CGImageSourceCreateImageAtIndex(isr, 0, NULL);
        if (image)
        {
            NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:NO],
                                     (NSString *)kCGImageSourceShouldCache, nil];
            CFDictionaryRef optionDicRef = (__bridge CFDictionaryRef)(options);
            if(imageProperties != NULL)
            CFRelease(imageProperties);
            imageProperties = CGImageSourceCopyPropertiesAtIndex(isr, 0, optionDicRef);
            [self setImage:image imageProperties:(__bridge NSDictionary *)imageProperties];
            imageSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
            self.resolutionLabel.stringValue = [NSString stringWithFormat:@"%ldx%ld", (long)imageSize.width, (long)imageSize.height];
        }
        CFRelease(isr);
    }
}

-(void)mouseDown:(NSEvent *)event {
    if(self.shouldDragImage){
        [super mouseDown:event];
    }
    else {
        NSPoint point = [event locationInWindow];
        point = [self getConvertedClickedPoint:point];
        [self.clickedDelegate landmarkClickedAtPoint:point];
        
    }
}

-(NSPoint)getConvertedClickedPoint:(NSPoint)point{
    NSPoint cPoint = [self convertViewPointToImagePoint:point];
    cPoint = NSMakePoint(cPoint.x - (int)cPoint.x > 0.5 ? ceil(cPoint.x) : floor(cPoint.x),
                         point.y - (int)cPoint.y > 0.5 ? ceil(cPoint.y) : floor(cPoint.y));
    //NSLog(@"clicked %@", NSStringFromPoint(cPoint));
    return cPoint;
}

-(BOOL)isIndexOutOfBound:(NSUInteger)index {
    return [landmarkHandler.trainMaskArray count] <= index;
}

@end
