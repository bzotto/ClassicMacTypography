//
//  UIntTypes.h
//  Copyright © 2018 Ben Zotto. All rights reserved.
//

#ifndef UIntTypes_h
#define UIntTypes_h

#import <Foundation/Foundation.h>

typedef struct _UIntPoint {
    NSUInteger x;
    NSUInteger y;
} UIntPoint;
UIntPoint UIntPointMake(NSUInteger x, NSUInteger y);

typedef struct _UIntSize {
    NSUInteger width;
    NSUInteger height;
} UIntSize;
UIntSize UIntSizeMake(NSUInteger width, NSUInteger height);

typedef struct _UIntRect {
    UIntPoint origin;
    UIntSize size;
} UIntRect;
UIntRect UIntRectMake(NSUInteger x, NSUInteger y, NSUInteger width, NSUInteger height);

#endif /* UIntTypes_h */
