//
//  SimpleBitmapRenderer.h
//  Copyright © 2018 Ben Zotto. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIntTypes.h"
#import "BitmapFont.h"
#import "MacRomanString.h"

@interface SimpleBitmapRenderer : NSObject
@property (readonly) UIntSize size;
@property (strong) BitmapFont * currentFont;

- (id)initWithSize:(UIntSize)size;

// Returns the width from the leftmost origin start to the rightmost pixel for given string
// in the current font. Will not trim printable whitespace which will be
// included in measurement.
- (NSUInteger)measureWidthForString:(MacRomanString *)str;

// Render the string onto the canvas using the the origin point (at baseline
// of first character) with the current font. No line-wrapping or any layout at all.
- (void)renderString:(MacRomanString *)str atOrigin:(UIntPoint)origin;

// Layout the string inside the rect and render onto the canvas. Does
// best effort simple word wrapping. Does not pixel-clip to the rect; glyphs that will
// not fall wholly within the rect will not be rendered. The word wrapping algorithm
// is naive and doesn't handle edge cases like double-spaces.
- (void)renderString:(MacRomanString *)str inRect:(UIntRect)rect;

// Render the complete set of present characters in the current font, into the rect as possible.
- (void)renderCharSetInRect:(UIntRect)rect;

// Retrieving images of the rendered "canvas".
- (NSString *)bitmapImageAsString;
- (NSData *)bitmapImageAsPNGDataWithScale:(NSUInteger)scale showingGrid:(BOOL)showGrid;
@end
