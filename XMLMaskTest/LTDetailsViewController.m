//
//  LTDetailsViewController.m
//  LandmarkTesting
//
//  Created by Mostafizur Rahman on 4/10/17.
//  Copyright © 2017 Mostafizur Rahman. All rights reserved.
//

#import "LTDetailsViewController.h"
#import "LTStaticImageDrawing.h"

#import "LTNumberFormatter.h"




@interface LTDetailsViewController ()
{
    BOOL isProcessing;
    NSUInteger imageWidth;
    NSUInteger imageHeight;
    NSMutableDictionary *undoDictionary;
    Landmarks *currentLandmark;
    Landmarks *previousLandmark;
    NSUInteger drawingType;
    NSPoint scrollPoint;
    BOOL isCommandKey;
    int selectionRadius;
    
}
@end

@implementation LTDetailsViewController
void* const ColorPanelContext = (void*)1001;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resizeWindow) name:NSWindowDidResizeNotification object:nil];
    [self.detailsImageView setImage:self.imagePath];
    imageWidth = CGImageGetWidth(self.detailsImageView.image);
    imageHeight = CGImageGetHeight(self.detailsImageView.image);
    [self.detailsImageView ap_forwardDraggingDestinationTo:self];
    undoDictionary = [[NSMutableDictionary alloc] init];
    drawingType = 0;
}

-(void)viewWillAppear {
    [super viewWillAppear];
    NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
    [colorPanel addObserver:self forKeyPath:@"color" options:0 context:ColorPanelContext];
    LTNumberFormatter *formatter = [[LTNumberFormatter alloc] init];
    [self.indexTextField setFormatter:formatter];
    previousLandmark = [[Landmarks alloc] init];
    self.indexTextField.delegate = self;
    selectionRadius = 6;
//    self.detailsImageView.wantsLayer = YES;
//    self.detailsImageView.layer.borderColor = [[NSColor redColor] CGColor];
//    self.detailsImageView.layer.borderWidth = 1;
    self.detailsImageView.clickedDelegate = self;
}

- (IBAction)zoomIn:(id)sender {
    self.detailsImageView.shouldDragImage = YES;
    [self.detailsImageView zoomImage:1];
    [[NSCursor arrowCursor] set];
}
- (IBAction)zoomOut:(id)sender {
    self.detailsImageView.shouldDragImage = YES;
    [self.detailsImageView zoomImage:0];
    [[NSCursor arrowCursor] set];
}
- (IBAction)aspectZoom:(id)sender {
    self.detailsImageView.shouldDragImage = YES;
    [self.detailsImageView zoomImage:2];
    [[NSCursor arrowCursor] set];
}
- (IBAction)fitZoom:(id)sender {
    self.detailsImageView.shouldDragImage = YES;
    [self.detailsImageView zoomImage:3];
    [[NSCursor arrowCursor] set];
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
    [self drawImageInView:color dotColor:dotColor];
}
- (IBAction)showColorPanel:(id)sender {
    NSColorPanel *panel = [NSColorPanel sharedColorPanel];
    [panel orderFront:nil];
    [panel setTarget:self];
    [panel makeKeyAndOrderFront:self];
}


-(void)drawImageInView:(NSColor *)color dotColor:(NSColor *)dotColor{
    if (!isProcessing)
    {
        isProcessing = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            NSImage *someImage = [LTStaticImageDrawing drawImage:color dotColor:dotColor
                                                        landmark:self.faceLandmark height:imageHeight
                                                           width:imageWidth type:drawingType];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                CGImageSourceRef source;
                CFDataRef cfdRef = (__bridge CFDataRef)[someImage TIFFRepresentation];
                source = CGImageSourceCreateWithData(cfdRef, NULL);
//                NSDictionary *dictionary = self.detailsImageView.imageProperties;
                CGImageRef imgRef =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
                CGFloat zoomFactor = self.detailsImageView.zoomFactor;
//                CGPoint point = self.detailsImageView.loc
                [self.detailsImageView updateImage:imgRef];
                self.detailsImageView.zoomFactor = zoomFactor;
                [self.detailsImageView scrollToPoint:scrollPoint];
                CGImageRelease(imgRef);
                CFRelease(source);
                source = NULL;
                isProcessing = NO;
            });
        });
    }
}

- (void)animateViewToFrame:(CGFloat)frameValue {
    
    isProcessing = false;
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.3];
    self.topSpaceConstraint.constant = self.topSpaceConstraint.constant + frameValue;
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
        [self animateViewToFrame:50];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.detailsImageView.resolutionLabel = self.resolutionLabel;
            previousLandmark.landmarkIndex = -1;
            [self.detailsImageView loadNextImage];
            [self loadImageInDetailsView];
        });
    }
    else {
        [self animateViewToFrame:-50];
    }
    return YES;
}
-(void)dropComplete:(NSArray *)fileArray
{
    
}
- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
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
    [self.detailsImageView updateIndex:1];
    self.indexTextField.stringValue = [NSString stringWithFormat:@"%ld",[self.detailsImageView getCurrentIndex]];
    previousLandmark.landmarkIndex = -1;
    [self.detailsImageView loadNextImage];
    [self loadImageInDetailsView];
    
}

- (IBAction)resetCurrentImage:(id)sender {
    long index = [self.indexTextField.stringValue integerValue];
    for(Landmarks *landmark in self.faceLandmark.landmarksArray){
        if(index == landmark.landmarkIndex){
            NSString *location = [self.locationTextField.stringValue stringByReplacingOccurrencesOfString:@"{" withString:@""];
            location = [location stringByReplacingOccurrencesOfString:@"}" withString:@""];
            NSArray *coord = [location componentsSeparatedByString:@","];
            landmark.xCoodinate = [[coord objectAtIndex:0] integerValue];
            landmark.yCoodinate = [[coord objectAtIndex:1] integerValue];
            [self drawImage];
            break;
        }
    }
}
- (IBAction)readPreviousImage:(id)sender {
    [self.detailsImageView updateIndex:-1];
    previousLandmark.landmarkIndex = -1;
    [self.detailsImageView loadNextImage];
    [self loadImageInDetailsView];
}

- (void)keyDown:(NSEvent *)theEvent {
    
    [self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
    if([theEvent keyCode] == 53 && previousLandmark.landmarkIndex != -1){
        currentLandmark.xCoodinate = previousLandmark.xCoodinate;
        currentLandmark.yCoodinate = previousLandmark.yCoodinate;
        currentLandmark.landmarkIndex = previousLandmark.landmarkIndex;
        
        [self drawImage];
        return;
    }
    NSString *key = [theEvent charactersIgnoringModifiers];
    if([key isEqualToString:@"z"]){
       
    }
    else if([key isEqualToString:@"c"]){
         [[NSCursor arrowCursor] set];
    }
    else if([key isEqualToString:@"s"]){
        if(isCommandKey){
            if(previousLandmark.landmarkIndex == currentLandmark.landmarkIndex){
                previousLandmark.xCoodinate = currentLandmark.xCoodinate;
                previousLandmark.yCoodinate = currentLandmark.yCoodinate;
            }
            return;
        }
        drawingType =  !drawingType;
        [self drawImage];
        
    }
    else if([key isEqualToString:@"d"]){
        self.detailsImageView.shouldDragImage = !self.detailsImageView.shouldDragImage;
    }
}

-(void)drawImage {
    NSColor *color = [NSColor redColor];
    NSColor *dotColor = [NSColor colorWithCalibratedRed:1.0f - color.redComponent  green: 1.0f - color.blueComponent blue: 1.0f - color.redComponent alpha:1.0];
    [self drawImageInView:color dotColor:dotColor];
}

-(void)flagsChanged:(NSEvent *)event{
    [super flagsChanged:event];
    
    NSUInteger flag = [event modifierFlags];
    isCommandKey = !!(flag & NSCommandKeyMask);
}

- (IBAction)updateLandmarks:(id)sender {
    
    [self.detailsImageView updateLandmark];
}

- (IBAction)deleteImage:(id)sender {
    [self.detailsImageView deleteImage];
}

-(void)loadImageInDetailsView
{
    self.faceLandmark = [self.detailsImageView getCurrentFaceLandmark];
    CGSize imageSize = [[self detailsImageView] getSize];
    imageWidth = imageSize.width;
    imageHeight = imageSize.height;
    drawingType =  1;
    [self drawImage];
    self.filePathTextField.stringValue = self.faceLandmark.maskImageName.lastPathComponent;
    
}

-(void)landmarkClickedAtPoint:(NSPoint)clickedPoint{
    if (!isProcessing)
    {
//        scrollPoint = clickedPoint;//[self.detailsImageView convertImagePointToViewPoint:clickedPoint];
        isProcessing = YES;
    BOOL isEdited = NO;
        CGRect boundingRect = CGRectMake(clickedPoint.x - selectionRadius / 2, imageHeight - clickedPoint.y -  selectionRadius / 2, selectionRadius, selectionRadius);
        for(Landmarks *landmark in self.faceLandmark.landmarksArray){
            if(CGRectContainsPoint(boundingRect, CGPointMake(landmark.xCoodinate, landmark.yCoodinate))){
                landmark.isEdited = YES;
                isEdited = YES;
                
                previousLandmark.xCoodinate = landmark.xCoodinate;
                previousLandmark.yCoodinate = landmark.yCoodinate;
                if(currentLandmark == nil ||
                    currentLandmark.landmarkIndex != landmark.landmarkIndex){
                    currentLandmark.isEdited = NO;
                    currentLandmark = nil;
                    currentLandmark = landmark;
                }
                break;
            }
        }
        isProcessing = false;
        if(currentLandmark != nil){
            self.locationTextField.stringValue = NSStringFromPoint(NSMakePoint(clickedPoint.x, imageHeight - clickedPoint.y));
            currentLandmark.xCoodinate = clickedPoint.x;
            currentLandmark.yCoodinate = imageHeight - clickedPoint.y;
            previousLandmark.landmarkIndex = currentLandmark.landmarkIndex;
            //draw
            [self drawImage];
        }
         /*long topdist = (clickedPoint.y - imageHeight + self.faceLandmark.box.top) ;
        topdist = topdist < 0 ? 1000 : topdist;
        long leftdist = (self.faceLandmark.box.left - clickedPoint.x);
        leftdist = leftdist < 0 ? 1000 : leftdist;
//        height - faceLandmarks.box.height - faceLandmarks.box.top
        
        long rightdist = (clickedPoint.x - self.faceLandmark.box.left - self.faceLandmark.box.width);
        rightdist = rightdist < 0 ? 1000 : rightdist;
        long bottomdist = (imageHeight - self.faceLandmark.box.height - self.faceLandmark.box.top ) - clickedPoint.y;
        bottomdist = bottomdist < 0 ? 1000 : bottomdist;
        long array[] = {leftdist,topdist, rightdist, bottomdist};
        long min = array[0];
        for(int i = 1; i < 4; i++){
            if(array[i] < min ){
                min = array[i];
            }
        }
        if(min == array[0]){ // left
            self.faceLandmark.box.left -= min;
        }
        else if(min == array[1]){ // top
            self.faceLandmark.box.top -= min;
        }
        else if(min == array[2]){
             self.faceLandmark.box.left += min;
        }
        else if(min == array[3]){
            self.faceLandmark.box.top += min;
        }
        [self drawImage];*/
    }
    
}

-(void)controlTextDidEndEditing:(NSNotification *)obj{
    NSUInteger index = [[self.indexTextField stringValue] integerValue];
    if(![self.detailsImageView isIndexOutOfBound:index]){
        [self.detailsImageView jumpToIndex:index];
        previousLandmark.landmarkIndex = -1;
        [self.detailsImageView loadNextImage];
    }
}
- (IBAction)increament:(id)sender {

//    self.faceLandmark.box.height += 5;
//    self.faceLandmark.box.width += 5;
    selectionRadius = ++selectionRadius > 20 ? 20 : selectionRadius;
}
- (IBAction)decreament:(id)sender {

    selectionRadius = --selectionRadius < 6 ? 6 : selectionRadius;
}
- (IBAction)selectIndex:(id)sender {
    long index = [((NSSecureTextField *)sender).stringValue integerValue];
    for(Landmarks *landmark in self.faceLandmark.landmarksArray){
        if(landmark.landmarkIndex == index){
            currentLandmark.isEdited = NO;
            currentLandmark = nil;
            currentLandmark = landmark;
            landmark.isEdited = YES;
            break;
            
        }
    }
}



@end

//@implementation OnlyIntegerValueFormatter
//

//@end
