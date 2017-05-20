//
//  FDMaskXmlParser.h
//  FDFaceMasking
//
//  Copyright © 2016 IPvision Canada Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FaceMaskItem.h"
#import "FaceLandmarks.h"

/*!
    @interface          FDMaskXmlParser
    @abstract           XML parser class for landmarks iteration
    @discussion         This class contains static methods to parse XML file
                        containing specific tags name. If the tag names are invalid
                        or illigal characters found, the error parameter will contain
                        the error descriptions.
 */
@interface FDMaskXmlParser : NSObject

/*!
    @method             getFaceMasks:withError:
    @abstract           Parses xml file from path location to determina number of masks
                        available in the application.
    @param              xmlFilePath
                        Path to the xml file. This file contains all face masks info
                        in xml tags.
    @param              error 
                        It is used to raise error if the xml file contains invalid tags
                        or structure.
    @discussion         This static method can parse xml file that contains face masks of
                        numerous type and returns face mask array. It can parse mask i. title,
                        ii. logo name, iii. landmarks xml file name/path. This method is used
                        to create the collectionview datasource. If the tag is incomplete or
                        contains illigal characters, the param 'error' will contain error
                        descriptions.
 */
+(NSArray *)getFaceMasks:(NSString *)xmlFilePath
               withError:(NSError *__autoreleasing*)error;

/*!
    @method             getLandmarks:withError:
    @abstract           Parses xml landmark file from xmlFilePath location to draw the input
                        imask image using landmarks points in GLKView.
    @param              xmlFilePath
                        Path to the xml file. This file contains all 76 facelandmarks points
                        and relavent info.
    @param              error 
                        It is used to raise error if the xml file contains invalid tags or
                        structure.
    @discussion         This static method can parse xml file that contains 76 face landmark
                        points of selected mask. It can parse xml contains i. mask image name,
                        ii. mask width, height, iii. landmarks counts, iv. 76 landmark points.
                        Xml file is responsible for mask rendering on face rectangle in GLKView.
                        If the tag is incomplete or contains illigal characters, the param 'error'
                        will contain error descriptions.
 */
+(FaceLandmarks *)getLandmarks:(NSString*)xmlFilePath
                     withError:(NSError *__autoreleasing*)error;

/*!
    @method             getSubstringBetween:andEndString:fromString:withError:
    @abstract           Get string value in between two xml tags. and delete the string including xml tags.
    @param              startString
                        starting xml tag
    @param              endString
                        ending xml tag
    @param              sourceString
                        input xml string
    @return             NSString value between stat xml tag and end xml tag.
                        whole xml string. After getting the xml tag value the sourceString is reduced because
                        tags and value is deleted from it.
    @discussion         This static method can return xml tag value and delete string after extracting tag value
 */
+(NSString *)getSubstringBetween:(NSString *)startString
                    andEndString:(NSString *)endString
                      fromString:(NSString *__autoreleasing*)sourceString
                       withError:(NSError *__autoreleasing*)error;

/*!
    @method             getAttributeFrom:withAttributeName:
    @abstract           get attribute value from xml tag
    @param              landmarksString
                        NSString representing input xml tag with attributed values
    @param              attribute
                        NSString representing a single tag attribute
    @return             Integer value of Landmark position x, y, index, gif drawing rect(width percentage, height
                        percentage, origin X-Coordinate percentage, origin Y-Coordinate percentage)
 
    @discussion         This method can read landmark string and parse Landmark x, y, index attribute. Gif drawing
                        rectangle is also extracted using this method.
 */
+(NSInteger)getAttributeFrom:(NSString *)landmarksString
           withAttributeName:(NSString *)attribute;
 
 /*!
    @method             raisErrorWithCode:tagName:reasonKey:inError:
    @abstract           Manually rais error for invalid xml tag or attributes.
    @param              errorCode
                        Code of error occured, represents the domain of the error [usually cocoa domain].
    @param              tagString
                        Xml tag name responsible for the error
    @param              reasonKey
                        Reason key and tag string is used to fully specify the error. UserInfo dictionary contains 
                        full definition of the error.
    @discussion         Rais error if the xml input string is invalid.
  
  */
+(BOOL)raisErrorWithCode:(NSInteger)errorCode
                 tagName:(NSString *)tagString
               reasonKey:(NSString *)reasonKey
                 inError:(NSError *__autoreleasing*)error;
@end
