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
}

@end

@implementation LTDetailsImageView

-(void)drawRect:(NSRect)dirtyRect{
    if(!isLoaded){
        isLoaded = YES;
        
    }
}

-(void)awakeFromNib{
    [self setDoubleClickOpensImageEditPanel: YES];
    [self setCurrentToolMode: IKToolModeMove];
    [self zoomImageToFit: self];
    [self registerForDraggedTypes:@[NSFileType,NSFilenamesPboardType,NSFileTypeSymbolicLink,NSURLPboardType]];
    self.supportsDragAndDrop = YES;
    self.delegate = self;
    
}

-(void)loadFaceLanmark:(NSString *)filePath {
    landmarkHandler = [[LTDlibLandmarksHandler alloc] initWithFilePath:filePath];
}

-(void)updateLandmark {
    [landmarkHandler updateTrainFile];
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

-(void)updateImage:(CGImageRef)inputImageRef {
    [self setImage:inputImageRef imageProperties:(__bridge NSDictionary *)imageProperties];
}

- (void)openImageURL: (NSURL*)url
{
    CGImageRef          image = NULL;
    CGImageSourceRef    isr = CGImageSourceCreateWithURL( (CFURLRef)url, NULL);
    
    if (isr)
    {
        image = CGImageSourceCreateImageAtIndex(isr, 0, NULL);
        if (image)
        {
            NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:NO],
                                     (NSString *)kCGImageSourceShouldCache, nil];
            CFDictionaryRef optionDicRef = (__bridge CFDictionaryRef)(options);
            imageProperties = CGImageSourceCopyPropertiesAtIndex(isr, 0, optionDicRef);
            [self setImage:image imageProperties:(__bridge NSDictionary *)imageProperties];
            
        }
        CFRelease(isr);
    }
}

@end
