//
//  Channel.h
//  AT PrYv
//
//  Created by Manuel Spuhler on 11/01/2013.
//  Copyright (c) 2013 PrYv. All rights reserved.
//

@class PYFolder;
@class PYEvent;

#import <Foundation/Foundation.h>
#import "PYClient.h"

@interface PYChannel : NSObject
{
    PYAccess *_access;
    NSString *_channelId;
    NSString *_name;
    NSTimeInterval _timeCount;
    NSDictionary *_clientData;
    BOOL _enforceNoEventsOverlap;
    BOOL _trashed;

}

@property (nonatomic, retain) PYAccess *access;
@property (nonatomic, copy, readonly) NSString *channelId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic)       NSTimeInterval timeCount;
@property (nonatomic, copy) NSDictionary *clientData;
@property (nonatomic, getter = isEnforceNoEventsOverlap) BOOL enforceNoEventsOverlap;
@property (nonatomic, getter = isTrashed) BOOL trashed;

//GET /{channel-id}/events
- (void)getAllEventsWithRequestType:(PYRequestType)reqType
                          successHandler:(void (^) (NSArray *eventList))successHandler
                            errorHandler:(void (^)(NSError *error))errorHandler;

//POST /{channel-id}/events
/*Records a new event. Events recorded this way must be completed events, i.e. either period events with a known duration or mark events. To start a running period event, post a events/start request. In addition to the usual JSON, this request accepts standard multipart/form-data content to support the creation of event with attached files in a single request. When sending a multipart request, one content part must hold the JSON for the new event and all other content parts must be the attached files.*/
- (void)createEvent:(PYEvent *)event
        requestType:(PYRequestType)reqType
     successHandler:(void (^) (NSString *newEventId, NSString *stoppedId))successHandler
       errorHandler:(void (^)(NSError *error))errorHandler;

//POST /{channel-id}/events/start
- (void)startPeriodEventInFolderId:(NSString *)folderId;

//POST /{channel-id}/events/stop
- (void)stopPeriodEventWithId:(NSString *)eventId onDate:(NSDate *)specificTime;

//GET /{channel-id}/events/running
- (NSArray *)getRunningPeriodEvents;

//PUT /{channel-id}/events/{event-id}
//- (void)

/**
 @discussion
 Get list of all folders
 
 GET /{channel-id}/folders/
 
 @param successHandler A block object to be executed when the operation finishes successfully. This block has no return value and takes one argument NSArray of PYFolder objects
 @param filterParams - > Query string parameters (parentId, includeHidden, state ...) They are optional. If you don't filter put nil
 
 */
- (void)getFoldersWithRequestType:(PYRequestType)reqType
                     filterParams:(NSDictionary *)filter
                   successHandler:(void (^)(NSArray *folderList))successHandler
                     errorHandler:(void (^)(NSError *error))errorHandler;


/**
 @discussion
 Create a new folder in the current channel Id
 folders have one unique Id AND one unique name. Both must be unique
 POST /{channel-id}/folders/
 
 */
- (void)createFolderWithId:(NSString *)folderId
                      name:(NSString *)folderName
                  parentId:(NSString *)parentId
                  isHidden:(BOOL)hidden
          customClientData:(NSDictionary *)clientData
       withRequestType:(PYRequestType)reqType
        successHandler:(void (^)(NSString *createdFolderId))successHandler
          errorHandler:(void (^)(NSError *error))errorHandler;


/**
 @discussion
 Modify an existing folder Id
 
 PUT /{channel-id}/folders/{id}
 
 */
- (void)modifyFolderWithId:(NSString *)folderId
                      name:(NSString *)newfolderName
                  parentId:(NSString *)newparentId
                  isHidden:(BOOL)hidden
          customClientData:(NSDictionary *)clientData
           withRequestType:(PYRequestType)reqType
            successHandler:(void (^)())successHandler
              errorHandler:(void (^)(NSError *error))errorHandler;

/**
 @discussion
 Trashes or deletes the specified folder, depending on its current state:
 If the folder is not already in the trash, it will be moved to the trash
 If the folder is already in the trash, it will be irreversibly deleted with its possible descendants
 If events exist that refer to the deleted item(s), you must indicate how to handle them with the parameter mergeEventsWithParent
 
 @param filterParams:
        mergeEventsWithParent (true or false): Required if actually deleting the item and if it (or any of its descendants) has linked events, ignored otherwise. If true, the linked events will be assigned to the parent of the deleted item; if false, the linked events will be deleted
 
 DELETE /{channel-id}/folders/{folder-id}
 */

- (void)trashOrDeleteFolderWithId:(NSString *)folderId
                     filterParams:(NSDictionary *)filter
           withRequestType:(PYRequestType)reqType
            successHandler:(void (^)())successHandler
              errorHandler:(void (^)(NSError *error))errorHandler;


@end
