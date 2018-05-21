//
//  MacRomanString.h
//  Copyright © 2018 Ben Zotto. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MacRomanString : NSObject
@property (readonly) NSUInteger length;
- (id)initWithCString:(const char *)cstring;
- (id)initWithCChars:(const char *)cchars length:(NSUInteger)length;
- (unsigned char)characterAtIndex:(NSUInteger)index;
- (MacRomanString *)substringWithRange:(NSRange)range;
@end

// Handy category for NSString 
@interface NSString (MacRomanString)
- (MacRomanString *)macRomanString;
@end
