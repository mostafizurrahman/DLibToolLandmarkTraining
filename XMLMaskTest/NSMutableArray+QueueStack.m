//
//  NSMutableArray+QueueStack.m
//  SameImageCutter
//
//  Created by Mostafizur Rahman on 10/17/16.
//  Copyright © 2016 Mostafizur Rahman. All rights reserved.
//

#import "NSMutableArray+QueueStack.h"

@implementation NSMutableArray (QueueStack)

- (id)init {
    return [super init];
}
-(NSMutableArray *)getDataArray{
    return self;
}

- (NSUInteger)size {
    return self.count;
}
- (id)front {
    return self.firstObject;
}
- (id)back {
    return self.lastObject;
}

- (id)dequeue {
    id firstObject = nil;
    if (!self.empty) {
        firstObject  = self.firstObject;
        [self removeObjectAtIndex:0];
    }
    return firstObject;
}

-(id)pop{
    id object = nil;
    if (!self.empty) {
        object = self.lastObject;
        [self removeObject:object];
    }
    return object;
}
- (BOOL)empty {
    return self.count == 0;
}
-(id)getObjectAt:(long)index {
    return  [self objectAtIndex:[self getValidIndex:index]];
}

-(void)setObject:(id)object at:(long)index {
    [self insertObject:object atIndex:[self getValidIndex:index]];
}

-(long)getValidIndex:(long)index {
    if (index < 0) {
        return 0;
    }
    else if(index >= self.count) {
        return self.count - 1;
    }
    return index;
}
@end
