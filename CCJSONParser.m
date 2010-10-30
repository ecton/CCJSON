//
//  CCJSONParser.m
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


#import "CCJSONParser.h"

#define SkipWhitespace(offset, json, jsonLength) \
		while (offset < jsonLength && (json[offset] == '\t' || json[offset] == ' ' || json[offset] == '\r' || json[offset] == '\n')) { \
			offset += 1; \
		}
		
#define xtod(c) ((c) >= '0' && (c) <= '9' ? (c) - '0' : ((c) >= 'A' && (c) <= 'F' ? (c) + 10 - 'A' : ((c) >= 'a' && (c) <= 'f' ? (c) + 10 - 'a' : 0)))

#define PARSE_ERROR(message, offset, outError) {\
	if (outError) { \
		*outError = [NSError errorWithDomain:@"cocoaconjuror.cc" code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys: message, @"message", [NSNumber numberWithInt:offset], @"offset", nil]]; \
	}\
	*inOutOffset = offset;\
	return nil;}


@implementation CCJSONParser

static id ParseJSONObject(int *inOutOffset, unichar *json, int jsonLength, BOOL useNSNull, NSError **outError) {
	// Skip any whitespace
	int offset = *inOutOffset;
	while (json[offset] == '\t' || json[offset] == ' ' || json[offset] == '\r' || json[offset] == '\n') {
		offset += 1;
	}
	if (offset < jsonLength) {
		switch (json[offset]) {
			case '{': { // Object
				offset += 1;
				NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:16];
				SkipWhitespace(offset, json, jsonLength);
				if (offset < jsonLength && json[offset] != '}') {
					while (true) {
						SkipWhitespace(offset, json, jsonLength);
						*inOutOffset = offset;
						id key = ParseJSONObject(inOutOffset, json, jsonLength, useNSNull, outError);
						if (outError && *outError) return nil;
						offset = *inOutOffset;
						SkipWhitespace(offset, json, jsonLength);
						if (offset >= jsonLength || json[offset] != ':') PARSE_ERROR(@"Expected : for object value", offset, outError);
						offset += 1;
						SkipWhitespace(offset, json, jsonLength);
						*inOutOffset = offset;
						id value = ParseJSONObject(inOutOffset, json, jsonLength, useNSNull, outError);
						if (outError && *outError) return nil;
						offset = *inOutOffset;
						if (value) {
							[dict setObject:value forKey:key];
							[value release];
						}
						[key release];
						if (offset >= jsonLength || json[offset] != ',') break;
						offset += 1;
					}
					SkipWhitespace(offset, json, jsonLength);
				}
				if (offset >= jsonLength || json[offset] != '}') PARSE_ERROR(@"Expected } to close object", offset, outError);
				offset += 1;
				*inOutOffset = offset;
				return dict;
			} break;
			
			case '[': { // Array
				offset += 1;
				NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:16];
				SkipWhitespace(offset, json, jsonLength);
				if (offset < jsonLength && json[offset] != ']') {
					while (true) {
						SkipWhitespace(offset, json, jsonLength);
						
						*inOutOffset = offset;
						id value = ParseJSONObject(inOutOffset, json, jsonLength, useNSNull, outError);
						if (outError && *outError) return nil;
						offset = *inOutOffset;
						[array addObject:value];
						[value release];
						if (offset >= jsonLength || json[offset] != ',') break;
						offset += 1;
					}
					SkipWhitespace(offset, json, jsonLength);
				}
				if (offset >= jsonLength || json[offset] != ']') PARSE_ERROR(@"Expected ] to close array", offset, outError);
				offset += 1;
				*inOutOffset = offset;
				return array;
			} break;
			
			case '"': { // String
				offset += 1;
				NSString *str = nil;
				unichar stringBuffer[1024];
				int uncommittedLength = 0;
				while (offset < jsonLength && json[offset] != '"') {
					unichar ch = json[offset];
					offset += 1;
					if (ch == '\\') {
						if (offset >= jsonLength) PARSE_ERROR(@"Expected escape char, but got EOF", offset, outError);
						ch = json[offset];
						offset += 1;
						switch (ch) {
							case '\\': stringBuffer[uncommittedLength++] = ch; break;
							case '"':	ch = '"'; stringBuffer[uncommittedLength++] = ch; break;
							case '/':	ch = '/'; stringBuffer[uncommittedLength++] = ch; break;
							case 'b':	ch = '\b'; stringBuffer[uncommittedLength++] = ch; break;
							case 'f':	ch = '\f'; stringBuffer[uncommittedLength++] = ch; break;
							case 'n':	ch = '\n'; stringBuffer[uncommittedLength++] = ch; break;
							case 'r':	ch = '\r'; stringBuffer[uncommittedLength++] = ch; break;
							case 't':	ch = '\t'; stringBuffer[uncommittedLength++] = ch; break;
							case 'u':	
								if (offset + 4 >= jsonLength) PARSE_ERROR(@"Expected 4 hex chars for unicode char", offset, outError);
								ch = xtod(json[offset]) << 12 | xtod(json[offset + 1]) << 8 | xtod(json[offset + 2]) << 4 | xtod(json[offset + 3]);
								offset += 4;
								stringBuffer[uncommittedLength++] = ch;
							break;
						}
					} else {
						stringBuffer[uncommittedLength++] = ch;
					}
					if (uncommittedLength == 1024) {
						if (!str) {
							// If we've already consumed 1k, it could be much longer -- let's allocate more space to avoid another resize
							str = [[NSMutableString alloc] initWithCapacity:4096];
						}
						CFStringAppendCharacters((CFMutableStringRef)str, stringBuffer, uncommittedLength);
						uncommittedLength = 0;
					}
				}
				if (uncommittedLength > 0) {
					if (!str) {
						str = [[NSString alloc] initWithCharacters:stringBuffer length:uncommittedLength];
					} else {
						CFStringAppendCharacters((CFMutableStringRef)str, stringBuffer, uncommittedLength);
					}
				}
				if (offset >= jsonLength || json[offset] != '"') PARSE_ERROR(@"Expected closing quote of string", offset, outError);
				offset += 1;
				*inOutOffset = offset;
				return str;
			} break; 
			
			case 't': { // true
				if (offset + 4 < jsonLength && json[offset + 1] == 'r' && json[offset + 2] == 'u' && json[offset + 3] == 'e') {
					offset += 4;
					*inOutOffset = offset;
					return [[NSNumber alloc] initWithBool:YES];
				} else {
					PARSE_ERROR(@"Unknown value", offset, outError);
				}
			} break; 
			
			case 'f': { // false
				if (offset + 5 < jsonLength && json[offset + 1] == 'a' && json[offset + 2] == 'l' && json[offset + 3] == 's' && json[offset + 4] == 'e') {
					offset += 5;
					*inOutOffset = offset;
					return [[NSNumber alloc] initWithBool:NO];
				} else {
					PARSE_ERROR(@"Unknown value", offset, outError);
				}
			} break; 
			
			case 'n': { // null
				if (offset + 4 < jsonLength && json[offset + 1] == 'u' && json[offset + 2] == 'l' && json[offset + 3] == 'l') {
					offset += 4;
					*inOutOffset = offset;
					if (useNSNull) {
						return [[NSNull null] retain];
					}
					return NULL;
				} else {
					PARSE_ERROR(@"Unknown value", offset, outError);
				}
			} break; 
			
			default: { // Number or bad stuff
				BOOL valid = NO;
				double value = 0;
				BOOL neg = NO;
				if (json[offset] == '-') {
					neg = YES;
					valid = YES;
					offset += 1;
				}
				
				while (offset < jsonLength && json[offset] >= '0' && json[offset] <= '9') {
					value = value * 10 + json[offset] - '0';
					valid = YES;
					offset += 1;
				}
				
				if (offset < jsonLength && json[offset] == '.') {
					offset += 1;
					valid = YES;
					double place = 10;					
					while (offset < jsonLength && json[offset] >= '0' && json[offset] <= '9') {
						value = value + (double)(json[offset] - '0') / place;
						place *= 10;
						offset += 1;
					}
				}
				
				if (offset < jsonLength && (json[offset] == 'e' || json[offset] == 'E')) {
					offset += 1;
					valid = YES;
					BOOL posExp = YES;
					if (offset < jsonLength && json[offset] == '+') {
						offset += 1;
					} else if (offset < jsonLength && json[offset] == '+') {
						posExp = NO;
						offset += 1;
					}
					
					double exp = 0;
					while (offset < jsonLength && json[offset] >= '0' && json[offset] <= '9') {
						exp = exp * 10 + json[offset] - '0';
						offset += 1;
					}
					
					value = value * pow(10, posExp ? exp : -exp);
				}
				
				if (!valid) {
					PARSE_ERROR(@"Invalid data", offset, outError);
				}
				
				if (neg) value = -value;
				
				*inOutOffset = offset;
				return [[NSNumber alloc] initWithDouble:value];
			} break; 
		}
	}
	*inOutOffset = offset;
	return nil;
}

+ (id)objectFromJSON:(NSString *)jsonString {
	return [self objectFromJSON:jsonString useNSNull:YES];
}

+ (id)objectFromJSON:(NSString *)jsonString useNSNull:(BOOL)useNSNull {
	int jsonLength = [jsonString length];
	unichar *json = malloc(jsonLength * sizeof(unichar));
	[jsonString getCharacters:json];
	
	int consumedLength = 0;
	NSError *error = nil;
	id obj = ParseJSONObject(&consumedLength, json, jsonLength, useNSNull, &error);
	if (error) {
		NSLog(@"%@", [error description]);
		NSLog(@"%@", [[error userInfo] description]);
	}
	
	free(json);
	return [obj autorelease];
}

@end
