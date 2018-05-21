//
//  BitmapFont.h
//  Copyright © 2018 Ben Zotto. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CharacterImage.h"

@interface BitmapFont : NSObject
@property (readonly) NSString * name;       // Text name of font if known, derived from ID.
@property (readonly) NSInteger size;        // Point size (pixels), derived from ID.
@property (readonly) BOOL isProportional;   // YES if proportional; NO if fixed-width.
@property (readonly) NSInteger firstChar;   // ASCII code of first character
@property (readonly) NSInteger lastChar;    // ASCII code of last character
@property (readonly) NSInteger widMax;      // maximum character width
@property (readonly) NSInteger kernMax;     // negative of maximum character kern
@property (readonly) NSInteger nDescent;    // negative of descent
@property (readonly) NSInteger fRectWidth;  // width of font rectangle
@property (readonly) NSInteger fRectHeight; // height of font rectangle
@property (readonly) NSInteger ascent;      // ascent
@property (readonly) NSInteger descent;     // descent
@property (readonly) NSInteger leading;     // leading

// Data is assumed to be an original Macintosh FONT resource in its original packed,
// big-endian format, as documented in Inside Macintosh. The resource ID is assumed
// to be a string containing only numeric digits. This routine does basic sanity
// checking on input data but is NOT exhaustively hardened against e.g. corrupt or
// maliciously-crafted data. 
+ (instancetype)fontFromResourceData:(NSData *)data withResourceIdString:(NSString *)resourceId;

- (NSUInteger)countOfPresentCharacters;
- (BOOL)characterIsPresent:(NSUInteger)character;
- (CharacterImage *)imageForCharacter:(NSUInteger)character;
- (CharacterImage *)missingCharacterImage;
@end
