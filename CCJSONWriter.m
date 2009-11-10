//
//  CCJSONWriter.m
//  Jamaica2Go
//
//  Created by Jonathan Johnson on 9/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

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
	[json appendString:@"{"];
	BOOL first = YES;
	for (id key in [dictionary allKeys]) {
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

@end
