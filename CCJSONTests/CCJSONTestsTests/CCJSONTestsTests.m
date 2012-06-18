//
//  CCJSONTestsTests.m
//  CCJSONTestsTests
//
//  Created by Jonathan Johnson on 6/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CCJSONTestsTests.h"
#import "CCJSON.h"

@implementation CCJSONTestsTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testSimpleDict
{
    NSDictionary *obj = [CCJSONParser objectFromJSON:@"{\"a\":[1,true,1.0]}"];
    STAssertNotNil(obj,@"JSON Failed to parse");
}

- (void)testWhitespaceDict
{
    NSDictionary *obj = [CCJSONParser objectFromJSON:@"  { \"a\" : [ 1  , true , 1.0 ] }  "];
    STAssertNotNil(obj,@"JSON Failed to parse");
}

@end
