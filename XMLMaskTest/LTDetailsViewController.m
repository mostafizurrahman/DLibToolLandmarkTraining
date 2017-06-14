//
//  LTDetailsViewController.m
//  LandmarkTesting
//
//  Created by Mostafizur Rahman on 4/10/17.
//  Copyright © 2017 Mostafizur Rahman. All rights reserved.
//

#import "LTDetailsViewController.h"
#import "LTStaticImageDrawing.h"
#import "OnlyIntegerValueFormatter.h"
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
    NSColorPanel *colorPanel;
}
@end

@implementation LTDetailsViewController
void* const ColorPanelContext = (void*)1000;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.detailsImageView setImage:self.imagePath];
    imageWidth = CGImageGetWidth(self.detailsImageView.image);
    imageHeight = CGImageGetHeight(self.detailsImageView.image);
    [self.detailsImageView ap_forwardDraggingDestinationTo:self];
    undoDictionary = [[NSMutableDictionary alloc] init];
    drawingType = 0;
}

-(void)viewWillAppear {
    [super viewWillAppear];
    colorPanel = [NSColorPanel sharedColorPanel];
    [colorPanel addObserver:self forKeyPath:@"color" options:0 context:ColorPanelContext];
    LTNumberFormatter *formatter = [[LTNumberFormatter alloc] init];
    [self.indexTextField setFormatter:formatter];
    previousLandmark = [[Landmarks alloc] init];
    self.indexTextField.delegate = self;
    selectionRadius = 6;
    OnlyIntegerValueFormatter *fortmatter = [[OnlyIntegerValueFormatter alloc] init];
    [self.delRanLanCountTextField setFormatter:fortmatter];
    [self.delLanAtIndexTextField setFormatter:formatter];
    [self.imageIndexTextField setFormatter:formatter];
    
    
    self.detailsImageView.clickedDelegate = self;
    drawingType = 1;
    if(self.faceLandmark)
        [self drawImage];
}

- (IBAction)zoomIn:(id)sender {
    if(self.faceLandmark )
    {
        self.detailsImageView.shouldDragImage = YES;
        [self.detailsImageView zoomImage:1];
        [[NSCursor arrowCursor] set];
    }
}

- (IBAction)zoomOut:(id)sender {
    if(self.faceLandmark )
    {
        self.detailsImageView.shouldDragImage = YES;
        [self.detailsImageView zoomImage:0];
        [[NSCursor arrowCursor] set];
    }
}

- (IBAction)aspectZoom:(id)sender {
    if(self.faceLandmark )
    {
        
        self.detailsImageView.shouldDragImage = YES;
        [self.detailsImageView zoomImage:2];
        [[NSCursor arrowCursor] set];
    }
}

- (IBAction)fitZoom:(id)sender {
    if(self.faceLandmark )
    {
        
        self.detailsImageView.shouldDragImage = YES;
        [self.detailsImageView zoomImage:3];
        [[NSCursor arrowCursor] set];
    }
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
    if(self.faceLandmark )
    {
        NSColor *dotColor = [NSColor colorWithCalibratedRed:1.0f - color.redComponent  green: 1.0f - color.blueComponent blue: 1.0f - color.redComponent alpha:1.0];
        [self drawImageInView:color dotColor:dotColor];
    }
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
                CGImageRef imgRef =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
                CGFloat zoomFactor = self.detailsImageView.zoomFactor;
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


- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return true;
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pasteboard = [sender draggingPasteboard];
    NSArray *fileArray = [pasteboard propertyListForType:NSFilenamesPboardType];
    NSString *pathString = [fileArray firstObject];
    if([@"xmljsontxtcsv" containsString:[[pathString pathExtension] lowercaseString]])
    {
        [self.detailsImageView loadFaceLanmark:pathString];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if(!self.detailsImageView.error){
                self.detailsImageView.resolutionLabel = self.resolutionLabel;
                previousLandmark.landmarkIndex = -1;
                [self.detailsImageView loadNextImage];
                [self loadImageInDetailsView];
            }
            else{
                
            }
        });
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
    if(!self.faceLandmark ) return;
    [self.detailsImageView updateIndex:1];
    self.indexTextField.stringValue = [NSString stringWithFormat:@"%ld",[self.detailsImageView getCurrentIndex]];
    previousLandmark.landmarkIndex = -1;
    [self.detailsImageView loadNextImage];
    [self loadImageInDetailsView];
    
}

- (IBAction)resetCurrentImage:(id)sender {
    if(!self.faceLandmark || ![self.locationTextField.stringValue containsString:@"{"] ||
       ![self.locationTextField.stringValue containsString:@"}"] ||
       ![self.locationTextField.stringValue containsString:@","]) return;
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
    if(!self.faceLandmark ) return;
    [self.detailsImageView updateIndex:-1];
    previousLandmark.landmarkIndex = -1;
    [self.detailsImageView loadNextImage];
    [self loadImageInDetailsView];
}

- (void)keyDown:(NSEvent *)theEvent {
    
    [self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
    if(!self.faceLandmark ) return;
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
        self.hotKeyStatusLabel.stringValue = self.detailsImageView.shouldDragImage ? @"Drag image using mouse" : @"Select landmark using mouse click event";
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
                    self.delLanAtIndexTextField.stringValue = [NSString stringWithFormat:@"%ld",landmark.landmarkIndex];
                    self.indexTextField.stringValue = [NSString stringWithFormat:@"%ld",landmark.landmarkIndex];
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
    }
    
}

- (IBAction)jumpLandmarkIndex:(id)sender {
    if(!self.faceLandmark ) return;
    long index = [((NSTextField *)sender).stringValue integerValue];
    for(Landmarks *landmark in self.faceLandmark.landmarksArray){
        if(landmark.landmarkIndex == index){
            currentLandmark.isEdited = NO;
            currentLandmark = nil;
            currentLandmark = landmark;
            landmark.isEdited = YES;
            [self drawImage];
            break;
        }
    }
}

- (IBAction)increament:(id)sender {
    if(!self.faceLandmark ) return;
    selectionRadius = ++selectionRadius > 20 ? 20 : selectionRadius;
}


- (IBAction)decreament:(id)sender {
    if(!self.faceLandmark ) return;
    selectionRadius = --selectionRadius < 6 ? 6 : selectionRadius;
}

- (IBAction)selectIndex:(id)sender {
    if(!self.faceLandmark ) return;
    long index = [self.imageIndexTextField.stringValue integerValue];
    if(![self.detailsImageView isIndexOutOfBound:index]){
        [self.detailsImageView jumpToIndex:index];
        previousLandmark.landmarkIndex = -1;
        [self.detailsImageView loadNextImage];
    }
}


- (IBAction)deleteLandmark:(id)sender {
    if(!self.faceLandmark ) return;
    const int index = [self.delLanAtIndexTextField.stringValue intValue];
    
    for(Landmarks *landmark in _faceLandmark.landmarksArray){
        
        if(landmark.landmarkIndex == index){
            [_faceLandmark.landmarksArray removeObject:landmark];
            if(index == currentLandmark.landmarkIndex) {
                currentLandmark = nil;
            }
            [self drawImage];
            break;
        }
    }
    
}

- (IBAction)deleteRandomRange:(id)sender {
    if(!self.faceLandmark ) return;
    int deleteCount = [self.delRanLanCountTextField intValue];
    [self.detailsImageView deleteLandmarkRandomly:deleteCount];
}


@end
