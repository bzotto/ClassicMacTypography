//
//  CharacterImage.h
//  Copyright © 2018 Ben Zotto. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIntTypes.h"

@interface CharacterImage : NSObject
@property (readonly) NSUInteger characterWidth;
@property (readonly) NSInteger characterOffset;
@property (readonly) UIntSize characterRectSize;

+ (instancetype)imageWithWidth:(NSUInteger)width
                        offset:(NSInteger)offset
                      rectSize:(UIntSize)size       // size of character rect in bits (image width x font height)
                    fromBitmap:(uint8 *)bitmap      // base pointer to image bitmap to copy from
           bitmapStartLocation:(NSUInteger)startLocation // bit location from the start where this image begins
                  bitmapStride:(NSUInteger)stride;  // stride of bitmap pointer (in bytes)

// This is a byte-sized bitmap array of dimension characterRectSize.
// A byte value is zero for an off (transparent) pixel and nonzero for an on (solid) one.
- (uint8 *)image;
- (BOOL)isWhitespace;

// Dumps out the image as a text figure with X's and .'s.
- (NSString *)imageAsDebugString;
@end
