//
//  CharacterImage.m
//  Copyright © 2018 Ben Zotto. All rights reserved.
//

#import "CharacterImage.h"

@interface CharacterImage ()
{
    uint8 * _image;
}
@property (assign) NSUInteger characterWidth;
@property (assign) NSInteger characterOffset;
@property (assign) UIntSize characterRectSize;
@end

@implementation CharacterImage
+ (instancetype)imageWithWidth:(NSUInteger)width
                        offset:(NSInteger)offset
                      rectSize:(UIntSize)size       // size of character rect in bits (image width x font height)
                    fromBitmap:(uint8 *)bitmap      // base pointer to image bitmap to copy from
           bitmapStartLocation:(NSUInteger)startLocation // bit location from the start where this image begins
                  bitmapStride:(NSUInteger)stride  // stride of bitmap pointer (in bytes)
{
    CharacterImage * image = [[CharacterImage alloc] init];
    image.characterWidth = width;
    image.characterOffset = offset;
    image.characterRectSize = size;
    NSUInteger bitmapsize = size.width * size.height * sizeof(uint8);
    if (bitmapsize == 0) {
        return image;
    }
    
    image->_image = malloc(bitmapsize);
    if (!image->_image) {
        return nil;
    }

    for (NSUInteger y = 0; y < size.height; y++) {
        for (NSUInteger x = 0; x < size.width; x++) {
            NSUInteger loc = startLocation + x;
            uint8 byte = bitmap[(stride * y) + (loc / 8)];
            uint8 value = (byte >> (7 - (loc % 8))) & 0x01;
            image->_image[y * size.width + x] = value;
        }
    }
    
    return image;
}

- (void)dealloc
{
    if (_image) {
        free(_image);
    }
}

- (uint8 *)image
{
    return _image;
}

- (BOOL)isWhitespace
{
    return self.characterRectSize.width == 0;
}

- (NSString *)imageAsDebugString
{
    NSMutableString * str = [[NSMutableString alloc] init];
    for (int y = 0; y < self.characterRectSize.height; y++) {
        for (int x = 0; x < self.characterRectSize.width; x++) {
            int value = self.image[y * self.characterRectSize.width + x];
            if (value) {
                [str appendString:@"X"];
            } else {
                [str appendString:@"."];
            }
        }
        [str appendString:@"\n"];
    }
    return str;
}
@end
