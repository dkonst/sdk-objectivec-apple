//
//  Created by Konstantin Dorodov on 1/9/13.
//  Copyright (c) 2012 PrYv. All rights reserved.
//


#import "PYFolder.h"


@implementation PYFolder

@synthesize folderId = _folderId;
@synthesize channelId = _channelId;
@synthesize name = _name;
@synthesize parentId = _parentId;
@synthesize clientData = _clientData;
@synthesize timeCount = _timeCount;
@synthesize children = _children;
@synthesize hidden = _hidden;
@synthesize trashed = _trashed;

@synthesize isSyncTriedNow = _isSyncTriedNow;
@synthesize hasTmpId = _hasTmpId;
@synthesize notSyncAdd = _notSyncAdd;
@synthesize notSyncModify = _notSyncModify;
@synthesize synchedAt = _synchedAt;
@synthesize modifiedEventPropertiesAndValues = _modifiedEventPropertiesAndValues;

- (void)dealloc
{
    [_folderId release];
    [_channelId release];
    [_name release];
    [_parentId release];
    [_clientData release];
    [super dealloc];
}

- (NSDictionary *)cachingDictionary
{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    
    if (_folderId && _folderId.length > 0) {
        [dic setObject:_folderId forKey:@"id"];
    }
    
    if (_name && _name.length > 0) {
        [dic setObject:_name forKey:@"name"];
    }

    if (_parentId && _parentId.length > 0) {
        [dic setObject:_parentId forKey:@"parentId"];
    }

    if (_channelId && _channelId.length > 0) {
        [dic setObject:_channelId forKey:@"channelId"];
    }
                
    if (_clientData && _clientData.count > 0) {
        [dic setObject:_clientData forKey:@"clientData"];
    }

    [dic setObject:[NSNumber numberWithBool:_hidden] forKey:@"hidden"];
    [dic setObject:[NSNumber numberWithBool:_trashed] forKey:@"trashed"];
    [dic setObject:[NSNumber numberWithBool:_hasTmpId] forKey:@"hasTmpId"];
    [dic setObject:[NSNumber numberWithBool:_notSyncAdd] forKey:@"notSyncAdd"];
    [dic setObject:[NSNumber numberWithBool:_notSyncModify] forKey:@"notSyncModify"];
    [dic setObject:[NSNumber numberWithDouble:_synchedAt] forKey:@"synchedAt"];
    if (_modifiedEventPropertiesAndValues) {
        [dic setObject:_modifiedEventPropertiesAndValues forKey:@"modifiedProperties"];
    }
    
    return [dic autorelease];
}


- (NSDictionary *)dictionary {
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
            
    if (_folderId && _folderId.length > 0) {
        [dic setObject:_folderId forKey:@"id"];
    }
    
    if (_name && _name.length > 0) {
        [dic setObject:_name forKey:@"name"];
    }
    
    if (_parentId && _parentId.length > 0) {
        [dic setObject:_parentId forKey:@"parentId"];
    }
    
    if (_clientData && _clientData.count > 0) {
        [dic setObject:_clientData forKey:@"clientData"];
    }
    
    [dic setObject:[NSNumber numberWithBool:_hidden] forKey:@"hidden"];
    
    return [dic autorelease];
    
}


- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@", self.id=%@", self.folderId];
    [description appendFormat:@", self.name=%@", self.name];
    [description appendFormat:@", self.parentId=%@", self.parentId];
    [description appendFormat:@", self.hidden=%d", self.hidden];
    [description appendFormat:@", self.trashed=%d", self.trashed];
    [description appendString:@">"];
    return description;
}

@end