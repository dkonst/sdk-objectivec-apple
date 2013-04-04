//
//  PYEViewController.m
//  iOs Example
//
//  Created by Pierre-Mikael Legris on 06.02.13.
//  Copyright (c) 2013 Pryv. All rights reserved.
//

#import "PYEViewController.h"
#import "PryvApiKit.h"
#import "PYEventNote.h"
#import "PYEventType.h"

@interface PYEViewController ()

@end

@implementation PYEViewController

@synthesize signinButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    PYAccess *access = [PYClient createAccessWithUsername:@"perkikiki" andAccessToken:kPYUserTempToken];
    [access getChannelsWithRequestType:PYRequestTypeSync filterParams:nil successHandler:^(NSArray *channelList) {
        
        for (PYChannel *channel in channelList) {
            
//            [channel getAllEventsWithRequestType:PYRequestTypeSync successHandler:^(NSArray *eventList) {
//                
//            } errorHandler:^(NSError *error) {
//                
//            }];
            
            PYEventType *eventType = [[PYEventType alloc] initWithClass:PYEventClassNote andFormat:PYEventFormatTxt];
            NSString *noteTextValue = @"gfdgasdhjfasNenad";
            PYEventNote *noteEvent = [[PYEventNote alloc] initWithType:eventType
                                                             noteValue:noteTextValue
                                                              folderId:nil
                                                                  tags:nil
                                                           description:@"nenad description"
                                                            clientData:nil];
            
            [channel createEvent:noteEvent requestType:PYRequestTypeSync successHandler:^(NSString *newEventId, NSString *stoppedId) {
                
            } errorHandler:^(NSError *error) {
                
            }];
            

//            [channel getFoldersWithRequestType:PYRequestTypeAsync
//                                  filterParams:@{@"includeHidden": @"true", @"state" : @"all"}
//                                successHandler:^(NSArray *folderList) {
//                
//                
//            } errorHandler:^(NSError *error) {
//                
//            }];

        }
        
        
    } errorHandler:^(NSError *error) {
        
    }];
    
    
//    [[PYApiConnectionClient sharedPYApiConnectionClient] startClientWithUserId:@"perkikiki"
//                                                         oAuthToken:kPYUserTempToken
//                                                     successHandler:^(NSTimeInterval serverTime)
//     {
//         NSLog(@"success");
//     }errorHandler:^(NSError *error) {
//        NSLog(@"");
//    }];
//
//    NSString *channelId = @"position";
//    
//    NSMutableDictionary *channelData = [[NSMutableDictionary alloc] init];
//    [channelData setObject:@"Position2" forKey:@"name"];
//
//    NSMutableDictionary *clientData = [[NSMutableDictionary alloc] init];
//    [clientData setObject:@"value" forKey:@"key"];
//    [channelData setObject:clientData forKey:@"clientData"];
//        
//    [[PYChannelClient sharedPYChannelClient] editChannelWithRequestType:PYRequestTypeSync channelId:channelId data:channelData successHandler:^(){
//        NSLog(@"edit success");
//    } errorHandler:^(NSError *error){
//        NSLog(@"edit error %@", error);
//    }];
//    
//    [[PYFolderClient sharedPYFolderClient] getFoldersWithRequestType:PYRequestTypeAsync
//                                                filterParams:nil
//                                              successHandler:^(NSArray *folderList)
//     {
//         NSLog(@"folder list %@",folderList);
//     }errorHandler:^(NSError *error) {
//         NSLog(@"error %@",error);
//     }];
//    
//    
//    [[PYChannelClient sharedPYChannelClient] getChannelsWithRequestType:PYRequestTypeAsync filterParams:nil successHandler:^(NSArray *channelList)
//    {
//        NSLog(@"channel list %@", channelList);
//    } errorHandler:^(NSError *error) {
//        NSLog(@"error %@", error);
//    }];
//    
//
//    NSLog(@"end of viewDidLoad");
}

- (IBAction)siginButtonPressed: (id) sender  {
    NSLog(@"Signin Started");

}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
