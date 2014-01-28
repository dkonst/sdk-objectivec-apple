//
//  PYConnection+DataManagement.m
//  PryvApiKit
//
//  Created by Victor Kristof on 14.08.13.
//  Copyright (c) 2013 Pryv. All rights reserved.
//

#import "PYConnection+DataManagement.h"
#import "PYStream+JSON.h"
#import "PYEventFilterUtility.h"
#import "PYConstants.h"
#import "PYEvent.h"
#import "PYAttachment.h"
#import "PYCachingController+Event.h"
#import "PYCachingController+Stream.h"
#import "PYAsyncService.h"

@implementation PYConnection (DataManagement)

#pragma mark - Pryv API Streams

- (void)getAllStreamsWithRequestType:(PYRequestType)reqType
                    gotCachedStreams:(void (^) (NSArray *cachedStreamsList))cachedStreams
                    gotOnlineStreams:(void (^) (NSArray *onlineStreamList))onlineStreams
                        errorHandler:(void (^)(NSError *error))errorHandler
{
    //Return current cached streams
    NSArray *allStreamsFromCache = [self.cache getStreamsFromCache];
    //    [allStreamsFromCache makeObjectsPerformSelector:@selector(setAccess:) withObject:self.access];
    if (cachedStreams) {
        NSUInteger currentNumberOfStreamsInCache = allStreamsFromCache.count;
        if (currentNumberOfStreamsInCache > 0) {
            //if there are cached streams return it, when get response return in onlineList
            cachedStreams(allStreamsFromCache);
        }
    }
    
    [self getOnlineStreamsWithRequestType:reqType filterParams:nil successHandler:^(NSArray *streamsList) {
        if (onlineStreams) {
            onlineStreams(streamsList);
        }
    }
                       errorHandler:errorHandler
                 shouldSyncAndCache:YES];
}


- (void)getOnlineStreamsWithRequestType:(PYRequestType)reqType
                     filterParams:(NSDictionary *)filter
                   successHandler:(void (^) (NSArray *streamsList))onlineStreamsList
                     errorHandler:(void (^) (NSError *error))errorHandler
               shouldSyncAndCache:(BOOL)syncAndCache
{
    /*
     This method musn't be called directly (it's api support method). This method works ONLY in ONLINE mode
     This method doesn't care about current cache, it's interested in online streams only
     It should retrieve always online streams and need to cache (sync) online streams (before caching sync unsyched stream, because we don't want to lose unsync changes)
     */
    
    /*if there are streams that are not synched with server, they need to be synched first and after that cached
     This method must be SYNC not ASYNC and this method sync streams with server and cache them
     */
    if (syncAndCache == YES) {
        [self syncNotSynchedStreamsIfAny];
    }
    
    [self apiRequest:[PYClient getURLPath:kROUTE_STREAMS withParams:filter]
         requestType:reqType
              method:PYRequestMethodGET
            postData:nil
         attachments:nil
             success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                 NSMutableArray *streamList = [[NSMutableArray alloc] init];
                 for (NSDictionary *streamDictionary in JSON) {
                     [streamList addObject:[PYStream streamFromJSON:streamDictionary]];
                 }
                 
                 if (syncAndCache == YES) {
                     [self.cache cacheStreams:JSON];
                 }
                 
                 if (onlineStreamsList) {
                     //cacheEvents method will overwrite contents of currently cached file
                     onlineStreamsList([streamList autorelease]);
                 }
                 
             } failure:^(NSError *error) {
                 if (errorHandler) {
                     errorHandler (error);
                 }
             }];
}


- (void)getOnlineStreamsWithRequestType:(PYRequestType)reqType
                           filter:(NSDictionary*)filterDic
                   successHandler:(void (^) (NSArray *streamsList))onlineStreamList
                     errorHandler:(void (^)(NSError *error))errorHandler
{
    //This method should retrieve always online streams and need to cache (sync) online streams
    
    [self apiRequest:[PYClient getURLPath:kROUTE_STREAMS withParams:filterDic]
         requestType:reqType
              method:PYRequestMethodGET
            postData:nil
         attachments:nil
             success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                 
                 NSMutableArray *streamList = [[NSMutableArray alloc] init];
                 for(NSDictionary *streamDictionary in JSON){
                     PYStream *streamObject = [PYStream streamFromJSON:streamDictionary];
                     streamObject.connection = self;
                     [streamList addObject:streamObject];
                 }
                 if(onlineStreamList){
                     [self.cache cacheStreams:JSON];
                     onlineStreamList([streamList autorelease]);
                 }
             } failure:^(NSError *error){
                 if(errorHandler){
                     errorHandler(error);
                 }
             }
     ];
    
}

- (void)createStream:(PYStream *)stream
     withRequestType:(PYRequestType)reqType
      successHandler:(void (^)(NSString *createdStreamId))successHandler
        errorHandler:(void (^)(NSError *error))errorHandler;
{
    [self apiRequest:kROUTE_STREAMS
         requestType:reqType
              method:PYRequestMethodPOST
            postData:[stream dictionary]
         attachments:nil
             success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                 NSString *createdStreamId = [JSON objectForKey:@"id"];
                 if (successHandler) {
                     successHandler(createdStreamId);
                 }
                 [self.cache getAndCacheStream:stream
                                                withServerId:createdStreamId
                                                 requestType:reqType];
             } failure:^(NSError *error) {
                 if (error.code == kCFURLErrorNotConnectedToInternet || error.code == kCFURLErrorNetworkConnectionLost) {
                     if (stream.isSyncTriedNow == NO) {
                         //If we didn't try to sync stream from unsync list that means that we have to cache that stream, otherwise leave it as is
                         //stream.Id = self.Id; SHOULD NOT BE COMMENTED, should use parentId ?
                         stream.notSyncAdd = YES;
                         //When we try to create stream and we came here it has tmpId
                         stream.hasTmpId = YES;
                         //this is random id
                         stream.streamId = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
                         //return that created id so it can work offline. Stream will be cached when added to unsync list
                         
                         [self.cache cacheStream:stream];
                         [self addStream:stream toUnsyncList:error];
                         
                         successHandler (stream.streamId);
                         
                     }else{
                         NSLog(@"Stream wants to be synchronized on server from unsync list but there is no internet");
                     }
                     
                 }else{
                     if (errorHandler) {
                         errorHandler (error);
                     }
                 }
             }];
}

-(void)trashOrDeleteStream:(PYStream *)stream
              filterParams:(NSDictionary *)filter
           withRequestType:(PYRequestType)reqType
            successHandler:(void (^)())successHandler
              errorHandler:(void (^)(NSError *))errorHandler
{
    [self apiRequest:[PYClient getURLPath:[NSString stringWithFormat:@"%@/%@",kROUTE_STREAMS, stream.streamId] withParams:filter]
         requestType:reqType
              method:PYRequestMethodDELETE
            postData:nil
         attachments:nil
             success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                 if (successHandler) {
                     successHandler();
                 }
             } failure:^(NSError *error) {
                 if (errorHandler) {
                     errorHandler (error);
                 }
             }];
}

//- (void)trashOrDeleteStream:(PYStream *)stream
//               filterParams:(NSDictionary *)filter
//           withRequestType:(PYRequestType)reqType
//            successHandler:(void (^)())successHandler
//              errorHandler:(void (^)(NSError *error))errorHandler
//{
//    [self apiRequest:[PYClient getURLPath:[NSString stringWithFormat:@"%@/%@",kROUTE_STREAMS, stream.streamId] withParams:filter]
//         requestType:reqType
//              method:PYRequestMethodDELETE
//            postData:nil
//         attachments:nil
//             success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
//                 NSLog(@"It's stream with server id because we'll never try to call this method if stream has tempId");
//                 if (successHandler) {
//                     successHandler();
//                 }
//             } failure:^(NSError *error) {
//                 if (error.code == kCFURLErrorNotConnectedToInternet || error.code == kCFURLErrorNetworkConnectionLost) {
//                     if (stream.isSyncTriedNow == NO) {
//
//                         //stream.notSyncTrashOrDelete = YES;
//
//                         if (stream.trashed == NO) {
//                             stream.trashed = YES;
//                             [self.cache cacheStream:stream];
//                         }else{
//                             //if event has trashed = yes flag it needs to be deleted from cache
//                             NSLog(@"Stream removed from cache.");
//                             [self.cache removeStream:stream];
//                             [self.streamsNotSync removeObject:stream];
//                         }
//
//
//                     }else{
//                         NSLog(@"Event with server id wants to be synchronized on server from unsync list but there is no internet");
//                     }
//
//                 }else{
//                     if (errorHandler) {
//                         errorHandler (error);
//                     }
//                 }
//             }];
//}


- (void)setModifiedStreamAttributesObject:(PYStream *)stream
                              forStreamId:(NSString *)streamId
                              requestType:(PYRequestType)reqType
                           successHandler:(void (^)())successHandler
                             errorHandler:(void (^)(NSError *error))errorHandler
{
    [self apiRequest:[NSString stringWithFormat:@"%@/%@",kROUTE_STREAMS,streamId]
         requestType:reqType
              method:PYRequestMethodPUT
            postData:[stream dictionary]
         attachments:nil
             success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                 
                 //Cache modified stream - We cache stream
                 NSLog(@"It's stream with server id because we'll never try to call this method if stream has tempId");
                 //If streamId isn't temporary cache stream (it will be overwritten in cache)
                 [self.cache getAndCacheStream:stream withServerId:streamId requestType:reqType];
                 
                 if (successHandler) {
                     successHandler();
                 }
                 
             } failure:^(NSError *error) {
                 
                 if (error.code == kCFURLErrorNotConnectedToInternet || error.code == kCFURLErrorNetworkConnectionLost) {
                     
                     if (stream.isSyncTriedNow == NO) {
                         
                         //Get current stream with id from cache
                         PYStream *currentStreamFromCache = [self.cache getStreamFromCacheWithStreamId:streamId];
                         
                         currentStreamFromCache.notSyncModify = YES;
                         
                         NSDictionary *modifiedPropertiesDic = [stream dictionary];
                         [modifiedPropertiesDic enumerateKeysAndObjectsUsingBlock:^(NSString *property, id value, BOOL *stop) {
                             [currentStreamFromCache setValue:value forKey:property];
                         }];
                         
                         //We have to know what properties are modified in order to make succesfull request
                         currentStreamFromCache.modifiedStreamPropertiesAndValues = [stream dictionary];
                         //We must have cached modified properties of stream in cache
                         [self.cache cacheStream:currentStreamFromCache];
                         
                         if (successHandler) {
                             successHandler();
                         }
                         
                     }else{
                         NSLog(@"Stream with server id wants to be synchronized on server from unsync list but there is no internet");
                     }
                 }else{
                     if (errorHandler) {
                         errorHandler (error);
                     }
                 }
                 
             }];
}

- (void)getOnlineStreamWithId:(NSString *)streamId
                  requestType:(PYRequestType)reqType
               successHandler:(void (^) (PYStream *stream))onlineStream
                 errorHandler:(void (^) (NSError *error))errorHandler
{
    //Method below automatically cache (overwrite) all streams, so this is bad
    //When API support separate method of getting only one stream by its id this will be implemneted here
    
    //This method should get particular stream and return it, not to cache it
    [self getOnlineStreamsWithRequestType:reqType filter:nil successHandler:^(NSArray *streamsList) {
        for (PYStream *currentStream in streamsList) {
            if ([currentStream.streamId compare:streamId] == NSOrderedSame) {
                onlineStream(currentStream);
                break;
            }
        }
    } errorHandler:errorHandler];
}

#pragma mark - Pryv API Events

- (void)getOnlineEventWithId:(NSString *)eventId
                 requestType:(PYRequestType)reqType
              successHandler:(void (^) (PYEvent *event))onlineEvent
                errorHandler:(void (^) (NSError *error))errorHandler
{
    //Method below automatically cache (overwrite) all events, so this is bad
    //When API support separate method of getting only one event by its id this will be implemneted here
    
    //This method should get particular event and return it, not to cache it
    
    [self getOnlineEventsWithRequestType:reqType
                              parameters:nil
                          successHandler:^(NSArray *eventList, NSNumber *serverTime) {
                              for (PYEvent *currentEvent in eventList) {
                                  if ([currentEvent.eventId compare:eventId] == NSOrderedSame) {
                                      onlineEvent(currentEvent);
                                      break;
                                  }
                              }
                          }
                            errorHandler:errorHandler
                      shouldSyncAndCache:NO];
}

//GET /events

- (void)getOnlineEventsWithRequestType:(PYRequestType)reqType
                            parameters:(NSDictionary*)filterDic
                        successHandler:(void (^) (NSArray *eventList, NSNumber *serverTime))onlineEventsList
                          errorHandler:(void (^) (NSError *error))errorHandler
                    shouldSyncAndCache:(BOOL)syncAndCache
{
    /*
     This method musn't be called directly (it's api support method). This method works ONLY in ONLINE mode
     This method doesn't care about current cache, it's interested in online events only
     It should retrieve always online events and need to cache (sync) online events (before caching sync unsyched, because we don't want to loose unsuc changes)
     */
    
    /*if there are events that are not synched with server, they need to be synched first and after that cached
     This method must be SYNC not ASYNC and this method sync events with server and cache them
     */
    if (syncAndCache == YES) {
        [self syncNotSynchedEventsIfAny];
    }
    [self apiRequest:[PYClient getURLPath:kROUTE_EVENTS withParams:filterDic]
         requestType:reqType
              method:PYRequestMethodGET
            postData:nil
         attachments:nil
             success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                 NSMutableArray *eventsArray = [[NSMutableArray alloc] init];
                 NSMutableArray *eventsCachingArray = [[NSMutableArray alloc] init];
                 [eventsCachingArray addObjectsFromArray:JSON];
                 
                 for (int i = 0; i < [JSON count]; i++) {
                     
                     NSDictionary *eventDic = [JSON objectAtIndex:i];
                     
                     PYEvent *event = [PYEvent getEventFromDictionary:eventDic onConnection:self];
                     
                     [eventsArray addObject:event];
                     
                     if (event.attachments.count > 0) {
                         for (int j = 0; j < event.attachments.count; j++) {
                             PYAttachment *attachment = [event.attachments objectAtIndex:j];
                             NSString *fileName = attachment.fileName;
                             [self getAttachmentDataForFileName:fileName
                                                        eventId:event.eventId
                                                    requestType:PYRequestTypeAsync
                                                 successHandler:^(NSData *filedata) {
                                                     
                                                     attachment.fileData = filedata;
                                                     [eventsCachingArray replaceObjectAtIndex:i withObject:[event cachingDictionary]];
                                                     
                                                 } errorHandler:errorHandler];
                         }
                     }
                 }
                 
                 if (syncAndCache == YES) {
                     [self.cache cacheEvents:eventsCachingArray];
                 }
                 if (onlineEventsList) {
                     //cacheEvents method will overwrite contents of currently cached file
                     [PYEventFilter sortNSMutableArrayOfPYEvents:eventsArray sortAscending:YES];
                     NSNumber* serverTime = [[response allHeaderFields] objectForKey:@"Server-Time"];
                     onlineEventsList([eventsArray autorelease], serverTime);
                 }
                 
             } failure:^(NSError *error) {
                 if (errorHandler) {
                     errorHandler (error);
                 }
             }];
}


- (void)getEventsWithRequestType:(PYRequestType)reqType
                      filter:(PYEventFilter *)filter
                 gotCachedEvents:(void (^) (NSArray *cachedEventList))cachedEvents
                 gotOnlineEvents:(void (^) (NSArray *onlineEventList, NSNumber *serverTime))onlineEvents
                  onlineDiffWithCached:(void (^) (NSArray *eventsToAdd, NSArray *eventsToRemove, NSArray *eventModified))syncDetails
                    errorHandler:(void (^)(NSError *error))errorHandler
{
    //Return current cached events and eventsToAdd, modyfiy, remove (for visual details)
    
    NSArray* filteredCachedEventList = [PYEventFilterUtility
                                        filterEventsList:[self.cache getEventsFromCache]
                                                                   withFilter:filter];
    
    if (cachedEvents) {
        if ([self.cache getEventsFromCache].count > 0) {
            //if there are cached events return it, when get response return in onlineList
            cachedEvents(filteredCachedEventList);
        }
    }
    //This method should retrieve always online events
    //In this method we should synchronize events from cache with ones online and to return current online list
    [self getOnlineEventsWithRequestType:reqType
                              parameters:[PYEventFilterUtility apiParametersForEventsRequestFromFilter:filter]
                          successHandler:^(NSArray *onlineEventList, NSNumber *serverTime) {
                              if (onlineEvents) {
                                  onlineEvents(onlineEventList, serverTime);
                              }
                              if (syncDetails) {
                                  // give differences between cachedEvents and received events
                                  
                                  NSMutableArray *eventsToAdd = [[[NSMutableArray alloc] init] autorelease];
                                  NSMutableArray *eventsToRemove = [[[NSMutableArray alloc] init] autorelease];
                                  NSMutableArray *eventsModified = [[[NSMutableArray alloc] init] autorelease];
                                  
                                  [PYEventFilterUtility createEventsSyncDetails:onlineEventList
                                                                    knownEvents:filteredCachedEventList
                                                                    eventsToAdd:eventsToAdd
                                                                 eventsToRemove:eventsToRemove
                                                                 eventsModified:eventsModified];
                                  
                                  
                                  
                                  syncDetails(eventsToAdd, eventsToRemove, eventsModified);
                              }
                          }
                            errorHandler:errorHandler
                      shouldSyncAndCache:YES];
}

//POST /events
- (void)createEvent:(PYEvent *)event
        requestType:(PYRequestType)reqType
     successHandler:(void (^) (NSString *newEventId, NSString *stoppedId))successHandler
       errorHandler:(void (^)(NSError *error))errorHandler
{
    
    if (event.connection != nil) {
        return errorHandler([NSError errorWithDomain:@"Cann create PYEvet with a known connection" code:500 userInfo:nil]);
    }
    
    event.connection = self;
    
    //    event.timeIntervalWhenCreationTried = [[NSDate date] timeIntervalSince1970];
    [self apiRequest:kROUTE_EVENTS
         requestType:reqType
              method:PYRequestMethodPOST
            postData:[event dictionary]
         attachments:event.attachments
             success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                 
                 NSString *createdEventId = [JSON objectForKey:@"id"];
                 NSString *stoppedId = [JSON objectForKey:@"stoppedId"];
                 
                 //The following method only cached the event with id gotten from server. Let's try
                 //to cache it directly here and see what happens.
                 //Cache particular event in cache
                 //                 [self.cache getAndCacheEventWithServerId:createdEventId
                 //                                                       usingConnection:self
                 //                                                           requestType:reqType];
                 //Fix maybe ?
                 event.eventId = [createdEventId copy];
                 [self.cache cacheEvent:event];
                 
                 if (successHandler) {
                     successHandler(createdEventId, stoppedId);
                 }
                 
             } failure:^(NSError *error) {
                 if (error.code == kCFURLErrorNotConnectedToInternet || error.code == kCFURLErrorNetworkConnectionLost) {
                     
                     if (event.isSyncTriedNow == NO) {
                         //If we didn't try to sync event from unsync list that means that we have to cache that event, otherwise leave it as is
                         event.notSyncAdd = YES;
                         event.time = [[NSDate date] timeIntervalSince1970];
                         event.modified = [NSDate date];
                         //When we try to create event and we came here it have tmpId
                         event.hasTmpId = YES;
                         //this is random id
                         event.eventId = [event.clientId copy];
                         //return that created id so it can work offline. Event will be cached when added to unsync list
                         if (event.attachments.count > 0) {
                             for (PYAttachment *attachment in event.attachments) {
                                 //                                     attachment.mimeType = @"mimeType";
                                 attachment.size = [NSNumber numberWithInt:attachment.fileData.length];
                             }
                         }
                         [self.cache cacheEvent:event];
                         [self addEvent:event toUnsyncList:error];
                         
                         successHandler (event.eventId, @"");
                         
                     }else{
                         NSLog(@"Event wants to be synchronized on server from unsync list but there is no internet");
                     }
                     
                     
                 }else{
                     if (errorHandler) {
                         errorHandler (error);
                     }
                 }
                 
             }];
}

- (void)trashOrDeleteEvent:(PYEvent *)event
           withRequestType:(PYRequestType)reqType
            successHandler:(void (^)())successHandler
              errorHandler:(void (^)(NSError *error))errorHandler
{
    [self apiRequest:[NSString stringWithFormat:@"%@/%@",kROUTE_EVENTS, event.eventId]
         requestType:reqType
              method:PYRequestMethodDELETE
            postData:nil
         attachments:nil
             success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                 
                 NSLog(@"It's event with server id because we'll never try to call this method if event has tempId");
                 if (successHandler) {
                     successHandler();
                 }
             } failure:^(NSError *error) {
                 
                 if (error.code == kCFURLErrorNotConnectedToInternet || error.code == kCFURLErrorNetworkConnectionLost) {
                     if (event.isSyncTriedNow == NO) {
                         
                         event.notSyncTrashOrDelete = YES;
                         event.modified = [NSDate date];
                         
                         if (event.trashed == NO) {
                             event.trashed = YES;
                             [self.cache cacheEvent:event];
                         }else{
                             //if event has trashed = yes flag it needs to be deleted from cache
                             [self.cache removeEvent:event];
                             [self.eventsNotSync removeObject:event];
                         }
                         
                         
                     }else{
                         NSLog(@"Event with server id wants to be synchronized on server from unsync list but there is no internet");
                     }
                     
                 }else{
                     if (errorHandler) {
                         errorHandler (error);
                     }
                 }
             }];
}

//PUT /events/{event-id}
- (void)setModifiedEventAttributesObject:(PYEvent *)eventObject
                              forEventId:(NSString *)eventId
                             requestType:(PYRequestType)reqType
                          successHandler:(void (^)(NSString *stoppedId))successHandler
                            errorHandler:(void (^)(NSError *error))errorHandler
{
    
    [self apiRequest:[NSString stringWithFormat:@"%@/%@",kROUTE_EVENTS,eventId]
         requestType:reqType
              method:PYRequestMethodPUT
            postData:[eventObject dictionary]
         attachments:eventObject.attachments
             success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                 
                 NSString *stoppedId = [JSON objectForKey:@"stoppedId"];
                 
                 //Cache modified event - We cache event
                 NSLog(@"It's event with server id because we'll never try to call this method if event has tempId");
                 //If eventId isn't temporary cache event (it will be overwritten in cache)
                 [self.cache getAndCacheEventWithServerId:eventId
                                                       usingConnection:self
                                                           requestType:reqType];
                 
                 if (successHandler) {
                     NSString *stoppedIdToReturn;
                     if (stoppedId.length > 0) {
                         stoppedIdToReturn = stoppedId;
                     }else{
                         stoppedIdToReturn = @"";
                     }
                     successHandler(stoppedIdToReturn);
                 }
                 
             } failure:^(NSError *error) {
                 
                 if (error.code == kCFURLErrorNotConnectedToInternet || error.code == kCFURLErrorNetworkConnectionLost) {
                     
                     if (eventObject.isSyncTriedNow == NO) {
                         
                         //Get current event with id from cache
                         PYEvent *currentEventFromCache = [self.cache getEventFromCacheWithEventId:eventId];
                         
                         NSLog(@"It's event with server id because we'll never try to call this method if event has tempId");
                         currentEventFromCache.notSyncModify = YES;
                         currentEventFromCache.modified = [NSDate date];
                         
                         NSDictionary *modifiedPropertiesDic = [eventObject dictionary];
                         [modifiedPropertiesDic enumerateKeysAndObjectsUsingBlock:^(NSString *property, id value, BOOL *stop) {
                             [currentEventFromCache setValue:value forKey:property];
                         }];
                         
                         //We have to know what properties are modified in order to make succesfull request
                         currentEventFromCache.modifiedEventPropertiesAndValues = [eventObject dictionary];
                         //We must have cached modified properties of event in cache
                         [self.cache cacheEvent:currentEventFromCache];
                         
                         if (successHandler) {
                             NSString *stoppedIdToReturn = @"";
                             successHandler(stoppedIdToReturn);
                         }
                         
                     }else{
                         NSLog(@"Event with server id wants to be synchronized on server from unsync list but there is no internet");
                     }
                 }else{
                     if (errorHandler) {
                         errorHandler (error);
                     }
                 }
                 
             }];
}

//POST /events/start
- (void)startPeriodEvent:(PYEvent *)event
             requestType:(PYRequestType)reqType
          successHandler:(void (^)(NSString *startedEventId))successHandler
            errorHandler:(void (^)(NSError *error))errorHandler
{
    [self apiRequest:[NSString stringWithFormat:@"%@/%@",kROUTE_EVENTS,@"start"]
         requestType:reqType
              method:PYRequestMethodPOST
            postData:[event dictionary]
         attachments:event.attachments
             success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                 
                 NSString *startedEventId = [JSON objectForKey:@"id"];
                 
                 if (successHandler) {
                     successHandler(startedEventId);
                 }
                 
             } failure:^(NSError *error) {
                 if (errorHandler) {
                     errorHandler (error);
                 }
             }];
    
}

//POST /events/stop
- (void)stopPeriodEventWithId:(NSString *)eventId
                       onDate:(NSDate *)specificTime
                  requestType:(PYRequestType)reqType
               successHandler:(void (^)(NSString *stoppedEventId))successHandler
                 errorHandler:(void (^)(NSError *error))errorHandler
{
    
    NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
    
    [postData setObject:eventId forKey:@"id"];
    if (specificTime) {
        NSTimeInterval timeInterval = [specificTime timeIntervalSince1970];
        [postData setObject:[NSNumber numberWithDouble:timeInterval] forKey:@"time"];
        
    }
    
    [self apiRequest:[NSString stringWithFormat:@"%@/%@",kROUTE_EVENTS,@"stop"]
         requestType:reqType
              method:PYRequestMethodPOST
            postData:[postData autorelease]
         attachments:nil
             success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                 
                 NSString *stoppedEventId = [JSON objectForKey:@"stoppedId"];
                 
                 if (successHandler) {
                     successHandler(stoppedEventId);
                 }
                 
             } failure:^(NSError *error) {
                 if (errorHandler) {
                     errorHandler (error);
                 }
             }];
    
}

//GET /events/running
- (void)getRunningPeriodEventsWithRequestType:(PYRequestType)reqType
                                   parameters:(NSDictionary *)filter
                               successHandler:(void (^)(NSArray *arrayOfEvents))successHandler
                                 errorHandler:(void (^)(NSError *error))errorHandler

{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:filter];
    [parameters setValue:@"true" forKey:@"running"];
    [self apiRequest:[PYClient getURLPath:kROUTE_EVENTS withParams:parameters]
         requestType:reqType
              method:PYRequestMethodGET
            postData:nil
         attachments:nil
             success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                 
                 NSMutableArray *eventsArray = [[NSMutableArray alloc] init];
                 for (NSDictionary *eventDic in JSON) {
                     [eventsArray addObject:[PYEvent getEventFromDictionary:eventDic onConnection:self]];
                 }
                 if (successHandler) {
                     successHandler([eventsArray autorelease]);
                 }
                 
             } failure:^(NSError *error) {
                 if (errorHandler) {
                     errorHandler (error);
                 }
             }
     ];
    
}

- (void)getAttachmentDataForFileName:(NSString *)fileName
                             eventId:(NSString *)eventId
                         requestType:(PYRequestType)reqType
                      successHandler:(void (^) (NSData * filedata))success
                        errorHandler:(void (^) (NSError *error))errorHandler
{
    
    NSString *path = [NSString stringWithFormat:@"%@/%@/%@",kROUTE_EVENTS, eventId, fileName];
    NSString *urlPath = [path stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];

    
    
    NSString* fullPath = [NSString stringWithFormat:@"%@://%@%@:%i/%@", self.apiScheme, self.userID, self.apiDomain, self.apiPort, urlPath];
    
    NSURL *url = [NSURL URLWithString:fullPath];

    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
    [request setValue:self.accessToken forHTTPHeaderField:@"Authorization"];
    [request setURL:url];
    [request setHTTPMethod:@"GET"];
    request.timeoutInterval = 60.0f;
    
    [PYAsyncService RAWRequestServiceWithRequest:request success:^(NSURLRequest *req, NSHTTPURLResponse *resp, id result) {
        if (success) {
            NSLog(@"*66 %i %@", [result length], url);
            success(result);
        }
    } failure:^(NSURLRequest *req, NSHTTPURLResponse *resp, NSError *error, id JSON) {
        errorHandler(error);
        
    }];

    
}

@end
