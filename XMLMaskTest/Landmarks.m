//
//  Landmarks.m
//  IPVFaceDetection
//
//  Created by Mostafizur Rahman on 8/18/16.
//  Copyright © 2016 Mostafizur Rahman. All rights reserved.
//

#import "Landmarks.h"

@implementation Landmarks
-(instancetype)initWith:(NSUInteger)index xCoord:(NSInteger)xcoord yCoord:(NSInteger)ycoord {
    self = [super init];
    self.landmarkIndex = index;
    self.xCoodinate = xcoord;
    self.yCoodinate = ycoord;
    return self;
}
@end

