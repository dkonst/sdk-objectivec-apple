//
//  PYEvent+JSON.m
//  PryvApiKit
//
//  Created by Nenad Jelic on 4/6/13.
//  Copyright (c) 2013 Pryv. All rights reserved.
//

#import "PYEvent+JSON.h"
#import "PYAttachment.h"
#import "PYCachingController.h"
#import "PYConnection.h"

@implementation PYEvent (JSON)

+ (id)eventFromDictionary:(NSDictionary *)JSON
{
    PYEvent *event = [[self alloc] init];
    event.eventId = [JSON objectForKey:@"id"];
    id streamId = [JSON objectForKey:@"streamId"];
    if ([streamId isKindOfClass:[NSNull class]]) {
        event.streamId = nil;
    }else{
        event.streamId = streamId;
    }
    
    [event setEventServerTime:[[JSON objectForKey:@"time"] doubleValue]];
    if ([JSON objectForKey:@"duration"] == [NSNull null]) {
        event.duration = 0;
    }else{
        event.duration = [[JSON objectForKey:@"duration"] doubleValue];
    }
    
    id eventType = [JSON objectForKey:@"type"];
    
    if([[eventType class] isSubclassOfClass:[NSDictionary class]])
    {
        NSDictionary *eventTypeDic = (NSDictionary*)eventType;
        event.type = [NSString stringWithFormat:@"%@/%@",[eventTypeDic objectForKey:@"class"],[eventTypeDic objectForKey:@"type"]];
    }
    else
    {
        event.type = eventType;
    }
    
    if ([JSON objectForKey:@"content"] == [NSNull null]) {
        event.eventContent = nil;
    }else{
        event.eventContent = [JSON objectForKey:@"content"];;
    }
    
    
    id tags = [JSON objectForKey:@"tags"];
    if ([tags isKindOfClass:[NSNull class]]) {
        event.tags = nil;
    }else{
        event.tags = tags;
    }
    
    event.eventDescription = [JSON objectForKey:@"description"];
    
    NSDictionary *attachmentsDic = [JSON objectForKey:@"attachments"];
    if (attachmentsDic) {
        NSMutableArray *attachmentObjects = [[NSMutableArray alloc] initWithCapacity:attachmentsDic.count];
        
        [attachmentsDic enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL *stop) {
            [attachmentObjects addObject:[PYAttachment attachmentFromDictionary:obj]];
        }];
        
        event.attachments = attachmentObjects;
        [attachmentObjects release];
    }
    
    event.clientData = [JSON objectForKey:@"clientData"];
    event.trashed = [[JSON objectForKey:@"trashed"] boolValue];
    event.modified = [NSDate dateWithTimeIntervalSince1970:[[JSON objectForKey:@"modified"] doubleValue]];
    
    
    NSNumber *hasTmpId = [JSON objectForKey:@"hasTmpId"];
    if ([hasTmpId isKindOfClass:[NSNull class]]) {
        event.hasTmpId = NO;
    }else{
        event.hasTmpId = [hasTmpId boolValue];
    }
    
    NSNumber *notSyncAdd = [JSON objectForKey:@"notSyncAdd"];
    if ([notSyncAdd isKindOfClass:[NSNull class]]) {
        event.notSyncAdd = NO;
    }else{
        event.notSyncAdd = [notSyncAdd boolValue];
    }
    
    NSNumber *notSyncModify = [JSON objectForKey:@"notSyncModify"];
    if ([notSyncModify isKindOfClass:[NSNull class]]) {
        event.notSyncModify = NO;
    }else{
        event.notSyncModify = [notSyncModify boolValue];
    }
    
    NSNumber *notSyncTrashOrDelete = [JSON objectForKey:@"notSyncTrashOrDelete"];
    if ([notSyncTrashOrDelete isKindOfClass:[NSNull class]]) {
        event.notSyncTrashOrDelete = NO;
    }else{
        event.notSyncTrashOrDelete = [notSyncTrashOrDelete boolValue];
    }
    
    NSDictionary *modifiedProperties = [JSON objectForKey:@"modifiedProperties"];
    if ([modifiedProperties isKindOfClass:[NSNull class]]) {
        event.modifiedEventPropertiesAndValues = nil;
    }else{
        event.modifiedEventPropertiesAndValues = modifiedProperties;
    }
    
    NSNumber *synchedAt = [JSON objectForKey:@"synchedAt"];
    if ([synchedAt isKindOfClass:[NSNull class]]) {
        event.synchedAt = 0;
    }else{
        event.synchedAt = [synchedAt doubleValue];
    }
    
    return [event autorelease];
}

+ (id)eventFromDictionary:(NSDictionary *)JSON onConnection:(PYConnection *)connection;
{
    if (connection == nil) {
        [NSException raise:@"Connection cannot be nil" format:nil];
    }
    
    PYEvent *event = [self eventFromDictionary:JSON];
    event.connection = connection;
    return event;
}

@end
