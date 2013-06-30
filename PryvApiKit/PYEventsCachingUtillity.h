//
//  PYEventsCachingUtillity.h
//  PryvApiKit
//
//  Created by Nenad Jelic on 5/27/13.
//  Copyright (c) 2013 Pryv. All rights reserved.
//

@class PYEvent;
#import <Foundation/Foundation.h>

@interface PYEventsCachingUtillity : NSObject

/**
 Cache PYEvent object on disk
 */
+ (void)cacheEvent:(PYEvent *)event;
/**
 Remove PYEvent object from disk
 */
+ (void)removeEvent:(PYEvent *)event;
/**
 Cache event json objects on disk
 */
+ (void)cacheEvents:(NSArray *)events;
/**
 Get all PYEvent objects from disk
 */
+ (NSArray *)getEventsFromCache;
/**
 Get PYEvent object from disk with key(eventId)
 */
+ (PYEvent *)getEventFromCacheWithEventId:(NSString *)eventId;

/**
 Utility method - Get key for event
 */
+ (NSString *)getKeyForEvent:(PYEvent *)event;

@end
