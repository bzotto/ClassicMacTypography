//
//  UIntTypes.m
//  Copyright © 2018 Ben Zotto. All rights reserved.
//

#import "UIntTypes.h"

UIntPoint UIntPointMake(NSUInteger x, NSUInteger y)
{
    UIntPoint point; point.x = x; point.y = y; return point;
}

UIntSize UIntSizeMake(NSUInteger width, NSUInteger height)
{
    UIntSize size; size.width = width; size.height = height; return size;
}

UIntRect UIntRectMake(NSUInteger x, NSUInteger y, NSUInteger width, NSUInteger height)
{
    UIntRect rect; rect.origin = UIntPointMake(x, y); rect.size = UIntSizeMake(width, height); return rect;
}
