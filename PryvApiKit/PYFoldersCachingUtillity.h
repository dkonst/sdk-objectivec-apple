//
//  PYFoldersCachingUtillity.h
//  PryvApiKit
//
//  Created by Nenad Jelic on 6/12/13.
//  Copyright (c) 2013 Pryv. All rights reserved.
//

@class PYFolder;
@class PYChannel;
#import <Foundation/Foundation.h>
#import "PYClient.h"

@interface PYFoldersCachingUtillity : NSObject

/**
 Cache folder json objects on disk
 */
+ (void)cacheFolders:(NSArray *)folders;
/**
 Remove PYFolder object from disk
 */
+ (void)removeFolder:(PYFolder *)folder;
/**
 Get all PYFolder objects from disk
 */
+ (NSArray *)getFoldersFromCache;
/**
 Get PYFolder object from disk with key(folderId)
 */
+ (PYFolder *)getFolderFromCacheWithFolderId:(NSString *)folderId;
/**
 Cache PYFolder object on disk
 */
+ (void)cacheFolder:(PYFolder *)folder;
/**
 Get folder with particular id from server and cache it on disk
 */
+ (void)getAndCacheFolderWithServerId:(NSString *)folderId
                           inChannel:(PYChannel *)channel
                         requestType:(PYRequestType)reqType;

@end
