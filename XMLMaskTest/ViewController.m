
//
//  ViewController.m
//  XMLMaskTest
//
//  Created by Mostafizur Rahman on 8/18/16.
//  Copyright © 2016 Mostafizur Rahman. All rights reserved.
//

#import "ViewController.h"
#import <Cocoa/Cocoa.h>
#import <CoreGraphics/CoreGraphics.h>
#import "AppDelegate.h"
#import "LTDetailsViewController.h"

#import "LTStaticImageDrawing.h"

#define SAMPLE_IMAGE 0
#define SAMPLE_NONIMAGE 2
#define SANDRD_IMAGE 1
#define SANDRD_NONIMAGE 3

@interface ViewController()
{
    NSImage *inputImage;
    BOOL isLeftMouseButtonDown;
    NSColor* theColor ;
    LandmaskXMLParser *xmlparser;
    BOOL isProcessing;
    NSTextField *dragDestTextField;
    NSInteger editableVertexNumber;
    NSMutableDictionary *updatedLandmarksDictionary;
    
    
    FaceLandmarks *sampleLandmarks;
    FaceLandmarks *stndrdLandmarks;
    NSUInteger sampleType;
    
    NSUInteger imageWH;
}
@end
@implementation ViewController

void* const ColorPanelColorContext = (void*)1001;
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Mask Landmark Testing Tool";
    isProcessing = false;
    isLeftMouseButtonDown = false;
    editableVertexNumber = 0;
    
    xmlparser = [[LandmaskXMLParser alloc] init];
    xmlparser.parseDelegate = self;
    updatedLandmarksDictionary = [[NSMutableDictionary alloc] init];
    [_xmlTextField ap_forwardDraggingDestinationTo:self];
    [_xmlTextField registerForDraggedTypes:@[NSFileType,NSFilenamesPboardType,NSFileTypeSymbolicLink,NSURLPboardType]];
    
    [_imageTextField ap_forwardDraggingDestinationTo:self];
    [_imageTextField registerForDraggedTypes:@[NSFileType,NSFilenamesPboardType,NSFileTypeSymbolicLink,NSURLPboardType]];
    
    [_imageView registerForDraggedTypes:@[NSFileType,NSFilenamesPboardType,NSFileTypeSymbolicLink,NSURLPboardType]];
    OnlyIntegerValueFormatter *formatter = [[OnlyIntegerValueFormatter alloc] init] ;
    [_vertextTextField setFormatter:formatter];
    _imageView.delegate = self;
    
}

-(void)viewDidDisappear {
    [super viewDidDisappear];
    NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
    [colorPanel removeObserver:self forKeyPath:@"color"];
    [[NSApplication sharedApplication] terminate:self];
    
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}


-(void)viewWillAppear
{
    [super viewWillAppear];
    NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
    [colorPanel addObserver:self forKeyPath:@"color"
                    options:0 context:ColorPanelColorContext];
    [_errorLabel setStringValue:@""];
    _standardImageView.layer.borderColor = [[NSColor greenColor] CGColor];
    _standardImageView.layer.borderWidth = 2;
    _imageView.layer.borderColor = [[NSColor cyanColor] CGColor];
    _imageView.layer.borderWidth = 2;
    
}

- (IBAction)openXmlFileLocation:(id)sender {
    
    BOOL isXmlFile = [sender tag] == 11;
    NSArray* fileTypes = isXmlFile ? [[NSArray alloc] initWithObjects:@"xml", @"XML",@"txt",@"TXT",@"json",@"csv",@"CSV", nil] : [[NSArray alloc] initWithObjects:@"png", @"PNG", nil];
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];
    [panel setAllowedFileTypes:fileTypes];
    [panel beginSheetModalForWindow:[self.view window] completionHandler:^(NSModalResponse returnCode) {
        
        
        if (returnCode == NSFileHandlingPanelOKButton)
        {
            for (NSURL *url in [panel URLs])
            {
                if (isXmlFile)
                {
                    [_xmlTextField setStringValue:[url path]];
                }
                else
                {
                    [_imageTextField setStringValue:[url path]];
                }
                break;
            }
        }
    }];
}





- (IBAction)hideStandardImage:(id)sender
{
    sampleType = SANDRD_NONIMAGE;
    NSString *stdXmlPath = [[NSBundle mainBundle] pathForResource:@"leopard" ofType:@"xml"];
   
    [xmlparser loadRssFeed:stdXmlPath];
}


- (IBAction)showStandardSample:(id)sender
{
    sampleType = SANDRD_IMAGE;
    NSString *stdXmlPath = [[NSBundle mainBundle] pathForResource:@"leopard" ofType:@"xml"];
    NSString *stdImagePath  = [[NSBundle mainBundle] pathForResource:@"leopard" ofType:@"png"];
    stndrdLandmarks.inputImage = [[NSImage alloc] initWithContentsOfFile:stdImagePath];
    NSString *xml = [[NSString alloc] initWithContentsOfFile:stdXmlPath encoding:NSUTF8StringEncoding error:nil];
    [xmlparser loadRssFeed:xml];
}



- (IBAction)hideSampleImage:(id)sender {
    
    [_errorLabel setStringValue:@""];
    [_statusLable setStringValue:@""];
    sampleType = SAMPLE_NONIMAGE;
    if (![_xmlTextField.stringValue isEqualToString:@""]) {
        NSString *xml = [[NSString alloc] initWithContentsOfFile:_xmlTextField.stringValue encoding:NSUTF8StringEncoding error:nil];
        if([_xmlTextField.stringValue containsString:@"json"] || [_xmlTextField.stringValue containsString:@"csv"]){
            xml = [self getXmlString:xml];
        }
        [xmlparser loadRssFeed:xml];
    }
}


- (IBAction)testXml:(id)sender {
    [_errorLabel setStringValue:@""];
    [_statusLable setStringValue:@""];
    sampleType = SAMPLE_IMAGE;
    int len = (int)[_imageTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length;
    NSLog(@"length %d", len);
    if(len > 0)
    {
        NSString *xml = [[NSString alloc] initWithContentsOfFile:_xmlTextField.stringValue encoding:NSUTF8StringEncoding error:nil];
        if([_xmlTextField.stringValue containsString:@"json"] || [_xmlTextField.stringValue containsString:@"csv"]){
            xml = [self getXmlString:xml];
        }
        
        [xmlparser loadRssFeed:xml];
        NSLog(@"my whole life is a lie length %d", len);
    }
}

-(NSString *)getXmlString:(NSString *)inputString {
    int i = 0;
    NSString *outputString = @"";
    NSString *inString = [inputString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    inString = [inString stringByReplacingOccurrencesOfString:@" " withString:@""];
    inString = [inString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    inString = [inString stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    inString = [[inString componentsSeparatedByString:@"\"data\""] lastObject];
    inString = [[inString componentsSeparatedByString:@"\"images\""] firstObject];
    inString = [[inString componentsSeparatedByString:@"]}],"] firstObject];
    inString = [[inString componentsSeparatedByString:@":["] lastObject];
    NSArray *inputStrArr = [inString componentsSeparatedByString:@","];
    for(int index = 0; index < [inputStrArr count]; index++){
        NSString *xCoord = [inputStrArr objectAtIndex:index++];
        NSString *yCoord = [inputStrArr objectAtIndex:index];
        NSString *nodeString = [NSString stringWithFormat:@"<landmark vertex=\"%d\" x=\"%d\" y=\"%d\"/>\n", i++, (int)([xCoord doubleValue] * imageWH) , (int)([yCoord doubleValue] * imageWH)];
        outputString = [NSString stringWithFormat:@"%@%@",outputString, nodeString];
    }
    NSString *headerString = @"<?xml version=\"1.0\"?>"
    "<masklandmark>"
    "<mask_resolution>"
    "<width>512</width>"
    "<height>512</height>"
    "</mask_resolution>"
    "<mask_title>BD_cricket</mask_title>"
    "<mask_image_name>bdcricketmask</mask_image_name>"
    "<mask_logo_name>bdcricket</mask_logo_name>"
    "<landmarks_count>76</landmarks_count>"
    "<landmarks>";
    return [NSString stringWithFormat:@"%@%@</landmarks> </masklandmark>",headerString, outputString ] ;
}

- (IBAction)showColorPanel:(id)sender {
    NSColorPanel *panel = [NSColorPanel sharedColorPanel];
    [panel orderFront:nil];
    [panel setTarget:self];
    [panel makeKeyAndOrderFront:self];
}


#pragma mark - font+color

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if(sampleType == SAMPLE_IMAGE || sampleType == SAMPLE_NONIMAGE)
    {
        NSColor *color = ((NSColorPanel *)object).color;
        NSColor *dotColor = [NSColor colorWithCalibratedRed:1.0f - color.redComponent  green: 1.0f - color.blueComponent blue: 1.0f - color.redComponent alpha:1.0];
        if (!isProcessing && ![_xmlTextField.stringValue isEqualToString:@""] && ![_imageTextField.stringValue isEqualToString:@""])
        {
            isProcessing = true;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                NSImage *image = [LTStaticImageDrawing drawImage:((NSColorPanel *)object).color dotColor:dotColor landmark:sampleLandmarks height:imageWH width:imageWH type:sampleType];
                dispatch_async(dispatch_get_main_queue(), ^{
                    ((NSImageView *)sampleLandmarks.imageView).image = image;
                    isProcessing = YES;
                });
            });
        }
    }
}



- (IBAction)resetAll:(id)sender {
    
    NSImage *image = [NSImage imageNamed: @"monkey"];
    _imageView.image = image;
    _standardImageView.image = image;
    [_xmlTextField setStringValue:@""];
    [_imageTextField setStringValue:@""];
    [_errorLabel setStringValue:@""];
    editableVertexNumber = 0;
    [_vertextTextField setStringValue:@"0"];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSPoint dragpoint = [sender draggingLocation];
    [self highlightTextFiled:_imageTextField isHighlited:false];
    [self highlightTextFiled:_xmlTextField isHighlited:false];
    if (CGRectContainsPoint(_imageTextField.frame,dragpoint)) {
        dragDestTextField = _imageTextField;
    }
    else if(CGRectContainsPoint(_xmlTextField.frame,dragpoint))
    {
        dragDestTextField = _xmlTextField;
    }
    else
    {
        dragDestTextField = nil;
    }
    [self highlightTextFiled:dragDestTextField isHighlited:true];
    return NSDragOperationGeneric;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    return [self draggingEntered:sender];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    [self highlightTextFiled:dragDestTextField isHighlited:false];
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
    [self highlightTextFiled:dragDestTextField isHighlited:false];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return true;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pasteboard = [sender draggingPasteboard];
    NSArray *fileArray = [pasteboard propertyListForType:NSFilenamesPboardType];
    if(fileArray.count == 2)
    {
        for (NSString *filepath in fileArray)
        {
            NSString* tempPath = @"";
            NSString* tempFile = [tempPath stringByAppendingPathComponent:filepath];
            NSURL* url = [NSURL fileURLWithPath:tempFile];
            NSString *extension = url.pathExtension;
            if ([extension.lowercaseString containsString:@"png"])
            {
                [_imageTextField setStringValue:[url path]];
                inputImage = [[NSImage alloc] initWithContentsOfFile:_imageTextField.stringValue];
                imageWH = ((NSBitmapImageRep *)inputImage.representations.firstObject).pixelsHigh;
            }
            else if([extension.lowercaseString containsString:@"xml"] || [extension.lowercaseString containsString:@"txt"]
                    || [extension.lowercaseString containsString:@"csv"]  || [extension.lowercaseString containsString:@"json"])
            {
                [_xmlTextField setStringValue:[url path]];
            }
        }
    }
    if (![_xmlTextField.stringValue isEqualToString:@""] && ![_imageTextField.stringValue isEqualToString:@""]) {
        sampleType = SAMPLE_IMAGE;
            NSString *xml = [[NSString alloc] initWithContentsOfFile:_xmlTextField.stringValue encoding:NSUTF8StringEncoding error:nil];
            if([_xmlTextField.stringValue containsString:@"json"] || [_xmlTextField.stringValue containsString:@"csv"]){
                xml = [self getXmlString:xml];
            }
            [xmlparser loadRssFeed:xml];
        
    }
    return YES;
}

-(void)dropComplete:(NSArray *)fileArray
{
    
    if(fileArray.count == 2)
    {
        for (NSString *filepath in fileArray)
        {
            NSString* tempPath = @"";
            NSString* tempFile = [tempPath stringByAppendingPathComponent:filepath];
            NSURL* url = [NSURL fileURLWithPath:tempFile];
            NSString *extension = url.pathExtension;
            if ([extension.lowercaseString containsString:@"png"])
            {
                [_imageTextField setStringValue:[url path]];
                inputImage = [[NSImage alloc] initWithContentsOfFile:_imageTextField.stringValue];
                imageWH = ((NSBitmapImageRep *)inputImage.representations.firstObject).pixelsHigh;
            }
            else if([extension.lowercaseString containsString:@"xml"]
                    || [extension.lowercaseString containsString:@"txt"]
                    ||[extension.lowercaseString containsString:@"csv"]
                    ||[extension.lowercaseString containsString:@"json"])
            {
                [_xmlTextField setStringValue:[url path]];
            }
        }
    }
    if (![_xmlTextField.stringValue isEqualToString:@""] && ![_imageTextField.stringValue isEqualToString:@""]) {
        sampleType = SAMPLE_IMAGE;
        NSString *xml = [[NSString alloc] initWithContentsOfFile:_xmlTextField.stringValue encoding:NSUTF8StringEncoding error:nil];
        if([_xmlTextField.stringValue containsString:@"json"] || [_xmlTextField.stringValue containsString:@"csv"]){
            xml = [self getXmlString:xml];
        }
        [xmlparser loadRssFeed:xml];
        
    }
}

-(void)clickedPoint:(NSPoint)point
{
    if (sampleLandmarks.landmarksArray.count && !isProcessing)
    {
        isProcessing = YES;
        NSUInteger index = [[_vertextTextField stringValue] integerValue];
        editableVertexNumber = index > 68 ? 67 : index;
        [_vertextTextField setStringValue:[NSString stringWithFormat:@"%ld",editableVertexNumber]];
        Landmarks *landmarks = [sampleLandmarks.landmarksArray objectAtIndex:editableVertexNumber];
        NSString *key = [NSString stringWithFormat:@"%ld", landmarks.landmarkIndex];
        
        landmarks.isEdited = true;
        landmarks.xCoodinate = point.x;
        landmarks.yCoodinate = imageWH - point.y;
        _imageView.image = [LTStaticImageDrawing drawImage:[NSColor redColor] dotColor:[NSColor greenColor] landmark:sampleLandmarks height:imageWH width:imageWH type:sampleType];
        NSArray *allkeys = [updatedLandmarksDictionary allKeys];
        
        for(NSString *mark in allkeys)
        {
            if([mark containsString:[NSString stringWithFormat:@"%ld", landmarks.landmarkIndex]])
            {
                [updatedLandmarksDictionary removeObjectForKey:mark];
                [updatedLandmarksDictionary setObject:landmarks forKey:mark];
                return;
            }
        }
        [updatedLandmarksDictionary setObject:landmarks forKey:key];
        isProcessing = NO;
    }
}



- (void)highlightTextFiled:(NSTextField *)textFiled isHighlited:(BOOL)highlight
{
    [textFiled setHighlighted:highlight];
    if (highlight)
    {
        textFiled.layer.borderColor = [NSColor redColor].CGColor;
        textFiled.layer.borderWidth = 2.0;
    }
    else
    {
        textFiled.layer.borderWidth = 0.0;
    }
}

- (IBAction)leftDecreament:(id)sender {
    editableVertexNumber = editableVertexNumber > 0 ? editableVertexNumber - 1 : editableVertexNumber;
    [_vertextTextField setStringValue:[NSString stringWithFormat:@"%ld",editableVertexNumber]];
}
- (IBAction)rightIncreament:(id)sender {
    editableVertexNumber = editableVertexNumber < 68 ? editableVertexNumber + 1 : editableVertexNumber;
    [_vertextTextField setStringValue:[NSString stringWithFormat:@"%ld",editableVertexNumber]];
}
- (IBAction)setVertext:(id)sender {
    NSTextField *textfield = (NSTextField *)sender;
    NSUInteger index = [[textfield stringValue] integerValue];
    editableVertexNumber = index > 68 ? 67 : index;
    [_vertextTextField setStringValue:[NSString stringWithFormat:@"%ld",editableVertexNumber]];
}


- (IBAction)correct:(id)sender {
    
    NSString *xmlString =  [[NSString alloc] initWithContentsOfFile:_xmlTextField.stringValue encoding:NSUTF8StringEncoding error:nil];//
    xmlString = [xmlString stringByReplacingOccurrencesOfString:@"“" withString:@"\""];
    xmlString = [xmlString stringByReplacingOccurrencesOfString:@"”" withString:@"\""];
    NSLog(@"log %@",xmlString);
    NSData *xmlData = [[NSData alloc ] initWithBytes:xmlString.UTF8String length:xmlString.length];
    [xmlData writeToFile:_xmlTextField.stringValue atomically:YES];

}
- (IBAction)updateLandmarks:(id)sender {
 
    NSString *xmlString = [[NSString alloc] initWithContentsOfFile:_xmlTextField.stringValue encoding:NSUTF8StringEncoding error:nil];
    NSArray *allkeys = [updatedLandmarksDictionary allKeys];
    NSLog(@"%@ len ",xmlString);
    for(NSString *key in allkeys)
    {
        Landmarks *landmarks = [updatedLandmarksDictionary objectForKey:key];
        
        NSString *separator = [NSString stringWithFormat:@"vertex=\"%@\"",key];
        NSArray *xmlStringArray = [xmlString componentsSeparatedByString:separator];
        NSString *xmlLastString = [xmlStringArray lastObject];
        NSArray *lastCompArray = [xmlLastString componentsSeparatedByString:@"/>"];
        NSString *middleString = [NSString stringWithFormat:@" x=\"%ld\" y=\"%ld\"",landmarks.xCoodinate, landmarks.yCoodinate];
        xmlString = @"";
        xmlString = [NSString  stringWithFormat:@"%@%@%@/>",xmlStringArray[0], separator, middleString];
        for (int i = 1; i < lastCompArray.count; i++)
        {
            xmlString = [NSString  stringWithFormat:@"%@%@%@",xmlString, [lastCompArray objectAtIndex:i],(i == lastCompArray.count - 1 ? @"":@"/>")];
        }
    }
    NSData *xmlData = [[NSData alloc ] initWithBytes:xmlString.UTF8String length:xmlString.length];
    [xmlData writeToFile:_xmlTextField.stringValue atomically:YES];
}


-(void)didEndLandmarksParsing:(FaceLandmarks *)faceLandmarks
{
 
    if (xmlparser.isErrorOccured) {
        [_errorLabel setStringValue:@"Invalid XML File"];
        _imageView.image = [NSImage imageNamed:@"error-512"];
        NSString *theFileName = [_xmlTextField.stringValue componentsSeparatedByString:@"/"].lastObject;
        long line = [xmlparser.errors.userInfo[@"NSXMLParserErrorLineNumber"] longValue];
        NSString *message = [xmlparser.errors.userInfo[@"NSXMLParserErrorMessage"] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        NSString *status = [NSString stringWithFormat:@"Error in %@.xml file, %@ at line number %ld.",theFileName, message, line ];
        [_statusLable setStringValue:status];
        return;
    }
    if(sampleType == SAMPLE_IMAGE || sampleType == SAMPLE_NONIMAGE)
    {
        sampleLandmarks = faceLandmarks;
        sampleLandmarks.imageView = _imageView;
        NSImage *img = sampleType == SAMPLE_NONIMAGE ? nil : [[NSImage alloc] initWithContentsOfFile:_imageTextField.stringValue];
        sampleLandmarks.inputImage = img;
        
        _imageView.image = [LTStaticImageDrawing drawImage:[NSColor redColor] dotColor:[NSColor greenColor] landmark:sampleLandmarks height:imageWH width:imageWH type:sampleType];
        isProcessing = NO;
        
    }
    else if(sampleType == SANDRD_IMAGE || sampleType == SANDRD_NONIMAGE)
    {
        stndrdLandmarks = faceLandmarks;
        stndrdLandmarks.imageView = _standardImageView;
        stndrdLandmarks.inputImage = sampleType == SAMPLE_NONIMAGE ? nil : [NSImage imageNamed:@"leopard.png"];
        imageWH = 512;
        _standardImageView.image = [LTStaticImageDrawing drawImage:[NSColor redColor] dotColor:[NSColor greenColor] landmark:sampleLandmarks height:imageWH width:imageWH type:sampleType];
        isProcessing = NO;
    }
}

-(NSURL *)getURL:(NSString *)path
{
    NSString* tempPath = @"";
    NSString* tempFile = [tempPath stringByAppendingPathComponent:path];
    return [NSURL fileURLWithPath:tempFile isDirectory:NO];
}


- (IBAction)openDetailsViewController:(NSButton *)sender {
    
    LTDetailsViewController *detailsVC = (LTDetailsViewController *)[self.storyboard instantiateControllerWithIdentifier: @"DetailsVC"];
    detailsVC.imagePath = _imageTextField.stringValue;
    detailsVC.faceLandmark = sampleLandmarks;
    [self presentViewControllerAsSheet:detailsVC];
}


@end
