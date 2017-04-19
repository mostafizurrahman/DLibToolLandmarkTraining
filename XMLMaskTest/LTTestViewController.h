//
//  ViewController.h
//  XMLMaskTest
//
//  Created by Mostafizur Rahman on 8/18/16.
//  Copyright © 2016 Mostafizur Rahman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "NSView+APForwardDraggingDestination.h"
#import "DragDropImageView.h"
#import "OnlyIntegerValueFormatter.h"

#import "LandmaskXMLParser.h"
@interface ViewController : NSViewController<NSDraggingDestination, DragDropImageViewDelegate, ParsingDidEndDelegate>

@property (strong) IBOutlet NSTextField *statusLable;
@property (strong) IBOutlet NSTextField *xmlTextField;
@property (strong) IBOutlet NSTextField *imageTextField;
@property (strong) IBOutlet NSImageView *standardImageView;
@property (strong) IBOutlet DragDropImageView *imageView;
@property (strong) IBOutlet NSTextFieldCell *errorLabel;
@property (nonatomic) NSColorPanel *colorPanel;
@property (strong) IBOutlet NSTextField *vertextTextField;
@property (weak) NSColorWell *updatingColorWell;
@end

