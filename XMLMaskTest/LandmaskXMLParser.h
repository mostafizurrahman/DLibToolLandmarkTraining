//
//  LandmaskXMLParser.h
//  DisplayLiveSamples
//
//  Created by Mostafizur Rahman on 8/24/16.
//  Copyright © 2016 ZweiGraf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FaceLandmarks.h"
#import "Landmarks.h"
@protocol ParsingDidEndDelegate<NSObject>
-(void)didEndLandmarksParsing:(FaceLandmarks *)faceLandmarks;
@end
@interface LandmaskXMLParser : NSObject<NSXMLParserDelegate>
{
    @private
    NSMutableArray *landmarkArray;
    NSXMLParser *xmlParser;
    NSInteger depth;
    NSString *currentElement;
    
    FaceLandmarks *faceLandmarks;
}
@property (readonly) BOOL isErrorOccured;
@property (readwrite) id<ParsingDidEndDelegate> parseDelegate;
@property (readonly) NSError *errors;
- (void)loadRssFeed:(NSString *) urlString;

@end
