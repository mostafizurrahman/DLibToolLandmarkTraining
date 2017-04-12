//
//  LTDetailsViewController.m
//  LandmarkTesting
//
//  Created by Mostafizur Rahman on 4/10/17.
//  Copyright © 2017 Mostafizur Rahman. All rights reserved.
//

#import "LTDetailsViewController.h"
#import "LTStaticImageDrawing.h"



@interface LTDetailsViewController ()
{
    BOOL isProcessing;
    NSUInteger imageWH;
    NSMutableDictionary *undoDictionary;
}
@end

@implementation LTDetailsViewController
void* const ColorPanelContext = (void*)1001;

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resizeWindow) name:NSWindowDidResizeNotification object:nil];
    [self.detailsImageView setImage:self.imagePath];
    imageWH = CGImageGetWidth(self.detailsImageView.image);
    [self.detailsImageView ap_forwardDraggingDestinationTo:self];
    undoDictionary = [[NSMutableDictionary alloc] init];
}

-(void)viewWillAppear {
    [super viewWillAppear];
    NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
    [colorPanel addObserver:self forKeyPath:@"color" options:0 context:ColorPanelContext];
}

- (IBAction)zoomIn:(id)sender {
    [self.detailsImageView zoomImage:1];
}
- (IBAction)zoomOut:(id)sender {
    [self.detailsImageView zoomImage:0];
}
- (IBAction)aspectZoom:(id)sender {
    [self.detailsImageView zoomImage:2];
}
- (IBAction)fitZoom:(id)sender {
    [self.detailsImageView zoomImage:3];
}

-(void)resizeWindow {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CGRect frame = self.presentingViewController.view.frame;
        [self.view.window setFrame:frame display:YES animate:YES];
        self.view.frame = frame;
    });
}

- (IBAction)exitApp:(id)sender {
    
    for (NSWindow *window in [NSApplication sharedApplication].windows) {
        [window close];
    }
    [NSApp terminate:self];
}
- (IBAction)hideDetailsView:(id)sender {
    [self dismissViewController:self];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    NSColor *color = ((NSColorPanel *)object).color;
    if(self.backgroundCheckbox.state == 1){
        self.detailsImageView.backgroundColor = color;
        return;
    }
    NSColor *dotColor = [NSColor colorWithCalibratedRed:1.0f - color.redComponent  green: 1.0f - color.blueComponent blue: 1.0f - color.redComponent alpha:1.0];
    if (!isProcessing)
    {
        isProcessing = true;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
           NSImage *someImage = [LTStaticImageDrawing drawImage:((NSColorPanel *)object).color dotColor:dotColor landmark:self.faceLandmark height:imageWH width:imageWH type:0];
            dispatch_async(dispatch_get_main_queue(), ^{
                CGImageSourceRef source;
                
                source = CGImageSourceCreateWithData((CFDataRef)[someImage TIFFRepresentation], NULL);
                CGImageRef maskRef =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
                [self.detailsImageView updateImage:maskRef];
                CGImageRelease(maskRef);
                isProcessing = false;
            });
        });
    }
}
- (IBAction)showColorPanel:(id)sender {
    NSColorPanel *panel = [NSColorPanel sharedColorPanel];
    [panel orderFront:nil];
    [panel setTarget:self];
    [panel makeKeyAndOrderFront:self];
}


- (void)animateViewToFrame:(CGFloat)frameValue {
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.3];
    self.bottomSpace.constant = frameValue;
    [self.detailsImageView setNeedsDisplay:YES];
    [NSAnimationContext endGrouping];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return true;
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pasteboard = [sender draggingPasteboard];
    NSArray *fileArray = [pasteboard propertyListForType:NSFilenamesPboardType];
    NSString *pathString = [fileArray firstObject];
    if([[pathString pathExtension] isEqualToString:@"xml"])
    {
        [self.detailsImageView loadFaceLanmark:pathString];
        [self animateViewToFrame:70];
    }
    else {
        [self animateViewToFrame:0];
    }
    return YES;
}
-(void)dropComplete:(NSArray *)fileArray
{
    
}
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    return [self draggingEntered:sender];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
    
}
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    return NSDragOperationGeneric;
}


- (IBAction)readNextImage:(id)sender {
}

- (IBAction)resetCurrentImage:(id)sender {
}
- (IBAction)readPreviousImage:(id)sender {
}

- (void)keyDown:(NSEvent *)theEvent {
    
    [self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
    NSString *theArrow = [theEvent charactersIgnoringModifiers];
}

- (IBAction)updateLandmarks:(id)sender {
    [self.detailsImageView updateLandmark];
}

@end
