//
//  CCJSONWriter.m
//  CCJSON
//
//  Created by Jonathan Johnson on 8/18/09.
//  Copyright 2009 Jonathan Johnson. All rights reserved.
// 
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.

#import "CCJSONWriter.h"

@interface CCJSONWriter(private)

+ (void)appendString:(NSString *)string toString:(NSMutableString *)json;
+ (void)appendNumber:(NSNumber *)number toString:(NSMutableString *)json;
+ (void)appendDictionary:(NSDictionary *)dictionary toString:(NSMutableString *)json;
+ (void)appendArray:(NSArray *)array toString:(NSMutableString *)json;
+ (void)appendValueOfObject:(id)object toString:(NSMutableString *)json;

@end

@implementation CCJSONWriter

+ (void)appendString:(NSString *)string toString:(NSMutableString *)json {
    static NSMutableCharacterSet *sCharsToEscape;
    if (!sCharsToEscape) {
        sCharsToEscape = [[NSCharacterSet alloc] init]; 
		[sCharsToEscape addCharactersInRange:NSMakeRange(0,32)];
        [sCharsToEscape addCharactersInString:@"\\\""];
    }
    
    [json appendString:@"\""];
    
    NSRange esc = [string rangeOfCharacterFromSet:sCharsToEscape];
    if (esc.length == 0) {
        [json appendString:string];
    } else {
		// Take the part of the string already scanned
		[json appendString:[string substringToIndex:esc.location]];
		
		// Scan the rest by hand
        NSUInteger length = [string length];
        for (NSUInteger i = esc.location; i < length; i++) {
            unichar c = [string characterAtIndex:i];
            switch (c) {
                case '"':  [json appendString:@"\\\""]; break;
                case '\\': [json appendString:@"\\\\"]; break;
                case '\t': [json appendString:@"\\t"]; break;
                case '\n': [json appendString:@"\\n"]; break;
                case '\r': [json appendString:@"\\r"]; break;
                case '\b': [json appendString:@"\\b"]; break;
                case '\f': [json appendString:@"\\f"]; break;
                default:    
                    if (c < 0x20) {
                        [json appendFormat:@"\\u%04x", c];
                    } else {
                        CFStringAppendCharacters((CFMutableStringRef)json, &c, 1);
                    }
                    break;
            }
        }
    }
    
    [json appendString:@"\""];
}

+ (void)appendNumber:(NSNumber *)number toString:(NSMutableString *)json {
	if (CFGetTypeID((CFTypeRef)number) == CFBooleanGetTypeID()) {
		[json appendString:[number boolValue] ? @"true" : @"false"];
	} else {
		[json appendString:[number stringValue]];
	}
}

+ (void)appendDictionary:(NSDictionary *)dictionary toString:(NSMutableString *)json {
	NSArray *keys = [dictionary objectForKey:CCJSONFieldOrderKey];
	if (!keys) {
		keys = [dictionary allKeys];
	}
	[json appendString:@"{"];
	BOOL first = YES;
	for (id key in keys) {
		if (first) {
			first = NO;
		} else {
			[json appendString:@","];
		}
		[self appendValueOfObject:key toString:json];
		[json appendString:@":"];
		[self appendValueOfObject:[dictionary objectForKey:key] toString:json];
	}
	[json appendString:@"}"];
}

+ (void)appendArray:(id)array toString:(NSMutableString *)json {
	[json appendString:@"["];
	BOOL first = YES;
	for (id obj in array) {
		if (first) {
			first = NO;
		} else {
			[json appendString:@","];
		}
		[self appendValueOfObject:obj toString:json];
	}
	[json appendString:@"]"];
}

+ (void)appendValueOfObject:(id)object toString:(NSMutableString *)json {
	if ([object isKindOfClass:[NSNumber class]]) {
		[self appendNumber:object toString:json];
	} else if ([object isKindOfClass:[NSString class]]) {
		[self appendString:object toString:json];
	} else if ([object isKindOfClass:[NSDictionary class]]) {
		[self appendDictionary:object toString:json];
	} else if (object == [NSNull null]) {
		[json appendString:@"null"];
	} else if ([object isKindOfClass:[NSArray class]] || [object conformsToProtocol:@protocol(NSFastEnumeration)]) {
		[self appendArray:object toString:json];
	} else {
		NSLog(@"Unknown data type: %@", [object class]);
	}
}

+ (NSString *)stringFromDictionary:(NSDictionary *)dictionary {
	NSMutableString *json = [NSMutableString string];
	[self appendDictionary:dictionary toString:json];
	return json;
}

+ (NSString *)stringFromArray:(NSArray *)array {
	NSMutableString *json = [NSMutableString string];
	[self appendArray:array toString:json];
	return json;
}

+ (NSString *)stringFromString:(NSString *)str {
	NSMutableString *json = [NSMutableString string];
	[self appendString:str toString:json];
	return json;
}

@end
