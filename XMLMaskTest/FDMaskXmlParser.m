//
//  FDMaskXmlParser.m
//  FDFaceMasking
//
//  Copyright © 2016 IPvision Canada Inc. All rights reserved.
//

#import "FDMaskXmlParser.h"
#import <CoreGraphics/CoreGraphics.h>

#import "Landmarks.h"
#define TAG_NAME_FILE_NAME @"<landmarks_file_name>"
#define TAG_NAME_ID @"<item_id>"
#define TAG_NAME_TITLE @"<mask_title>"
#define TAG_NAME_LOGO @"<mask_logo_name>"
#define TAG_NAME_IMAGE @"<mask_image_name>"

@implementation FDMaskXmlParser




/*
 @parameter xmlFilePath : path to the xml file to be parsed.
 decription : returns FaceLandmarks containing landmarks points array and vertex index. Error occured if xml is invalid
 */

+(FaceLandmarks *)getLandmarks:(NSString*)xmlFilePath withError:(NSError *__autoreleasing*)error {
    if(!xmlFilePath) return nil;
    NSMutableArray *landmarksArray = [[NSMutableArray alloc] init];
    NSString *xmlString = [[NSString alloc] initWithContentsOfFile:xmlFilePath encoding:NSUTF8StringEncoding error:nil];
    [FDMaskXmlParser removeSpecialCharFrom:&xmlString];
    
    xmlString = [FDMaskXmlParser getSubstringBetween:@"<masklandmark>"
                                        andEndString:@"</masklandmark>"
                                          fromString:&xmlString
                                           withError:error];
    
    xmlString = [FDMaskXmlParser  getStringByDeletingComments:xmlString];
    NSString *itemString = [FDMaskXmlParser getSubstringBetween:@"<mask_resolution>"
                                                   andEndString:@"</mask_resolution>"
                                                     fromString:&xmlString
                                                      withError:error];
    
    
    FaceLandmarks *faceLandmarks = [[FaceLandmarks alloc] init];
    
    faceLandmarks.maskWidth = [[FDMaskXmlParser getSubstringBetween:@"<width>"
                                                       andEndString:@"</width>"
                                                         fromString:&itemString
                                                          withError:error] integerValue];
    if ((*error).code > 1000) {
        return nil;
    }
    faceLandmarks.maskHeight = [[FDMaskXmlParser getSubstringBetween:@"<height>"
                                                        andEndString:@"</height>"
                                                          fromString:&itemString
                                                           withError:error] integerValue];
    if ((*error).code > 1000) {
        return nil;
    }
    faceLandmarks.maskTitle = [FDMaskXmlParser getSubstringBetween:@"<mask_title>"
                                                      andEndString:@"</mask_title>"
                                                        fromString:&xmlString
                                                         withError:error];
    if ((*error).code > 1000) {
        return nil;
    }
    faceLandmarks.maskImageName = [FDMaskXmlParser getSubstringBetween:@"<mask_image_name>"
                                                          andEndString:@"</mask_image_name>"
                                                            fromString:&xmlString
                                                             withError:error];
    if ((*error).code > 1000) {
        return nil;
    }
    NSError *blendError;
    NSString* blendStr = [FDMaskXmlParser getSubstringBetween:@"<blend_mode>"
                                                          andEndString:@"</blend_mode>"
                                                            fromString:&xmlString
                                                             withError:&blendError];
    
  
    
    faceLandmarks.landmarksCount = [[FDMaskXmlParser getSubstringBetween:@"<landmarks_count>"
                                                            andEndString:@"</landmarks_count>"
                                                              fromString:&xmlString
                                                               withError:error] integerValue];
    if ((*error).code > 1000) {
        return nil;
    }
    xmlString = [FDMaskXmlParser getSubstringBetween:@"<landmarks>"
                                        andEndString:@"</landmarks>"
                                          fromString:&xmlString
                                           withError:error];
    if ((*error).code > 1000) {
        return nil;
    }
    itemString = [FDMaskXmlParser getSubstringBetween:@"<landmark"
                                         andEndString:@"/>"
                                           fromString:&xmlString
                                            withError:error];
    
    if ((*error).code > 1000) {
        return nil;
    }
    while (itemString != nil) {
        [landmarksArray addObject:[FDMaskXmlParser getAttributes:itemString withError:error] ];
        itemString = [FDMaskXmlParser getSubstringBetween:@"<landmark"
                                             andEndString:@"/>"
                                               fromString:&xmlString
                                                withError:error];
        if ((*error).code > 1000) {
            return nil;
        }
        
    }
    NSSortDescriptor *landmarkDescriptor = [[NSSortDescriptor alloc] initWithKey:@"landmarkIndex" ascending:YES];
    NSArray *sD = @[landmarkDescriptor];
    faceLandmarks.landmarksArray = [landmarksArray sortedArrayUsingDescriptors:sD];
    return faceLandmarks;
}






+(NSString *)getSubstringBetween:(NSString *)startString
                    andEndString:(NSString *)endString
                      fromString:(NSString *__autoreleasing*)sourceString
                       withError:(NSError *__autoreleasing*)error {
    
    NSRange startRange = [(*sourceString) rangeOfString:startString];
    if (startRange.length == 0) {
        if ([(*sourceString) length] > 0) {
            [FDMaskXmlParser raisErrorWithCode:1001 tagName:startString reasonKey:@"Searching range not found" inError:error];
        }
        return nil;
    }
    NSRange endRange = [(*sourceString) rangeOfString:endString];
    if (endRange.length == 0) {
        [FDMaskXmlParser raisErrorWithCode:1002 tagName:startString reasonKey:@"Searching range not found" inError:error];
        return nil;
    }
    NSUInteger startLocation = startRange.location + startRange.length;
    NSRange subStringRange = NSMakeRange(startLocation, endRange.location - startLocation);
    NSRange deletingRange = NSMakeRange(startRange.location , endRange.location - startLocation + startRange.length + endRange.length);
    NSString *subString = [(*sourceString) substringWithRange:subStringRange];
    *sourceString = [(*sourceString) stringByReplacingCharactersInRange:deletingRange withString:@""];
    return subString;
}

+(NSString *)getStringByDeletingComments:(NSString *)sourceString {
    
    while ([sourceString containsString:@"<!--"] && [sourceString containsString:@"-->"]) {
        
        NSRange startRange = [sourceString rangeOfString:@"<!--"];
        NSRange endRange = [sourceString rangeOfString:@"-->"];
        NSUInteger startLocation = startRange.location + startRange.length;
        NSRange deletingRange = NSMakeRange(startRange.location , endRange.location - startLocation + startRange.length + endRange.length);
        sourceString = [sourceString stringByReplacingCharactersInRange:deletingRange withString:@""];
    }
    
    return sourceString;
}

+(NSString *)getEndTagFrom:(NSString *)startTagName {
    
    return [startTagName stringByReplacingOccurrencesOfString:@"<" withString:@"</"];
}


+(Landmarks *)getAttributes:(NSString *)landmarksString
                  withError:(NSError *__autoreleasing*)error {
    
    Landmarks *landmarks = [[Landmarks alloc] init];
    
    if ([landmarksString containsString:@"vertex=\""]) {
        landmarks.landmarkIndex = [FDMaskXmlParser getAttributeFrom:landmarksString withAttributeName:@"vertex=\""];
    }
    else {
        [FDMaskXmlParser raisErrorWithCode:1010 tagName:@"landmark with attribute vertex=" reasonKey:@"Xml tag attribute error" inError:error];
        return nil;
    }
    
    if ([landmarksString containsString:@"x=\""]) {
        landmarks.xCoodinate = [FDMaskXmlParser getAttributeFrom:landmarksString withAttributeName:@"x=\""];
    }
    else {
        [FDMaskXmlParser raisErrorWithCode:1011 tagName:@"landmark with attribute x=" reasonKey:@"Xml tag attribute error" inError:error];
        return nil;
    }
    
    if ([landmarksString containsString:@"y=\""]) {
        landmarks.yCoodinate = [FDMaskXmlParser getAttributeFrom:landmarksString withAttributeName:@"y=\""];
    }
    else {
        [FDMaskXmlParser raisErrorWithCode:1012 tagName:@"landmark with attribute y=" reasonKey:@"Xml tag attribute error" inError:error];
        return nil;
    }
    
    return landmarks;
}

+(NSInteger)getAttributeFrom:(NSString *)landmarksString
           withAttributeName:(NSString *)attribute {
    
    landmarksString = [[landmarksString componentsSeparatedByString:attribute] lastObject];
    NSInteger atributeValue = [[[landmarksString componentsSeparatedByString:@"\""] firstObject] integerValue];
    return atributeValue;
}

+(NSString *)getTagNameFrom:(NSString *)xmlString {
    
    NSRange startRange = [xmlString rangeOfString:@"<"];
    if (startRange.length == 0) {
        return @"";
    }
    NSRange endRange = [xmlString rangeOfString:@">"];
    if(endRange.length == 0) {
        return @"";
    }
    NSUInteger startLocation = startRange.location + startRange.length;
    NSRange subStringRange = NSMakeRange(startLocation, endRange.location - startLocation);
    return [xmlString substringWithRange:subStringRange];
}

+(BOOL)raisErrorWithCode:(NSInteger)errorCode
                 tagName:(NSString *)tagString
               reasonKey:(NSString *)reasonKey
                 inError:(NSError *__autoreleasing*)error{
    
    BOOL errorSet = NO;
    NSString *description = [NSString stringWithFormat:@"XML starting tag named \"%@\" not found", tagString];
    if (error) {
        *error = [NSError errorWithDomain:NSCocoaErrorDomain code:errorCode userInfo:@{
                                                                                       NSLocalizedDescriptionKey: NSLocalizedString(description, nil),
                                                                                       NSLocalizedFailureReasonErrorKey: NSLocalizedString(reasonKey, nil),
                                                                                       NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Xml data invalid", nil)
                                                                                       }];
        errorSet = YES;
    }
    
    return errorSet;
}

+(void)removeSpecialCharFrom:(NSString *__autoreleasing*)xmlString {
    
    *xmlString = [(*xmlString) stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    *xmlString = [(*xmlString) stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    *xmlString = [(*xmlString) stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    *xmlString = [(*xmlString) stringByReplacingOccurrencesOfString:@" " withString:@""];
}

@end

