//
//  LTDlibLandmarksHandler.h
//  LandmarkTesting
//
//  Created by Mostafizur Rahman on 4/11/17.
//  Copyright © 2017 Mostafizur Rahman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LTDetailsImageView.h"
#define LANDMARK_COUNT 68
@interface LTDlibLandmarksHandler : NSObject

@property (readwrite) NSError *error;
@property (readwrite) LTDetailsImageView *detailsView;
@property (readonly)     NSMutableArray *trainMaskArray;
@property (readwrite) NSInteger currentFaceIndex;


-(instancetype)initWithFilePath:(NSString *)filePath;
-(BOOL)updateTrainFile;
-(void)deleteImage;
-(void)deleteLandmark:(int)index;
-(void)deleteLandmarkRandmoly:(int)deleteCount ;
@end
