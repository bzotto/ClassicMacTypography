//
//  BitmapTextRenderer.m
//  Copyright © 2018 Ben Zotto. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "SimpleBitmapRenderer.h"

@interface SimpleBitmapRenderer ()
{
    uint8 * _canvas;
}
@property (assign) UIntSize size;
@end

@implementation SimpleBitmapRenderer
- (id)initWithSize:(UIntSize)size
{
    if ((self = [super init])) {
        _canvas = malloc(size.width * size.height);
        if (!_canvas) {
            return nil;
        }
        memset(_canvas, 0, size.width * size.height);
        self.size = size;
    }
    return self;
}

- (void)dealloc
{
    if (_canvas) {
        free(_canvas);
    }
}

- (NSUInteger)measureWidthForString:(MacRomanString *)str
{
    if (!self.currentFont) {
        return 0;
    }
    NSUInteger width = 0;
    for (int i = 0; i < str.length; i++) {
        NSUInteger ch = [str characterAtIndex:i];
        CharacterImage * charImage = [self.currentFont imageForCharacter:ch];
        if (i == str.length-1) {
            width += charImage.characterRectSize.width;
        } else {
            if (self.currentFont.isProportional) {
                width += charImage.characterWidth;
            } else {
                width += self.currentFont.widMax;
            }
        }
    }
    return width;
}

- (UIntPoint)renderCharacter:(CharacterImage *)image atPenLocation:(UIntPoint)location
{
    // How many pixels does this character kern?
    // NOTE: This little computation is given by Inside Macintosh docs. But based on
    // my understanding, it doesn't seem like it would be correct to use the result of
    // this to shift the image blit. However, since none of the Apple fonts seem to have
    // anything but zero for kernMax, it's a no-op. :shrug:
    NSInteger kern = image.characterOffset + self.currentFont.kernMax;
    
    // Blit the character image at the pen's x plus net kern, and at the pen y.
    for (int y = 0; y < image.characterRectSize.height; y++) {
        for (int x = 0; x < image.characterRectSize.width; x++) {
            uint8 val = [image image][y * image.characterRectSize.width + x];
            if (val) {
                UIntPoint dest = UIntPointMake(location.x + kern + x, location.y - self.currentFont.ascent + y);
                [self setPixelAtLocation:dest];
            }
        }
    }
    
    // Advance the pen by the width of the character.
    if (self.currentFont.isProportional) {
        location.x += image.characterWidth;
    } else {
        location.x += self.currentFont.widMax;
    }
    return location;
}

- (void)renderString:(MacRomanString *)str atOrigin:(UIntPoint)origin
{
    if (!self.currentFont) {
        return;
    }
    UIntPoint pen = origin;
    for (int i = 0; i < str.length; i++) {
        NSUInteger ch = [str characterAtIndex:i];
        CharacterImage * charImage = [self.currentFont imageForCharacter:ch];
        pen = [self renderCharacter:charImage atPenLocation:pen];
    }
}

- (void)renderString:(MacRomanString *)str inRect:(UIntRect)rect
{
    if (!self.currentFont) {
        return;
    }
    // If the rect isn't big enough to hold even a single character of text, bail.
    if (rect.size.height < self.currentFont.fRectHeight ||
        rect.size.width < self.currentFont.fRectWidth) {
        return;
    }
    if (str.length == 0) {
        return;
    }
    // Always start the pen with an "ascent" offset from the top of rect.
    NSUInteger leftEdge = rect.origin.x + self.currentFont.kernMax;
    UIntPoint pen = UIntPointMake(leftEdge, rect.origin.y + self.currentFont.ascent);
    
    int wordStartIndex = 0;
    while (wordStartIndex < str.length) {
        // Find the next nonprinting (whitespace) character.
        int nextWhitespaceIndex = wordStartIndex + 1;
        for (; nextWhitespaceIndex < str.length; nextWhitespaceIndex++) {
            NSUInteger ch = [str characterAtIndex:nextWhitespaceIndex];
            if (ch == '\n' || ch == '\r' || [self.currentFont imageForCharacter:ch].isWhitespace) {
                break;
            }
        }
        MacRomanString * substring = [str substringWithRange:NSMakeRange(wordStartIndex, nextWhitespaceIndex - wordStartIndex)];
        NSUInteger substringWidth = [self measureWidthForString:substring];
        // Check for the special case of the substring being not just too big for current remaining.
        // width but for the full rect width, which will require a forced break in the word.
        while (substringWidth > rect.size.width && nextWhitespaceIndex > wordStartIndex) {
            nextWhitespaceIndex--;
            substring = [str substringWithRange:NSMakeRange(wordStartIndex, nextWhitespaceIndex - wordStartIndex)];
            substringWidth = [self measureWidthForString:substring];
        }
        // Does substring fit in remaining space on current line?
        if (pen.x + substringWidth > rect.origin.x + rect.size.width) {
            // CRLF.
            pen.x = leftEdge;
            pen.y += (self.currentFont.descent + self.currentFont.leading + self.currentFont.ascent);
            if (pen.y + self.currentFont.descent > rect.origin.y + rect.size.height) {
                // next line too short so we're done early!
                goto Done;
            }
        }
        // Render the subtring.
        for (int i = wordStartIndex; i < nextWhitespaceIndex; i++) {
            CharacterImage * charImage = [self.currentFont imageForCharacter:[str characterAtIndex:i]];
            pen = [self renderCharacter:charImage atPenLocation:pen];
        }
        // Render the sequence of whitespace, if any, after the word.
        for(; nextWhitespaceIndex < str.length; nextWhitespaceIndex++) {
            NSUInteger ch = [str characterAtIndex:nextWhitespaceIndex];
            CharacterImage * charImage = [self.currentFont imageForCharacter:ch];
            // Handle special cases CR/LF.
            if (ch == '\n' || ch == '\r') {
                pen.x = leftEdge;
                pen.y += (self.currentFont.descent + self.currentFont.leading + self.currentFont.ascent);
                if (pen.y + self.currentFont.descent > rect.origin.y + rect.size.height) {
                    // next line too short so we're done
                    goto Done;
                }
            } else if (!charImage.isWhitespace) {
                wordStartIndex = nextWhitespaceIndex;
                break;
            } else {
                pen = [self renderCharacter:charImage atPenLocation:pen];
            }
        }
        
        if (nextWhitespaceIndex >= str.length) {
            break;
        }
    }
Done:
    ;
}

- (void)renderCharSetInRect:(UIntRect)rect
{
    if (!self.currentFont) {
        return;
    }
    // If the rect isn't big enough to hold even a single character of text, bail.
    if (rect.size.height < self.currentFont.fRectHeight ||
        rect.size.width < self.currentFont.fRectWidth) {
        return;
    }

    // Always start the pen with an "ascent" offset from the top of rect.
    NSUInteger leftEdge = rect.origin.x + self.currentFont.kernMax;
    UIntPoint pen = UIntPointMake(leftEdge, rect.origin.y + self.currentFont.ascent);
    for (int ch = 1; ch < 256; ch++) {
        CharacterImage * charImage = [self.currentFont imageForCharacter:ch];
        if (ch == 255) {
            charImage = self.currentFont.missingCharacterImage;
        } else if (![self.currentFont characterIsPresent:ch] || charImage.characterRectSize.width == 0) {
            continue;
        }
        NSInteger kern = charImage.characterOffset + self.currentFont.kernMax;
        // Is there enough room on the canvas left to draw this character?
        if (pen.x + kern + charImage.characterRectSize.width >= rect.size.width) {
            pen.x = leftEdge;
            pen.y += (self.currentFont.descent + self.currentFont.leading + self.currentFont.ascent);
            // If we went past the edge, STOP.
            if (pen.y + self.currentFont.descent > rect.origin.y + rect.size.height) {
                // next line too short so we're done
                return;
            }
        }

        pen = [self renderCharacter:charImage atPenLocation:pen];
    }
}
//
// Retrieval
//

- (NSString *)bitmapImageAsString
{
    NSMutableString * str = [[NSMutableString alloc] init];
    for (int y = 0; y < self.size.height; y++) {
        for (int x = 0; x < self.size.width; x++) {
            uint8 val = _canvas[y * self.size.width + x];
            switch (val) {
                case 0:
                    [str appendString:@" "];
                    break;
                default:
                    [str appendString:@"X"];
                    break;
            }
        }
        [str appendString:@"\n"];
    }
    return str;
}

- (NSData *)bitmapImageAsPNGDataWithScale:(NSUInteger)scale showingGrid:(BOOL)showGrid
{
    if (scale == 0) {
        return nil;
    }
    if (scale == 1) {
        showGrid = NO;
    }
    CGSize contextSize = CGSizeMake(self.size.width * scale, self.size.height * scale);
    int bytesPerRow = contextSize.width * 4;
    int bytesTotal = bytesPerRow * contextSize.height;
    void * bitmapData = calloc(bytesTotal, sizeof(uint8));
    if (!bitmapData) {
        return nil;
    }
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    CGContextRef context = CGBitmapContextCreate (bitmapData,
                                                  contextSize.width,
                                                  contextSize.height,
                                                  8,
                                                  bytesPerRow,
                                                  colorSpace,
                                                  kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    if (!context) {
        free(bitmapData);
        return nil;
    }
    
    // Flip the context
    CGContextTranslateCTM(context, 0, contextSize.height);
    CGContextScaleCTM(context, 1, -1);
    
    // Fill with white background
    CGContextSetRGBFillColor(context, 1, 1, 1, 1);
    CGContextFillRect(context, CGRectMake(0, 0, contextSize.width, contextSize.height));
    
    for (int y = 0; y < self.size.height; y++) {
        for (int x = 0; x < self.size.width; x++) {
            uint8 val = _canvas[y * self.size.width + x];
            // Set color
            if (val) {
                CGContextSetRGBFillColor(context, 0, 0, 0, 1);
            } else {
                if (showGrid) {
                    CGContextSetRGBFillColor(context, 0.9, 0.9, 0.9, 1.0);
                } else {
                    CGContextSetRGBFillColor(context, 1, 1, 1, 1);
                }
            }
            // Draw
            if (showGrid) {
                CGRect pixel = CGRectMake(x * scale + 1, y * scale + 1, scale-1, scale-1);
                CGContextFillRect(context, pixel);
            } else {
                CGRect pixel = CGRectMake(x * scale, y * scale, scale, scale);
                CGContextFillRect(context, pixel);
            }
        }
    }
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    NSBitmapImageRep * newRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
    [newRep setSize:contextSize];
    NSData * pngData = [newRep representationUsingType:NSPNGFileType properties:@{}];
    CGImageRelease(imageRef);
    free(bitmapData);
    return pngData;
}

//
// Private routines
//
- (void)setPixelAtLocation:(UIntPoint)pt
{
    if (pt.x >= self.size.width) {
        return;
    } else if (pt.y >= self.size.height) {
        return;
    }
    _canvas[pt.y * self.size.width + pt.x] = 1;
}
@end

