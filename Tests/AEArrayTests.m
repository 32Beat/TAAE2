//
//  Tests.m
//  Tests
//
//  Created by Michael Tyson on 23/03/2016.
//  Copyright © 2016 A Tasty Pixel. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AEArray.h"


@interface AEArrayTests : XCTestCase

@end

@implementation AEArrayTests

- (void)testItemLifecycle {
    AEArray * array = [AEArray new];
    __weak NSArray * weakNSArray;
    
    @autoreleasepool {
        [array updateWithContentsOfArray:@[@(1), @(2), @(3)]];
        weakNSArray = array.allValues;
    }
    
    XCTAssertNotNil(weakNSArray);
    
    AEArrayToken token = AEArrayGetToken(array);
    XCTAssertEqual(AEArrayGetCount(token), 3);
    XCTAssertEqualObjects((__bridge id)AEArrayGetItem(token, 0), @(1));
    XCTAssertEqualObjects((__bridge id)AEArrayGetItem(token, 1), @(2));
    XCTAssertEqualObjects((__bridge id)AEArrayGetItem(token, 2), @(3));
    
    @autoreleasepool {
        [array updateWithContentsOfArray:@[@(4), @(5)]];
    }
    
    AEArrayGetToken(array);
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
    
    XCTAssertNil(weakNSArray);
    
    @autoreleasepool {
        weakNSArray = array.allValues;
    }
    
    token = AEArrayGetToken(array);
    XCTAssertEqual(AEArrayGetCount(token), 2);
    XCTAssertEqualObjects((__bridge id)AEArrayGetItem(token, 0), @(4));
    XCTAssertEqualObjects((__bridge id)AEArrayGetItem(token, 1), @(5));
    
    array = nil;
    
    XCTAssertNil(weakNSArray);
}

struct testStruct {
    int value;
};

- (void)testMapping {
    AEArray * array = [[AEArray alloc] initWithCustomMapping:^void *(id item) {
        struct testStruct * value = calloc(sizeof(struct testStruct), 1);
        value->value = ((NSNumber*)item).intValue;
        return value;
    }];
    
    [array updateWithContentsOfArray:@[@(1), @(2), @(3)]];
    
    AEArrayToken token = AEArrayGetToken(array);
    XCTAssertEqual(AEArrayGetCount(token), 3);
    XCTAssertEqual(((struct testStruct*)AEArrayGetItem(token, 0))->value, 1);
    XCTAssertEqual(((struct testStruct*)AEArrayGetItem(token, 1))->value, 2);
    XCTAssertEqual(((struct testStruct*)AEArrayGetItem(token, 2))->value, 3);
    
    [array updateWithContentsOfArray:@[@(4), @(5)]];
    
    token = AEArrayGetToken(array);
    XCTAssertEqual(AEArrayGetCount(token), 2);
    XCTAssertEqual(((struct testStruct*)AEArrayGetItem(token, 0))->value, 4);
    XCTAssertEqual(((struct testStruct*)AEArrayGetItem(token, 1))->value, 5);
    
    __block BOOL sawRelease = NO;
    array.releaseBlock = ^(id item, void * bytes) {
        if ( [item isEqual:@(4)] ) {
            sawRelease = YES;
        }
        free(bytes);
    };
    
    array = nil;
    
    XCTAssertTrue(sawRelease);
}

@end
