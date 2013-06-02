//
//  PryvCachingController.m
//  PryvApiKit
//
//  Created by Nenad Jelic on 5/27/13.
//  Copyright (c) 2013 Pryv. All rights reserved.
//

#import "PYCachingController.h"
#import "PYJSONUtility.h"
#import "PYEvent.h"
#import "PYEvent+JSON.h"
#import "PYEventFilter.h"

@interface PYCachingController ()
@property (nonatomic, retain) NSString *localDataPath;
@end

@implementation PYCachingController

@synthesize localDataPath = _localDataPath;

- init
{
    self = [super init];
	if (self) {
		NSError *error = nil;
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
		self.localDataPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"PYCachingController"];
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:_localDataPath])
			[[NSFileManager defaultManager] createDirectoryAtPath:_localDataPath withIntermediateDirectories:NO attributes:nil error:&error];
		
	}
	return self;
}

- (BOOL)isEventDataCachedForKey:(NSString *)key
{
	return key && [[NSFileManager defaultManager] fileExistsAtPath:[self.localDataPath stringByAppendingPathComponent:key]];
}

- (void)cacheEventData:(NSData *)data withKey:(NSString *)key;
{
	if (key)
		[[NSFileManager defaultManager] createFileAtPath:[self.localDataPath stringByAppendingPathComponent:key] contents:data attributes:nil];
}

- (void)cacheNSURLRequest:(NSURLRequest *)req withKey:(NSString *)key
{
    if (key)
        [NSKeyedArchiver archiveRootObject:req toFile:[self.localDataPath stringByAppendingPathComponent:key]];
}

- (NSURLRequest *)getNSURLRequestForKey:(NSString *)key
{
    if (key)
        return [NSKeyedUnarchiver unarchiveObjectWithFile:[self.localDataPath stringByAppendingPathComponent:key]];
    return nil;
}

- (NSData *)getEventDataForKey:(NSString *)key;
{
    if (key)
        return [NSData dataWithContentsOfFile:[self.localDataPath stringByAppendingPathComponent:key]];
    return nil;
}

- (NSArray *)getAllFilesWithPredicateFormat:(NSString *)format
{
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.localDataPath error:nil];
    NSArray *filesWithSelectedPrefix = [files filteredArrayUsingPredicate:
                                        [NSPredicate predicateWithFormat:format]];
    return filesWithSelectedPrefix;

}


- (NSArray *)getEventsFromCacheWithFilter:(PYEventFilter *)eventFilter
{
    return [eventFilter onArray:[self getAllEventsFromCache]];
}


- (NSArray *)getAllEventsFromCache
{
    NSArray *filesWithSelectedPrefix = [self getAllFilesWithPredicateFormat:@"self BEGINSWITH[cd] 'event_'"];
    if (!filesWithSelectedPrefix.count) {
        return nil;
    }
    
    NSMutableArray *arrayOFCachedEvents = [[NSMutableArray alloc] init];
    for (NSString *eventCachedName in filesWithSelectedPrefix) {
        NSDictionary *eventDic = [PYJSONUtility getJSONObjectFromData:[self getEventDataForKey:eventCachedName]];
        [arrayOFCachedEvents addObject:[PYEvent eventFromDictionary:eventDic]];
    }
    
    return arrayOFCachedEvents;
}

- (NSArray *)getAllUnsyncEventsFromCache
{
    NSArray *filesWithSelectedPrefix = [self getAllFilesWithPredicateFormat:@"self BEGINSWITH[cd] 'unsync_event_'"];
    if (!filesWithSelectedPrefix.count) {
        return nil;
    }
    
    NSMutableArray *arrayOFCachedEvents = [[NSMutableArray alloc] init];
    for (NSString *eventCachedName in filesWithSelectedPrefix) {
        NSDictionary *eventDic = [PYJSONUtility getJSONObjectFromData:[self getEventDataForKey:eventCachedName]];
        [arrayOFCachedEvents addObject:[PYEvent eventFromDictionary:eventDic]];
    }
    
    return arrayOFCachedEvents;

}

- (PYEvent *)getEventWithKey:(NSString *)key;
{
    if ([self isEventDataCachedForKey:key]) {
        NSData *eventData = [self getEventDataForKey:key];
        NSDictionary *eventDic = [PYJSONUtility getJSONObjectFromData:eventData];
        return [PYEvent eventFromDictionary:eventDic];
    }
    
    return nil;
}

+ (id)sharedManager {
    static PYCachingController *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

@end