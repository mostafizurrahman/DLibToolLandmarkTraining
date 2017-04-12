//
//  FaceLandmarks.h
//  IPVFaceDetection
//
//  Created by Mostafizur Rahman on 8/18/16.
//  Copyright © 2016 Mostafizur Rahman. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface FaceRect : NSObject

@property (readwrite) NSInteger left;
@property (readwrite) NSInteger width;
@property (readwrite) NSInteger top;
@property (readwrite) NSInteger height;
@end
@interface FaceLandmarks : NSObject

@property (readwrite) FaceRect *box;
@property (readwrite) NSInteger landmarksCount;
@property (readwrite) NSInteger maskHeight;
@property (readwrite) NSInteger maskWidth;
@property (readwrite) NSString *maskTitle;
@property (readwrite) NSString *maskImageName;
@property (readwrite) id imageView;
@property (readwrite) NSImage *inputImage;

@property (readwrite) NSMutableArray *landmarksArray;
@end
