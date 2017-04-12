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

@interface LTDetailsImageView : IKImageView

-(void)zoomImage:(NSUInteger)zoom;
-(void)setImage:(NSString *)imagePath;
-(void)updateImage:(CGImageRef)inputImageRef;
-(void)loadFaceLanmark:(NSString *)filePath;
-(void)updateLandmark;
@property (readwrite) FaceLandmarks *faceLandmarks;


@end
