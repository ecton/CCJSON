//
//  CCJSONWriter.h
//  Jamaica2Go
//
//  Created by Jonathan Johnson on 9/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CCJSONWriter : NSObject {

}

+ (NSString *)stringFromDictionary:(NSDictionary *)dictionary;
+ (NSString *)stringFromArray:(NSArray *)array;

@end
