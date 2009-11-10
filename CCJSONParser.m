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
		while (*offset < jsonLength && (json[*offset] == '\t' || json[*offset] == ' ' || json[*offset] == '\r' || json[*offset] == '\n')) { \
			*offset += 1; \
		}
		
#define xtod(c) ((c) >= '0' && (c) <= '9' ? (c) - '0' : ((c) >= 'A' && (c) <= 'F' ? (c) + 10 - 'A' : ((c) >= 'a' && (c) <= 'f' ? (c) + 10 - 'a' : 0)))

#define PARSE_ERROR(message, offset, outError) {\
	if (outError) { \
		*outError = [NSError errorWithDomain:@"cocoaconjuror.cc" code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys: message, @"message", [NSNumber numberWithInt:offset], @"offset", nil]]; \
	}\
	return nil;}


@implementation CCJSONParser

static id ParseJSONObject(int *offset, unichar *json, int jsonLength, NSError **outError) {
	// Skip any whitespace
	while (json[*offset] == '\t' || json[*offset] == ' ' || json[*offset] == '\r' || json[*offset] == '\n') {
		*offset += 1;
	}
	if (*offset < jsonLength) {
		switch (json[*offset]) {
			case '{': { // Object
				*offset += 1;
				NSMutableDictionary *dict = [NSMutableDictionary dictionary];
				SkipWhitespace(offset, json, jsonLength);
				if (*offset < jsonLength && json[*offset] != '}') {
					while (true) {
						SkipWhitespace(offset, json, jsonLength);
						id key = ParseJSONObject(offset, json, jsonLength, outError);
						if (outError && *outError) return nil;
						SkipWhitespace(offset, json, jsonLength);
						if (*offset >= jsonLength || json[*offset] != ':') PARSE_ERROR(@"Expected : for object value", *offset, outError);
						*offset += 1;
						SkipWhitespace(offset, json, jsonLength);
						id value = ParseJSONObject(offset, json, jsonLength, outError);
						if (outError && *outError) return nil;
						[dict setObject:value forKey:key];
						if (*offset >= jsonLength || json[*offset] != ',') break;
						*offset += 1;
					}
					SkipWhitespace(offset, json, jsonLength);
				}
				if (*offset >= jsonLength || json[*offset] != '}') PARSE_ERROR(@"Expected } to close object", *offset, outError);
				*offset += 1;
				return dict;
			} break;
			
			case '[': { // Array
				*offset += 1;
				NSMutableArray *array = [NSMutableArray array];
				SkipWhitespace(offset, json, jsonLength);
				if (*offset < jsonLength && json[*offset] != ']') {
					while (true) {
						SkipWhitespace(offset, json, jsonLength);
						
						id value = ParseJSONObject(offset, json, jsonLength, outError);
						if (outError && *outError) return nil;
						[array addObject:value];
						if (*offset >= jsonLength || json[*offset] != ',') break;
						*offset += 1;
					}
					SkipWhitespace(offset, json, jsonLength);
				}
				if (*offset >= jsonLength || json[*offset] != ']') PARSE_ERROR(@"Expected ] to close array", *offset, outError);
				*offset += 1;
				return array;
			} break;
			
			case '"': { // String
				*offset += 1;
				NSMutableString *str = [NSMutableString string];
				while (*offset < jsonLength && json[*offset] != '"') {
					unichar ch = json[*offset];
					*offset += 1;
					if (ch == '\\') {
						if (*offset >= jsonLength) return nil;
						ch = json[*offset];
						*offset += 1;
						switch (ch) {
							case '\\':	CFStringAppendCharacters((CFMutableStringRef)str, (UniChar *)&ch, 1); break;
							case '"':	ch = '"'; CFStringAppendCharacters((CFMutableStringRef)str, (UniChar *)&ch, 1); break;
							case '/':	ch = '/'; CFStringAppendCharacters((CFMutableStringRef)str, (UniChar *)&ch, 1); break;
							case 'b':	ch = '\b'; CFStringAppendCharacters((CFMutableStringRef)str, (UniChar *)&ch, 1); break;
							case 'f':	ch = '\f'; CFStringAppendCharacters((CFMutableStringRef)str, (UniChar *)&ch, 1); break;
							case 'n':	ch = '\n'; CFStringAppendCharacters((CFMutableStringRef)str, (UniChar *)&ch, 1); break;
							case 'r':	ch = '\r'; CFStringAppendCharacters((CFMutableStringRef)str, (UniChar *)&ch, 1); break;
							case 't':	ch = '\t'; CFStringAppendCharacters((CFMutableStringRef)str, (UniChar *)&ch, 1); break;
							case 'u':	
								if (*offset + 4 >= jsonLength) PARSE_ERROR(@"Expected 4 hex chars for unicode char", *offset, outError);
								ch = xtod(json[*offset]) << 12 | xtod(json[*offset + 1]) << 8 | xtod(json[*offset + 2]) << 4 | xtod(json[*offset + 3]);
								*offset += 4;
								CFStringAppendCharacters((CFMutableStringRef)str, &ch, 1); 
							break;
						}
					} else {
						CFStringAppendCharacters((CFMutableStringRef)str, &ch, 1);
					}
				}
				if (*offset >= jsonLength || json[*offset] != '"') PARSE_ERROR(@"Expected closing quote of string", *offset, outError);
				*offset += 1;
				return str;
			} break; 
			
			case 't': { // true
				if (*offset + 4 < jsonLength && json[*offset + 1] == 'r' && json[*offset + 2] == 'u' && json[*offset + 3] == 'e') {
					*offset += 4;
					return [NSNumber numberWithBool:YES];
				} else {
					PARSE_ERROR(@"Unknown value", *offset, outError);
				}
			} break; 
			
			case 'f': { // false
				if (*offset + 5 < jsonLength && json[*offset + 1] == 'a' && json[*offset + 2] == 'l' && json[*offset + 3] == 's' && json[*offset + 4] == 'e') {
					*offset += 5;
					return [NSNumber numberWithBool:NO];
				} else {
					PARSE_ERROR(@"Unknown value", *offset, outError);
				}
			} break; 
			
			case 'n': { // null
				if (*offset + 4 < jsonLength && json[*offset + 1] == 'u' && json[*offset + 2] == 'l' && json[*offset + 3] == 'l') {
					*offset += 4;
					return [NSNull null];
				} else {
					PARSE_ERROR(@"Unknown value", *offset, outError);
				}
			} break; 
			
			default: { // Number or bad stuff
				double value = 0;
				BOOL neg = NO;
				if (json[*offset] == '-') {
					neg = YES;
					*offset += 1;
				}
				
				while (*offset < jsonLength && json[*offset] >= '0' && json[*offset] <= '9') {
					value = value * 10 + json[*offset] - '0';
					*offset += 1;
				}
				
				if (*offset < jsonLength && json[*offset] == '.') {
					*offset += 1;
					double place = 10;					
					while (*offset < jsonLength && json[*offset] >= '0' && json[*offset] <= '9') {
						value = value + (double)(json[*offset] - '0') / place;
						place *= 10;
						*offset += 1;
					}
				}
				
				if (*offset < jsonLength && (json[*offset] == 'e' || json[*offset] == 'E')) {
					*offset += 1;
					BOOL posExp = YES;
					if (*offset < jsonLength && json[*offset] == '+') {
						*offset += 1;
					} else if (*offset < jsonLength && json[*offset] == '+') {
						posExp = NO;
						*offset += 1;
					}
					
					double exp = 0;
					while (*offset < jsonLength && json[*offset] >= '0' && json[*offset] <= '9') {
						exp = exp * 10 + json[*offset] - '0';
						*offset += 1;
					}
					
					value = value * pow(10, posExp ? exp : -exp);
				}
				
				if (neg) value = -value;
				
				return [NSNumber numberWithDouble:value];
			} break; 
		}
	}
	return nil;
}

+ (id)objectFromJSON:(NSString *)jsonString {
	int jsonLength = [jsonString length];
	unichar *json = malloc(jsonLength * sizeof(unichar));
	[jsonString getCharacters:json];
	
	int consumedLength = 0;
	NSError *error = nil;
	id obj = ParseJSONObject(&consumedLength, json, jsonLength, &error);
	if (error) {
		NSLog(@"%@", [error description]);
		NSLog(@"%@", [[error userInfo] description]);
	}
	
	free(json);
	return obj;
}

@end
