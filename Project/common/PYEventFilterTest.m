//
//  PYEventFilterTest.m
//  PryvApiKit
//
//  Created by Perki on 13.12.13.
//  Copyright (c) 2013 Pryv. All rights reserved.
//

#import "PYBaseConnectionTests.h"

#import "PYEventFilter.h"
#import "PYTestsUtils.h"

@interface PYEventFilterTest : PYBaseConnectionTests
@end

@implementation PYEventFilterTest


- (void)setUp
{
    [super setUp];
    
}

// FIXME this test should create the events necessary for the filter
- (void)testEventFilter
{
    STAssertNotNil(self.connection, @"Connection isn't created");
    
    PYEventFilter* pyFilter = [[PYEventFilter alloc] initWithConnection:self.connection
                                                               fromTime:PYEventFilter_UNDEFINED_FROMTIME
                                                                 toTime:PYEventFilter_UNDEFINED_TOTIME
                                                                  limit:20
                                                         onlyStreamsIDs:nil
                                                                   tags:nil];
    STAssertNotNil(pyFilter, @"PYEventFilter isn't created");
    
    
    __block BOOL finished1 = NO;
    __block BOOL finished2 = NO;
    [[NSNotificationCenter defaultCenter] addObserverForName:kPYNotificationEvents
                                                      object:pyFilter
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note)
     {
         NSDictionary *message = (NSDictionary*) note.userInfo;
         NSArray* toAdd = [message objectForKey:kPYNotificationKeyAdd];
         
         NSLog(@"*162 ADD %@", @(toAdd.count));
         
         if (! finished1) {
             STAssertEquals((NSUInteger)20, toAdd.count, @"Got wrong number of events");
             pyFilter.limit = 30;
             finished1 = YES;
             [pyFilter update];
         } else {
             STAssertEquals((NSUInteger)10, (NSUInteger)toAdd.count, @"Got wrong number of events");
         }
         
         NSArray* toRemove = [message objectForKey:kPYNotificationKeyDelete];
         if (toRemove) {
             NSLog(@"*162 REMOVE %@", @(toRemove.count));
         }
         NSArray* modify = [message objectForKey:kPYNotificationKeyModify];
         if (modify) {
             NSLog(@"*162 MODIFY %@", @(modify.count));
         }
         
         if (finished1) {
             finished2 = YES;
         }
         finished1 = YES;
         
         NSLog(@"*162");
         
     }];
    [pyFilter update];
    

    [PYTestsUtils execute:^{
        STFail(@"Failed after waiting 10 seconds");
    } ifNotTrue:&finished2 afterSeconds:10];
    
    
}

- (void) testSort
{
    
    PYEvent *event1 = [[PYEvent alloc] init];
    event1.streamId = @"1"; [event1 setEventServerTime:10];
    PYEvent *event2 = [[PYEvent alloc] init];
    event2.streamId = @"2"; [event2 setEventServerTime:20];
    PYEvent *event3 = [[PYEvent alloc] init];
    event3.streamId = @"3"; [event3 setEventServerTime:30];
    
    NSMutableArray* events = [[NSMutableArray alloc] initWithObjects:event2,event1,event3,nil];
    
    [PYEventFilter sortNSMutableArrayOfPYEvents:events sortAscending:NO];
    STAssertEquals(30.0,[(PYEvent*)[events objectAtIndex:0] getEventServerTime],@"wrong postion of event");
    STAssertEquals(20.0,[(PYEvent*)[events objectAtIndex:1] getEventServerTime],@"wrong postion of event");
    STAssertEquals(10.0,[(PYEvent*)[events objectAtIndex:2] getEventServerTime],@"wrong postion of event");
    
    
    [PYEventFilter sortNSMutableArrayOfPYEvents:events sortAscending:YES];
    STAssertEquals(10.0,[(PYEvent*)[events objectAtIndex:0] getEventServerTime],@"wrong postion of event");
    STAssertEquals(20.0,[(PYEvent*)[events objectAtIndex:1] getEventServerTime],@"wrong postion of event");
    STAssertEquals(30.0,[(PYEvent*)[events objectAtIndex:2] getEventServerTime],@"wrong postion of event");

    
}

@end
