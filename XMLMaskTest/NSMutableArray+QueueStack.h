//
//  NSMutableArray+QueueStack.h
//  SameImageCutter
//
//  Created by Mostafizur Rahman on 10/17/16.
//  Copyright © 2016 Mostafizur Rahman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (QueueStack)

//@property(readwrite, strong) NSMutableArray* dataArray;
@property(nonatomic, readonly) BOOL empty;
@property(nonatomic, readonly) NSUInteger size;
@property(nonatomic, readonly) id front;
@property(nonatomic, readonly) id back;

- (void)setObject:(id)object at:(long)index ;
- (id)getObjectAt:(long)index;
- (id)dequeue;
- (id)pop;
@end
