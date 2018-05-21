//
//  MacRomanString.m
//  Copyright © 2018 Ben Zotto. All rights reserved.
//

#import "MacRomanString.h"

@interface MacRomanString ()
{
    unsigned char * _cstring;
    NSUInteger _length;
}
@end

@implementation MacRomanString
- (id)initWithCString:(const char *)cstring
{
    if (!cstring) return nil;
    if ((self = [super init])) {
        self->_length = strlen(cstring);
        self->_cstring = (unsigned char *)strdup(cstring);
        if (!self->_cstring) {
            return nil;
        }
    }
    return self;
}

- (id)initWithCChars:(const char *)cchars length:(NSUInteger)length
{
    if (!cchars) return nil;
    if ((self = [super init])) {
        self->_length = length;
        self->_cstring = malloc(length + 1);
        if (!self->_cstring) {
            return nil;
        }
        memcpy(self->_cstring, cchars, length);
        self->_cstring[length] = '\0';
    }
    return self;
}

- (void)dealloc
{
    if (_cstring) {
        free(_cstring);
    }
}
- (unsigned char)characterAtIndex:(NSUInteger)index
{
    assert(index < self->_length);
    return _cstring[index];
}

- (MacRomanString *)substringWithRange:(NSRange)range
{
    if (range.location + range.length > self->_length) {
        return nil;
    }
    return [[MacRomanString alloc] initWithCChars:(const char *)&_cstring[range.location] length:range.length];
}
@end

//
// Category
//

@implementation NSString (MacRomanString)
- (MacRomanString *)macRomanString
{
    const char * cstr = [self cStringUsingEncoding:NSMacOSRomanStringEncoding];
    if (cstr) {
        return [[MacRomanString alloc] initWithCString:cstr];
    }
    return nil;
}
@end
