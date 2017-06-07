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
#import "FDMaskXmlParser.h"
#import "NSMutableArray+QueueStack.h"

@interface LTDlibLandmarksHandler() {
    NSString *singleImageString;
    NSMutableArray *imageUrlArray;
    NSString *rootDirectory;
    NSFileManager *fileManager;
    int indexOffset;
    BOOL isFaceLandmark;
}

@end

@implementation LTDlibLandmarksHandler
@synthesize  trainMaskArray;


-(instancetype)initWithFilePath:(NSString *)filePath {
    
    self = [super init];
    if(self){
        isFaceLandmark = NO;
        rootDirectory = [filePath stringByDeletingLastPathComponent];
        fileManager = [NSFileManager defaultManager];
        [self readImageStringParts:filePath];
    }
    return self;
}

#pragma -mark Generate FaceLandmark for Each Human Face
-(void)readImageStringParts:(NSString *)filePath{
    NSError *error;
    NSMutableString *inputString = [NSMutableString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding  error:&error];
    if(!error){
        
        trainMaskArray = [[NSMutableArray alloc] init];
        NSArray *imageArray = [inputString componentsSeparatedByString:@"</image>"];
        isFaceLandmark = [imageArray count] <= 1;
        if(isFaceLandmark){
            FaceLandmarks *facelandmark = [FDMaskXmlParser getLandmarks:filePath withError:&error];
            if(!error) {
                facelandmark.maskImageName = [rootDirectory stringByAppendingPathComponent:facelandmark.maskImageName];
                [trainMaskArray addObject:facelandmark];
            }
        }
        else
        {
            for(NSMutableString *imgString in imageArray)
            {
                NSMutableString *imageString = (NSMutableString *)[imgString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                imageString = (NSMutableString *)[imageString stringByReplacingOccurrencesOfString:@" " withString:@""];
                imageString = (NSMutableString *)[imageString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
                imageString = (NSMutableString *)[imageString stringByReplacingOccurrencesOfString:@"\"" withString:@"'"];
                if(![imageString containsString:@"<imagefile='"]) continue;
                indexOffset = [imageString containsString:@"name='0'"] || [imageString containsString:@"name='00'"] ? 0 : 1;
                NSString *imagePath = [self getSubstringBetween:@"<imagefile='" andEndString:@"'>" fromString:&imageString];
                if(imagePath)
                {
                    imagePath = [rootDirectory stringByAppendingPathComponent:imagePath];
                    NSURL *imageUrl = [[NSURL alloc] initFileURLWithPath:imagePath isDirectory:NO];
                    if(![fileManager fileExistsAtPath:imageUrl.path isDirectory:NO])
                        continue;
                    NSArray *boxsArray = [imageString componentsSeparatedByString:@"</box>"];
                    for(NSString *string in boxsArray)
                    {
                        if(![string containsString:@"<box"]) continue;
                        BOOL shouldIncludeFace = YES;
                        if([string containsString:@"part"])
                        {
                            FaceLandmarks *faceLandmark = [[FaceLandmarks alloc] init];
                            shouldIncludeFace = [self setLandmark:faceLandmark withString:string];
                            if(!shouldIncludeFace)
                            {
                                continue;
                            }
                            faceLandmark.maskImageName = imagePath;
                            [trainMaskArray addObject:faceLandmark];
                        }
                    }
                }
            }
            if([trainMaskArray count ] == 0){
                self.error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:1010 userInfo:@{@"Reason":@"No Image found!!! check input xml"}];
            }
        }
    }
    if(!self.error)
    self.error = error;
}


-(void)getFileListFromURL:(NSURL *)rootDirUrl {
    imageUrlArray = [[NSMutableArray alloc] init];
    NSMutableArray *stackArray = [[NSMutableArray alloc] init];
    NSError *error = nil;
    NSArray *rootSubdirectoryArray = [self getSubdirectoriesFromURL:rootDirUrl withError:&error];
    [self setUrlList:rootSubdirectoryArray withStack:stackArray];
    while(!stackArray.empty) {
        NSURL *fileURL = [stackArray pop];
        NSArray *subdirectoryArray = [self getSubdirectoriesFromURL:fileURL withError:&error];
        for(NSURL *url in subdirectoryArray){
            if([@"jpgjpeg" containsString:url.pathExtension.lowercaseString ]){
                [imageUrlArray addObject:url];
            }
        }
    }
}

-(NSArray *)getSubdirectoriesFromURL:(NSURL *)rootDirURL
                           withError:(NSError *__autoreleasing*)error {
    return [fileManager contentsOfDirectoryAtURL:rootDirURL
                      includingPropertiesForKeys:nil
                                         options:(NSDirectoryEnumerationSkipsHiddenFiles)
                                           error:error];
}

-(void)setUrlList:(NSArray const *)array
        withStack:(NSMutableArray *)stackArray {
    for(NSURL *fileUrl in array) {
        if ([self isDirectoryUrl:fileUrl]) {
            [stackArray addObject:fileUrl];
        }
    }
}

-(BOOL)isDirectoryUrl:(NSURL *)url {
    NSNumber *isDirectory;
    BOOL success = [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
    return success && [isDirectory boolValue];
}

-(BOOL)setLandmark:(FaceLandmarks *)faceLandmark withString:(NSString *)imageString{
    
    NSString *boxString = [self getSubstringBetween:@"box" andEndString:@">" fromString:&imageString];
    faceLandmark.box = [[FaceRect alloc] init];
    faceLandmark.box.top = [self getAttributeFrom:boxString withAttributeName:@"top='"];
    faceLandmark.box.left = [self getAttributeFrom:boxString withAttributeName:@"left='"];
    faceLandmark.box.width = [self getAttributeFrom:boxString withAttributeName:@"width='"];
    faceLandmark.box.height = [self getAttributeFrom:boxString withAttributeName:@"height='"];
    NSArray *partsArray = [imageString componentsSeparatedByString:@"<part"];
    faceLandmark.landmarksArray = [[NSMutableArray alloc] init];
    
    for(NSUInteger index = 0; index < partsArray.count; index++) {
        NSString *part = [partsArray objectAtIndex:index];
        if(![part containsString:@"name"]) continue;
        NSInteger landmarkIndex = [[self getSubstringBetween:@"name='" andEndString:@"'" fromString:&part] integerValue];
        NSInteger xCoordinate = [[self getSubstringBetween:@"x='" andEndString:@"'" fromString:&part] integerValue];
        NSInteger yCoordinate = [[self getSubstringBetween:@"y='" andEndString:@"'" fromString:&part] integerValue];
        Landmarks *landmark = [[Landmarks alloc] initWith:(landmarkIndex - indexOffset) xCoord:xCoordinate yCoord:yCoordinate];
        [faceLandmark.landmarksArray addObject:landmark];
    }
    return YES;
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
    if(isFaceLandmark){
        FaceLandmarks *facelandmark = [trainMaskArray firstObject];
        [outputString appendString:@"<?xml version=\"1.0\"?>\n"
         "<masklandmark>\n"
         "<mask_resolution>\n"
         "<width>512</width>\n"
         "<height>512</height>\n"
         "</mask_resolution>\n"];
        [outputString appendString:[NSString stringWithFormat:@"<mask_title>%@</mask_title>\n", facelandmark.maskTitle]];
        [outputString appendString:[NSString stringWithFormat:@"<mask_image_name>%@</mask_image_name>\n", [facelandmark.maskImageName lastPathComponent]]];
        [outputString appendString:[NSString stringWithFormat:@"<landmarks_count>%ld</landmarks_count>\n<landmarks>\n", facelandmark.landmarksArray.count]];
        for(long partIndex = 0; partIndex < facelandmark.landmarksArray.count; partIndex++){
            [outputString appendString:[self getLandmarkString:[facelandmark.landmarksArray objectAtIndex:partIndex]]];
        }
        [outputString appendString:@"\t</landmarks>\n</masklandmark>"];
        
        NSData *xmlData = [[NSData alloc ] initWithBytes:outputString.UTF8String length:outputString.length];
        
        return [xmlData writeToFile:[rootDirectory stringByAppendingPathComponent:
                                     [NSString stringWithFormat:@"face_landmark_%@.xml",
                                      [[facelandmark.maskImageName stringByDeletingPathExtension] lastPathComponent] ]]
                         atomically:YES];
    }
    [outputString appendString:@"<?xml version='1.0' encoding='ISO-8859-1'?>\n"
     "<?xml-stylesheet type = 'text/xsl' href = 'image_metadata_stylesheet.xsl'?>\n"
     "<dataset>\n"
     "<name>imglab dataset</name>\n"
     "<comment>Created by imglab tool.</comment><images>\n" ];
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
            if(++index == trainMaskArray.count) break;
            faceLandmark = [trainMaskArray objectAtIndex:index];
        } while([[faceLandmark.maskImageName lastPathComponent] isEqualToString:imageName]);
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
            landmark.landmarkIndex, landmark.xCoodinate, landmark.yCoodinate];
}

-(NSString *)getLandmarkString:(Landmarks *)landmark {
    
    return [NSString stringWithFormat:@"<landmark vertex = \"%ld\" x = \"%ld\" y = \"%ld\"/>\n",
            landmark.landmarkIndex, landmark.xCoodinate, landmark.yCoodinate];
}

-(NSInteger)getAttributeFrom:(NSString *)landmarksString
           withAttributeName:(NSString *)attribute {
    
    landmarksString = [[landmarksString componentsSeparatedByString:attribute] lastObject];
    NSInteger atributeValue = [[[landmarksString componentsSeparatedByString:@"'"] firstObject] integerValue];
    return atributeValue;
}



#pragma -Mark EDITING Methods

-(void)deleteImage {
    FaceLandmarks *faceLandmark = [trainMaskArray objectAtIndex:_currentFaceIndex];
    NSString *imagePath = faceLandmark.maskImageName;
    NSError *error;
    if([fileManager removeItemAtPath:imagePath error:&error]){
        NSLog(@"removed");
    }
    long count = trainMaskArray.count;
    _currentFaceIndex += _currentFaceIndex == (trainMaskArray.count - 1) ? -1 : 1;
    for(long index = 0; index < count; index++){
        faceLandmark = [trainMaskArray objectAtIndex:index];
        if([faceLandmark.maskImageName isEqualToString:imagePath]){
            [trainMaskArray removeObject:faceLandmark];
            count--;
            index--;
        }
    }
}


-(void)deleteLandmark:(int)index {
    for(FaceLandmarks *faceLandmark in trainMaskArray){
        for(int index = 0; index < faceLandmark.landmarksArray.count; ){
            Landmarks *landmark = [faceLandmark.landmarksArray objectAtIndex:index];
            if(!CGRectContainsPoint(CGRectMake(0, 0, faceLandmark.maskWidth, faceLandmark.maskHeight), CGPointMake(landmark.xCoodinate, landmark.yCoodinate))){
                [faceLandmark.landmarksArray removeObject:landmark];
            }
            else {
                index++;
            }
        }
        
    }
}

-(void)deleteLandmarkRandmoly:(int)deleteCount {
    const int NO_LANDMARKS = 67;
    //    int *deletedIndex = calloc(deleteCount , sizeof(int));
    //    int index;
    for(FaceLandmarks *faceLandmark in trainMaskArray){
        int counting = deleteCount;
        while (counting) {
            int landmarkIndex = arc4random_uniform(NO_LANDMARKS);
            for(Landmarks *landmark in faceLandmark.landmarksArray ){
                if(landmark.landmarkIndex == landmarkIndex){
                    counting--;
                    [faceLandmark.landmarksArray removeObject:landmark];
                    break;
                }
            }
        }
        
    }
    //    free(deletedIndex);
}






















@end
