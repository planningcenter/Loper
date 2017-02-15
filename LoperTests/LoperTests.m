//
//  LoperTests.m
//  LoperTests
//
//  Created by Skylar Schipper on 2/9/17.
//  Copyright (c) 2017 Planning Center
//

@import XCTest;
@import Loper;

@interface LoperTests : XCTestCase

@end

@implementation LoperTests

- (void)setUp {
    [[LOPStore defaultStore] openAndReturnError:NULL];
}

+ (void)tearDown {
    [[LOPStore defaultStore] cleanupAndReturnError:NULL];
}

- (void)testSetup {
    NSError *error = nil;
    XCTAssertTrue([[LOPStore defaultStore] openAndReturnError:&error]);
    XCTAssertNil(error);
    XCTAssertTrue([[LOPStore defaultStore] isOpen]);
}

- (void)testSettingString {
    NSError *error = nil;
    XCTAssertTrue([[LOPStore defaultStore] setString:@"Testing" forKey:@"test" inScope:nil error:&error]);
    XCTAssertNil(error);
}

- (void)testSettingStringInScope {
    NSError *error = nil;
    XCTAssertTrue([[LOPStore defaultStore] setString:@"Testing 1" forKey:@"test" inScope:@"another_scope" error:&error]);
    XCTAssertNil(error);

    XCTAssertTrue([[LOPStore defaultStore] setString:@"Testing 2" forKey:@"test" inScope:@"another_scope_2" error:&error]);
    XCTAssertNil(error);
}

- (void)testSettingInt {
    NSError *error = nil;
    XCTAssertTrue([[LOPStore defaultStore] setInteger:1 forKey:@"test_i" inScope:nil error:&error]);
    XCTAssertNil(error);
}

- (void)testSettingDouble {
    NSError *error = nil;
    XCTAssertTrue([[LOPStore defaultStore] setDouble:1.0 forKey:@"test_d" inScope:nil error:&error]);
    XCTAssertNil(error);
}

- (void)testCheckingValue {
    NSString *value = [[NSUUID UUID] UUIDString];
    NSError *error = nil;
    XCTAssertTrue([[LOPStore defaultStore] setString:value forKey:@"check_for_value" inScope:nil error:&error]);
    XCTAssertNil(error);

    XCTAssertTrue([[LOPStore defaultStore] hasValueForKey:@"check_for_value" inScope:nil]);
    XCTAssertFalse([[LOPStore defaultStore] hasValueForKey:@"check_for_value_missing" inScope:nil]);
}

- (void)testReadingString {
    NSString *value = [[NSUUID UUID] UUIDString];
    NSError *error = nil;
    XCTAssertTrue([[LOPStore defaultStore] setString:value forKey:@"test" inScope:@"reading_1" error:&error]);
    XCTAssertNil(error);

    NSString *outValue = [[LOPStore defaultStore] readStringForKey:@"test" inScope:@"reading_1"];

    XCTAssertEqualObjects(value, outValue);
}

- (void)testReadingInt {
    NSError *error = nil;
    XCTAssertTrue([[LOPStore defaultStore] setInteger:43 forKey:@"test_read_i" inScope:nil error:&error]);
    XCTAssertNil(error);

    int64_t value = [[LOPStore defaultStore] readIntegerForKey:@"test_read_i" inScope:nil];
    XCTAssertEqual(value, 43);
}

- (void)testReadingDouble {
    NSError *error = nil;
    XCTAssertTrue([[LOPStore defaultStore] setDouble:89.0 forKey:@"test_read_d" inScope:nil error:&error]);
    XCTAssertNil(error);

    int64_t value = [[LOPStore defaultStore] readDoubleForKey:@"test_read_d" inScope:nil];
    XCTAssertEqual(value, 89.0);
}

- (void)testReadingData {
    NSData *data = [[[NSUUID UUID] UUIDString] dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    XCTAssertTrue([[LOPStore defaultStore] setData:data forKey:@"test_read_dat" inScope:nil error:&error]);
    XCTAssertNil(error);

    NSData *value = [[LOPStore defaultStore] readDataForKey:@"test_read_dat" inScope:nil];
    XCTAssertEqualObjects(data, value);
}

- (void)testQueue {
    dispatch_queue_t queue = dispatch_queue_create("com.testing.queue", DISPATCH_QUEUE_CONCURRENT);
    NSData *data = [@"foo" dataUsingEncoding:NSUTF8StringEncoding];

    for (NSInteger idx = 0; idx < 200; idx++) {
        dispatch_async(queue, ^{
            NSString *key = [NSString stringWithFormat:@"queue_insert_%td",idx];
            [[LOPStore defaultStore] setData:data forKey:key inScope:@"insert_queue" error:NULL];
        });
    }

    dispatch_barrier_sync(queue, ^{});

    NSData *read = [[LOPStore defaultStore] readDataForKey:@"queue_insert_199" inScope:@"insert_queue"];

    XCTAssertEqualObjects(read, data);

    [[LOPStore defaultStore] deleteScope:@"insert_queue" error:NULL];
}

- (void)testCleanup {
    NSString *value = [[NSUUID UUID] UUIDString];
    NSError *error = nil;
    XCTAssertTrue([[LOPStore defaultStore] setString:value forKey:@"cleanup_test" inScope:nil error:&error]);
    XCTAssertNil(error);

    XCTAssertTrue([[LOPStore defaultStore] deleteAllAndReturnError:NULL]);

    XCTAssertFalse([[LOPStore defaultStore] hasValueForKey:@"cleanup_test" inScope:nil]);
}

- (void)testDeleteKeyForScope {
    NSString *value = [[NSUUID UUID] UUIDString];
    [[LOPStore defaultStore] setString:value forKey:@"delete_key" inScope:@"scope_1" error:NULL];
    [[LOPStore defaultStore] setString:value forKey:@"delete_key" inScope:@"scope_2" error:NULL];

    XCTAssertTrue([[LOPStore defaultStore] deleteValueForKey:@"delete_key" inScope:@"scope_1" error:NULL]);

    XCTAssertTrue([[LOPStore defaultStore] hasValueForKey:@"delete_key" inScope:@"scope_2"]);
    XCTAssertFalse([[LOPStore defaultStore] hasValueForKey:@"delete_key" inScope:@"scope_1"]);
}

- (void)testWritingHelpers {
    [[LOPStore defaultStore] setObject:@"testing" forKey:@"value_setting" inScope:nil];
    XCTAssertTrue([[LOPStore defaultStore] hasValueForKey:@"value_setting" inScope:nil]);
}

- (void)testWritingCodingObjects {
    [[LOPStore defaultStore] setObject:@{@"foo": @"bar"} forKey:@"test_encoded_object" inScope:nil];
    NSDictionary *output = [[LOPStore defaultStore] encodedObjectForKey:@"test_encoded_object" inScope:nil];
    XCTAssertTrue([output isKindOfClass:[NSDictionary class]]);
    XCTAssertEqualObjects(output, @{@"foo": @"bar"});
}

- (void)testHardDeleteOfDB {
    NSError *error = nil;
    XCTAssertTrue([[LOPStore defaultStore] setString:@"Hard Reset" forKey:@"hard_reset" inScope:@"reset_scope" error:&error]);
    XCTAssertNil(error);

    XCTAssertTrue([[LOPStore defaultStore] hardResetAndReturnError:&error]);
    XCTAssertNil(error);

    XCTAssertNil([[LOPStore defaultStore] stringForKey:@"hard_reset" inScope:@"reset_scope"]);

    // Sanity check for writable
    XCTAssertTrue([[LOPStore defaultStore] setString:@"Hard Reset" forKey:@"hard_reset" inScope:@"reset_scope" error:&error]);
    XCTAssertNil(error);
}

@end
