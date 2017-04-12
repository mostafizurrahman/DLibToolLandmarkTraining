//
//  LTDetailsViewController.h
//  LandmarkTesting
//
//  Created by Mostafizur Rahman on 4/10/17.
//  Copyright © 2017 Mostafizur Rahman. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FaceLandmarks.h"
#import "LTDetailsImageView.h"

#import "NSView+APForwardDraggingDestination.h"


@interface LTDetailsViewController : NSViewController<NSDraggingDestination>
@property (weak) IBOutlet LTDetailsImageView *detailsImageView;
@property (readwrite) NSString *imagePath;
@property (readwrite) FaceLandmarks *faceLandmark;
@property (weak) IBOutlet NSButton *backgroundCheckbox;
@property (readwrite) NSImage *inputImage;

@property (weak) IBOutlet NSLayoutConstraint *bottomSpace;

@end
