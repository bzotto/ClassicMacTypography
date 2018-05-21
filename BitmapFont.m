//
//  BitmapFont.m
//  Copyright © 2018 Ben Zotto. All rights reserved.
//

#import "BitmapFont.h"

//
// The FONT resource format is from the 1985 edition of Apple's Inside Macintosh
// documentation Volume I (Font Manager).
//

@interface BitmapFont ()
// Private accessors for public properties
@property (copy) NSString * name;
@property (assign) NSInteger size;
@property (assign) BOOL isProportional;
@property (assign) NSInteger firstChar;
@property (assign) NSInteger lastChar;
@property (assign) NSInteger widMax;
@property (assign) NSInteger kernMax;
@property (assign) NSInteger nDescent;
@property (assign) NSInteger fRectWidth;
@property (assign) NSInteger fRectHeight;
@property (assign) NSInteger ascent;
@property (assign) NSInteger descent;
@property (assign) NSInteger leading;

// Private data
@property (strong) NSDictionary * charImageMap;
@property (strong) CharacterImage * missingCharImage;
@end

// Declarations of utility functions at the end of this file.
static NSString * FontNameFromResourceId(uint16 resourceId);
static NSInteger FontSizeFromResourceId(uint16 resourceId);

@implementation BitmapFont

+ (instancetype)fontFromResourceData:(NSData *)data withResourceIdString:(NSString *)resourceIdStr
{
    if (!data || !resourceIdStr) {
        return nil;
    }
    
    BitmapFont * font = [[BitmapFont alloc] init];
    
    // Extract the name and size from the resource ID.
    NSInteger resourceId = [resourceIdStr integerValue];
    if (resourceId == 0 || resourceId > 0xFFFF) {
        // 0 would be invalid and is also the sentinel from -integerValue that it
        // couldn't parse, so safe to bail.
        NSLog(@"Failed to parse resource ID %@", resourceIdStr);
        return nil;
    }
    uint16 resourceIdShort = (uint16)resourceId;
    // If the high bit is nonzero, it's invalid.
    if ((resourceIdShort & 0x8000) != 0) {
        NSLog(@"Failed to parse resource ID %@", resourceIdStr);
        return nil;
    }
    
    font.name = FontNameFromResourceId(resourceIdShort);
    font.size = FontSizeFromResourceId(resourceIdShort);
    if (font.size < 0) {
        return nil;
    }

    // Parse the resource data
    if (data.length < 26) {
        return nil;
    }
    
    uint8 * resourceData = (uint8 *)data.bytes;
    
    uint16 fontType = OSReadBigInt16(resourceData, 0);
    if (fontType == 0x9000) {
        font.isProportional = YES;
    } else if (fontType == 0xB000) {
        font.isProportional = NO;
    } else if (fontType == 0xACB0) {
        NSLog(@"FWID width-only resources not supported.");
        return nil;
    } else {
        NSLog(@"Unknown fontType record value");
        return nil;
    }
    
    font.firstChar = OSReadBigInt16(resourceData, 2);
    font.lastChar = OSReadBigInt16(resourceData, 4);
    if (font.lastChar > 0xFF) {
        NSLog(@"lastChar is > 255");
        return nil;
    }
    
    NSUInteger charactersInFont = font.lastChar - font.firstChar + 1;

    // The 16-bit words values are generally signed. Make sure we don't drop the sign
    // in the expansion to native intgeters.
    #define ReadBigSignedInt16(base, byteOffset) ((NSInteger)(int16_t)OSReadBigInt16(base, byteOffset))
    
    font.widMax = ReadBigSignedInt16(resourceData, 6);
    font.kernMax = ReadBigSignedInt16(resourceData, 8);
    if (font.kernMax > 0) {
        NSLog(@"kernMax is not negative (or zero)");
        return nil;
    }
    font.nDescent = ReadBigSignedInt16(resourceData, 10);
    font.fRectWidth = ReadBigSignedInt16(resourceData, 12);
    font.fRectHeight = ReadBigSignedInt16(resourceData, 14);
    if (font.fRectHeight > 127 || font.fRectWidth > 254) {
        NSLog(@"font rectangle exceeds max dimension");
        return nil;
    }
    
    font.ascent = ReadBigSignedInt16(resourceData, 18);
    font.descent = ReadBigSignedInt16(resourceData, 20);
    font.leading = ReadBigSignedInt16(resourceData, 22);
    NSUInteger rowWords = OSReadBigInt16(resourceData, 24);
    
    // Sanity check that we're not going to run off the end of the data.
//    if (data.length != 26 + (rowWords * 2 * font.fRectHeight) + ((charactersInFont + 2) * 2 * 2)) {
//        return nil;
//    }
    
    uint8 * bitImagePtr = &resourceData[26];
    uint16 * locTablePtr = ((uint16 *)bitImagePtr) + (rowWords * font.fRectHeight);
    uint16 * owTablePtr = locTablePtr + (charactersInFont + 2);
    
    NSUInteger locTable[255 + 2] = {0};
    uint16 owTable[255 + 2] = {0};
    for (int i = 0; i < (charactersInFont + 2); i++) {
        locTable[i] = OSReadBigInt16(locTablePtr, i * 2);
        owTable[i] = OSReadBigInt16(owTablePtr, i * 2);
    }

    #undef ReadBigSignedInt16
    
    // Find and extract the special missing character image so we can use it when needed.
    uint16 missingLoc = locTable[charactersInFont];
    uint16 missingImageWidth = locTable[charactersInFont + 1] - missingLoc;
    uint16 missingOffsetWidth = owTable[charactersInFont];
    font.missingCharImage = [CharacterImage imageWithWidth:(missingOffsetWidth & 0x00FF)
                                                    offset:((missingOffsetWidth >> 8) & 0x00FF)
                                                  rectSize:UIntSizeMake(missingImageWidth, font.fRectHeight)
                                                fromBitmap:bitImagePtr
                                       bitmapStartLocation:missingLoc
                                              bitmapStride:(rowWords * 2)];
    
    NSMutableDictionary * charImageMap = [[NSMutableDictionary alloc] init];
    for (NSInteger i = 0; i < 256; i++) {
        // Are we out of range?
        if (i < font.firstChar || i > font.lastChar) {
            continue;
        }
        
        // Does the character not exist?
        uint16 ow = owTable[i - font.firstChar];
        if (ow == 0xFFFF) {
            // Doesn't exist
            continue;
        }
        
        NSUInteger offset = (ow >> 8) & 0x00FF;
        NSUInteger width = ow & 0x00FF;
        NSUInteger location = locTable[i - font.firstChar];
        NSUInteger nextLocation = locTable[i - font.firstChar + 1];
        
        CharacterImage * charImage = [CharacterImage imageWithWidth:width
                                                             offset:offset
                                                           rectSize:UIntSizeMake(nextLocation - location, font.fRectHeight)
                                                         fromBitmap:bitImagePtr
                                                bitmapStartLocation:location
                                                       bitmapStride:(rowWords * 2)];
        charImageMap[[NSNumber numberWithInteger:i]] = charImage;
    }
    font.charImageMap = charImageMap;
    
    return font;
}

- (id)init
{
    if ((self = [super init])) {
        self.charImageMap = @{};
    }
    return self;
}

- (NSUInteger)countOfPresentCharacters
{
    return self.charImageMap.count;
}

- (BOOL)characterIsPresent:(NSUInteger)character
{
    return [self.charImageMap objectForKey:[NSNumber numberWithInteger:character]] != nil;
}

- (CharacterImage *)imageForCharacter:(NSUInteger)character
{
    CharacterImage * charImage = [self.charImageMap objectForKey:[NSNumber numberWithInteger:character]];
    if (!charImage) {
        charImage = self.missingCharImage;
    }
    return charImage;
}

- (CharacterImage *)missingCharacterImage
{
    return self.missingCharImage;
}
@end

//
// Utility functions
//

static NSString * FontNameFromResourceId(uint16 resourceId)
{
    uint16 maskedNumber = (resourceId >> 7) & 0x00FF;
    NSInteger fontNumber = (NSInteger)maskedNumber;
    switch (fontNumber) {
        case 0:
            return @"Chicago";
        case 1:
            NSLog(@"Resource ID has unexpected font number 1 (application font)");
            // Default to Geneva, which was the Mac's default for this.
            return @"Geneva";
        case 2:
            return @"New York";
        case 3:
            return @"Geneva";
        case 4:
            return @"Monaco";
        case 5:
            return @"Venice";
        case 6:
            return @"London";
        case 7:
            return @"Athens";
        case 8:
            return @"San Francisco";
        case 9:
            return @"Toronto";
        case 10:
            // There was no apparent documented font number 10.
            NSLog(@"Resource ID has unexpected font number 10");
            return @"Unknown (Apple) #10";
        case 11:
            return @"Cairo";
        case 12:
            return @"Los Angeles";
        case 20:
            return @"Times";
        case 21:
            return @"Helvetica";
        case 22:
            return @"Courier";
        case 23:
            return @"Symbol";
        case 24:
            return @"Taliesin";
            
        default:
            if (fontNumber <= 127) {
                return [NSString stringWithFormat:@"Unknown (Apple) #%ld", fontNumber];
            } else {
                return [NSString stringWithFormat:@"Unknown (3rd Party) #%ld", fontNumber];
            }
    }
}

static NSInteger FontSizeFromResourceId(uint16 resourceId)
{
    uint16 maskedSize = resourceId & 0x007F;
    if (maskedSize == 0) {
        NSLog(@"Resource ID has invalid font size 0");
        return -1;
    }
    return (NSInteger)maskedSize;
}

