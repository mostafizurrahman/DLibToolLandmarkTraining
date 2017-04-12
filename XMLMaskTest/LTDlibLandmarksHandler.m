//
//  LTDlibLandmarksHandler.m
//  LandmarkTesting
//
//  Created by Mostafizur Rahman on 4/11/17.
//  Copyright © 2017 Mostafizur Rahman. All rights reserved.
//

#import "LTDlibLandmarksHandler.h"
#import "FaceLandmarks.h"
#import "PBInfoAlert.h"


@interface LTDlibLandmarksHandler() {
    NSString *singleImageString;

    NSString *rootDirectory;
    NSFileManager *fileManager;
}

@end

@implementation LTDlibLandmarksHandler
@synthesize  trainMaskArray;


-(instancetype)initWithFilePath:(NSString *)filePath {
    
    self = [super init];
    if(self){
        rootDirectory = [filePath stringByDeletingLastPathComponent];
        [self readImageStringParts:filePath];
    }
    return self;
}


#pragma -mark Generate FaceLandmark for Each Human Face
-(void)readImageStringParts:(NSString *)filePath{
    NSError *error;
    NSString *inputString = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSISOLatin2StringEncoding error:&error];
    if(!error){
        inputString = [inputString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        inputString = [inputString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        inputString = [inputString stringByReplacingOccurrencesOfString:@"\t" withString:@""];
        inputString = [inputString stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSArray *inputStringArray = [inputString componentsSeparatedByString:@"</comment>"];
        inputString = [inputStringArray lastObject];
        inputString = [self getSubstringBetween:@"<images>" andEndString:@"</images>" fromString:&inputString];
        NSString *imageString = [self getSubstringBetween:@"<image" andEndString:@"</image>" fromString:&inputString];
        trainMaskArray = [[NSMutableArray alloc] init];
        while(imageString){
            NSString *imagePath = [self getSubstringBetween:@"file='" andEndString:@"'>" fromString:&imageString];
            imagePath = [rootDirectory stringByAppendingPathComponent:imagePath];
            NSArray *boxArray = [imageString componentsSeparatedByString:@"</box>"];
            for(NSString *boxString in boxArray){
                if([boxString containsString:@"part"]){
                    FaceLandmarks *faceLandmark = [[FaceLandmarks alloc] init];
                    [self setLandmark:faceLandmark withString:boxString];
                    faceLandmark.maskImageName = imagePath;
                    [trainMaskArray addObject:faceLandmark];
                }
            }
            
            imageString = [self getSubstringBetween:@"<image" andEndString:@"</image>" fromString:&inputString];
            
        }
    }
}

-(void)setLandmark:(FaceLandmarks *)faceLandmark withString:(NSString *)imageString{
    
    NSString *boxString = [self getSubstringBetween:@"box" andEndString:@">" fromString:&imageString];
    faceLandmark.box = [[FaceRect alloc] init];
    faceLandmark.box.top = [[self getSubstringBetween:@"top='" andEndString:@"'" fromString:&boxString] integerValue];
    faceLandmark.box.left = [[self getSubstringBetween:@"left='" andEndString:@"'" fromString:&boxString] integerValue];
    faceLandmark.box.width = [[self getSubstringBetween:@"width='" andEndString:@"'" fromString:&boxString] integerValue];
    faceLandmark.box.height = [[self getSubstringBetween:@"height='" andEndString:@"'" fromString:&boxString] integerValue];
    NSArray *partsArray = [imageString componentsSeparatedByString:@"<part"];
    faceLandmark.landmarksArray = [[NSMutableArray alloc] initWithCapacity:LANDMARK_COUNT];
    
    for(NSUInteger index = 0; index < partsArray.count; index++ ){
        NSString *part = [partsArray objectAtIndex:index];
        if(![part containsString:@"name"]) continue;
        NSInteger landmarkIndex = [[self getSubstringBetween:@"name='" andEndString:@"'" fromString:&part] integerValue] - 1;
        NSInteger xCoordinate = [[self getSubstringBetween:@"x='" andEndString:@"'" fromString:&part] integerValue];
        NSInteger yCoordinate = [[self getSubstringBetween:@"y='" andEndString:@"'" fromString:&part] integerValue];
        Landmarks *landmark = [[Landmarks alloc] initWith:landmarkIndex xCoord:xCoordinate yCoord:yCoordinate];
        [faceLandmark.landmarksArray insertObject:landmark atIndex:landmarkIndex];
    }
}

-(NSString *)getSubstringBetween:(NSString *)startString
                    andEndString:(NSString *)endString
                      fromString:(NSString *__autoreleasing*)sourceString{
    PBInfoAlert *alert = nil;
    NSRange startRange = [(*sourceString) rangeOfString:startString];
    NSString *remainingString =[(*sourceString) stringByReplacingOccurrencesOfString:startString withString:@""];
    if (startRange.length == 0) {
        if ([(*sourceString) length] > 0) {
            alert = [[PBInfoAlert alloc] init:startString];
        }
        return nil;
    }
    NSRange endRange = [remainingString rangeOfString:endString];
    if (endRange.length == 0) {
        alert = [[PBInfoAlert alloc] init:endString];
        return nil;
    }
    if(alert){
        [alert beginSheetModalForWindow:[self.detailsView superview].window completionHandler:^(NSModalResponse returnCode) {}];
    }
    endRange.location = endRange.location + startRange.location + startRange.length;
    NSUInteger startLocation = startRange.location + startRange.length;
    NSRange subStringRange = NSMakeRange(startLocation, endRange.location - startLocation);
    NSRange deletingRange = NSMakeRange(startRange.location , endRange.location - startLocation + startRange.length + endRange.length);
    NSString *subString = [(*sourceString) substringWithRange:subStringRange];
    *sourceString = [(*sourceString) stringByReplacingCharactersInRange:deletingRange withString:@""];
    return subString;
}

#pragma -mark Upadet train xml

-(BOOL)updateTrainFile{
    NSMutableString *outputString = [[NSMutableString alloc] init];
    [outputString appendString:@"<?xml version='1.0' encoding='ISO-8859-1'?>\n"
    "<?xml-stylesheet type = 'text/xsl' href = 'image_metadata_stylesheet.xsl'?>\n"
    "<dataset>\n"
    "<name>imglab dataset</name>\n"
    "<comment>Created by imglab tool.</comment> <images>\n" ];
    for(long index = 0; index < trainMaskArray.count; index++){
        FaceLandmarks *faceLandmark = [trainMaskArray objectAtIndex:index];
        NSString *imageName = [faceLandmark.maskImageName lastPathComponent];
        [outputString appendString:[self getImageNameString:imageName]];
        do {
            [outputString appendString:[self getBoxString:faceLandmark.box]];
            for(long partIndex = 0; partIndex < faceLandmark.landmarksArray.count; partIndex++){
                [outputString appendString:[self getPartString:[faceLandmark.landmarksArray objectAtIndex:partIndex]]];
            }
            [outputString appendString:@"</box>\n"];
            if(++index) break;
            faceLandmark = [trainMaskArray objectAtIndex:index];
        }while([faceLandmark.maskImageName isEqualToString:imageName]);
        [outputString appendString:@"</image>\n"];
        index--;
    }
    [outputString appendString:@" </images>\n</dataset>\n"];
    NSData *xmlData = [[NSData alloc ] initWithBytes:outputString.UTF8String length:outputString.length];
    return [xmlData writeToFile:[rootDirectory stringByAppendingPathComponent:@"train1.xml"] atomically:YES];
}


-(NSString *)getImageNameString:(NSString *)imageName {
    return [NSString stringWithFormat:@"<image file='%@'>\n",imageName];
}

-(NSString *)getBoxString:(FaceRect *)faceRect {
    return [NSString stringWithFormat:@"<box top = '%ld' left = '%ld' width = '%ld' height = '%ld'>\n",
            faceRect.top, faceRect.left, faceRect.width, faceRect.height];
}

-(NSString *)getPartString:(Landmarks *)landmark {
    return [NSString stringWithFormat:@"<part name = '%ld' x = '%ld' y = '%ld'/>\n",
            landmark.landmarkIndex + 1, landmark.xCoodinate, landmark.yCoodinate];
}































@end
