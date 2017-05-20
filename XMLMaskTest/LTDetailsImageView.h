//
//  LTDetailsImageView.h
//  LandmarkTesting
//
//  Created by Mostafizur Rahman on 4/10/17.
//  Copyright © 2017 Mostafizur Rahman. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "Landmarks.h"
#import "FaceLandmarks.h"


@protocol OnLandamarkClicked <NSObject>

-(void)landmarkClickedAtPoint:(NSPoint)clickedPoint;

@end

@interface LTDetailsImageView : IKImageView

@property (readwrite) NSError *error;

-(void)zoomImage:(NSUInteger)zoom;
-(void)setImage:(NSString *)imagePath;
-(void)updateImage:(CGImageRef)inputImageRef;
-(void)loadFaceLanmark:(NSString *)filePath;
-(void)updateLandmark;
-(void)loadNextImage;
-(void)deleteImage;
-(void)updateIndex:(int)value;
-(CGSize)getSize;
-(BOOL)isIndexOutOfBound:(NSUInteger)index;
-(void)jumpToIndex:(NSUInteger)index;
-(FaceLandmarks *)getCurrentFaceLandmark;
-(void)deleteLandmark ;
-(NSUInteger)getCurrentIndex;
-(void)deleteImage:(int)landmarkCount;
-(void)deleteLandmarkRandomly:(int)deleteCount;
@property (readwrite) BOOL shouldDragImage;
@property (readwrite) FaceLandmarks *faceLandmarks;
@property (readwrite) NSTextField *resolutionLabel;
@property (readwrite, weak) id<OnLandamarkClicked> clickedDelegate;
@end
