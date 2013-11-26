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

- (void)testExponentation
{
    NSNumber *obj = [CCJSONParser objectFromJSON:@"1e2"];
    STAssertEqualsWithAccuracy([obj doubleValue], 100.0, 0.0001, @"1e2 != 100");
    obj = [CCJSONParser objectFromJSON:@"1e+2"];
    STAssertEqualsWithAccuracy([obj doubleValue], 100.0, 0.0001, @"1e+2 != 100");
    obj = [CCJSONParser objectFromJSON:@"1e-2"];
    STAssertEqualsWithAccuracy([obj doubleValue], 0.01, 0.0001, @"1e-2 != 0.01");
    obj = [CCJSONParser objectFromJSON:@"1.1e2"];
    STAssertEqualsWithAccuracy([obj doubleValue], 110.0, 0.0001, @"1.1e2 != 110");
    obj = [CCJSONParser objectFromJSON:@"1.1e+2"];
    STAssertEqualsWithAccuracy([obj doubleValue], 110.0, 0.0001, @"1.1e+2 != 110");
    obj = [CCJSONParser objectFromJSON:@"1.1e-2"];
    STAssertEqualsWithAccuracy([obj doubleValue], 0.011, 0.0001, @"1.1e-2 != ,011");
}

@end
