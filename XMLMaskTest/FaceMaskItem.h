//
//  FaceMaskItem.h
//  IPVFaceDetection
//
//  Created by Mostafizur Rahman on 8/16/16.
//  Copyright © 2016 Mostafizur Rahman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FaceMaskItem : NSObject
@property (readwrite) NSString *imageName;
@property (readwrite) NSString *title;
@property (readwrite) NSInteger itemID;
@property (readwrite) NSString *landmakrFile;
@end
