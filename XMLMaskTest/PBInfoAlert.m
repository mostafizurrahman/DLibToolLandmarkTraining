//
//  PBInfoAlert.m
//  ImageBucket
//
//  Created by Mostafizur Rahman on 11/26/16.
//  Copyright © 2016 Mostafizur Rahman. All rights reserved.
//

#import "PBInfoAlert.h"

@implementation PBInfoAlert

-(id)init:(NSString *)tag{
    
    self = [super init];
    
    [self setupAlert:tag];
    return self;
}

-(void)setupAlert:(NSString *)tag {
    [self setAccessories:@"empty_dir" accessoryImage:@"broken_link"];
    NSString *title = @"XML error";
    NSString *message = [NSString stringWithFormat:@"Error occured in input xml. Invalid tag or attribute %@"
                         , tag];
    self.informativeText = message;
    self.messageText = title;
}




-(void)setAccessories:(NSString *)iconName accessoryImage:(NSString *)accImageName{
    self.icon = [NSImage imageNamed:iconName];
    NSView *accessoryView = [[NSView alloc] initWithFrame:CGRectMake(0, 0, 275, 100)];
    accessoryView.wantsLayer = YES;
    accessoryView.layer.contents = [NSImage imageNamed:accImageName];
    accessoryView.layer.contentsGravity = kCAGravityResizeAspect;
    self.alertStyle = NSInformationalAlertStyle;
    self.accessoryView = accessoryView;
    [self addButtonWithTitle:@"Okay"];
}
@end
