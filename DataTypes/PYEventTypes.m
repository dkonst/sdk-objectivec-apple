//
//  EventTypes.m
//  PryvApiKit
//
//  Created by Perki on 28.11.13.
//  Copyright (c) 2013 Pryv. All rights reserved.
//

#import "PYEventTypes.h"
#import "PYEventType.h"
#import "PYEventTypesPackagedData.h"
#import "PYEvent.h"
#import "PYMeasurementSet.h"


#define kMeasurementSetsUrl @"http://pryv.github.io/event-types/extras.json"

@interface PYEventTypes ()

- (void)initObject;
- (void)updateFlat;
- (void)changeNSDictionary:(NSDictionary**) dict withContentOfJSONString:(id) jsonString;
- (void)executeCompletionBlockOnMainQueue:(PYEventTypesCompletionBlock)completionBlock withObject:(id)object andError:(NSError*)error;

@end

@implementation PYEventTypes

@synthesize hierarchical = _hierarchical;
@synthesize flat = _flat;
@synthesize extras = _extras;
@synthesize measurementSets = _measurementSets;


+ (PYEventTypes*)sharedInstance
{
    static PYEventTypes *_sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[PYEventTypes alloc] init];
        [_sharedInstance initObject];
    });
    return _sharedInstance;
}


- (void)initObject
{
    
    _hierarchical = [[NSDictionary alloc] init];
    [self changeNSDictionary:&_hierarchical withContentOfJSONString:PYEventTypesPackagedData.hierarchical];
    
    
    _extras = [[NSDictionary alloc] init];
    [self changeNSDictionary:&_extras withContentOfJSONString:PYEventTypesPackagedData.extras];
    
    _flat = [[NSMutableDictionary alloc] init];
    [self updateFlat];
    
    
    _measurementSets = [[NSMutableArray alloc] init];
    [self updateMeasurementSets];
}

/**
 * Update _flat reference table from hierachical data
 */
- (void)updateFlat
{
    [_flat removeAllObjects];
    
    NSDictionary *classes = [_hierarchical objectForKey:@"classes"];
    for(NSString *classKey in [classes allKeys])
    {
        NSDictionary *formats = [[classes objectForKey:classKey] objectForKey:@"formats"];
        for(NSString *formatKey in [formats allKeys])
        {
            PYEventType* eventType = [[PYEventType alloc] initWithClassKey:classKey
                                                              andFormatKey:formatKey
                                                   andDefinitionDictionary:[formats objectForKey:formatKey]];
            
            [_flat setObject:eventType forKey:eventType.key];
        }
    }
    
    // --- add extras
    NSDictionary *extras = [_extras objectForKey:@"extras"];
    for(NSString *classKey in [extras allKeys])
    {
        NSDictionary *formats = [[extras objectForKey:classKey] objectForKey:@"formats"];
        for(NSString *formatKey in [formats allKeys])
        {
            PYEventType* eventType = [_flat objectForKey:[NSString stringWithFormat:@"%@/%@", classKey, formatKey]];
            if (! eventType) {
                NSLog(@"WARNING .. PYEventTypes.updateFlat+extras cannot find %@ in _flat",
                      [NSString stringWithFormat:@"%@/%@", classKey, formatKey]);
            } else {
                [eventType addExtrasDefinitionsFromDictionary:[formats objectForKey:formatKey]];
            }
        }
    }
    
}

/**
 * Update _measurementSets reference table from extras data
 */
- (void)updateMeasurementSets
{
    [self.measurementSets removeAllObjects];

    NSDictionary *setsJSON = [_extras objectForKey:@"sets"];
    for(NSString *setKey in [setsJSON allKeys])
    {
        NSDictionary *setDic = [setsJSON objectForKey:setKey];
        PYMeasurementSet *set = [[PYMeasurementSet alloc] initWithKey:setKey andDictionary:setDic];
        [self.measurementSets addObject:set];
    }
}



-(void) changeNSDictionary:(NSDictionary**) dict withContentOfJSONString:(id) jsonString
{
    [*dict release];
    NSError *e = nil;
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    *dict = [NSJSONSerialization JSONObjectWithData: data options:kNilOptions error: &e];
    if (! *dict) {
        NSLog(@"Failed parsing JSON string to NSDictionary %@", e);
    }
    [*dict retain];
}


- (void)reloadWithCompletionBlock:(PYEventTypesCompletionBlock)completionBlock
{
    
    // TODO if connection reload if not online use pakaged set..
    
    /**
     NSURL *measurementSetsURL = [NSURL URLWithString:kMeasurementSetsUrl];
     NSURLRequest *request = [[NSURLRequest alloc] initWithURL:measurementSetsURL];
    [PYClient sendRequest:request withReqType:PYRequestTypeSync success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
    }
      [self executeCompletionBlockOnMainQueue:completionBlock withObject:result andError:nil];
     } failure:^(NSError *error) {
         [self executeCompletionBlockOnMainQueue:completionBlock withObject:nil andError:error];
     }];
     **/
    
    [self executeCompletionBlockOnMainQueue:completionBlock withObject:self andError:nil];
}




- (PYEventType*) pyTypeForEvent:(PYEvent*)event
{
    return [self pyTypeForString:event.type];
}

- (PYEventType*) pyTypeForString:(NSString *)eventTypeStr
{
    //TODO either generate an error if unkown or return an "uknown event structure"
    return [_flat objectForKey:eventTypeStr];
}


- (void)executeCompletionBlockOnMainQueue:(PYEventTypesCompletionBlock)completionBlock withObject:(id)object andError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(completionBlock)
        {
            completionBlock(object, error);
        }
    });
}

@end
