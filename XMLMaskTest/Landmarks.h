//
//  Landmarks.h
//  IPVFaceDetection
//
//  Created by Mostafizur Rahman on 8/18/16.
//  Copyright © 2016 Mostafizur Rahman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Landmarks : NSObject
@property (readwrite) BOOL isEdited;
@property (readwrite) NSInteger xCoodinate;
@property (readwrite) NSInteger yCoodinate;
@property (readwrite) NSInteger landmarkIndex;
-(instancetype)initWith:(NSUInteger)index xCoord:(NSInteger)xcoord yCoord:(NSInteger)ycoord;
@end

