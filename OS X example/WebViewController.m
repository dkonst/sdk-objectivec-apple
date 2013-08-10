//
//  WebViewController.m
//  PryvApiKit
//
//  Created by Victor Kristof on 09.07.13.
//  Copyright (c) 2013 Pryv. All rights reserved.
//

#import "WebViewController.h"
#import "PryvApiKit.h"
//#import "PYWebLoginViewController.h"

@interface WebViewController () <PYWebLoginDelegate>

@end

@implementation WebViewController

@synthesize webView;

-(void)awakeFromNib{
    
    NSLog(@"Signin Started");
    
    NSArray *objects = [NSArray arrayWithObjects:@"*", @"manage", nil];
    NSArray *keys = [NSArray arrayWithObjects:@"streamId", @"level", nil];
    
    NSArray *permissions = [NSArray arrayWithObject:[NSDictionary dictionaryWithObjects:objects forKeys:keys]];
    
    [PYClient setDefaultDomainStaging];
    [PYWebLoginViewController requestAccessWithAppId:@"pryv-sdk-macosx-example"
                                      andPermissions:permissions
                                            delegate:self
                                         withWebView:&webView];
}

-(void)windowWillClose:(NSNotification *)notification{
    //[self pyWebLoginNotVisible:notification];
    //NSLog(@"Notification posted");
}

//- (void) pyWebLoginNotVisible:(NSNotification *)notification {
//    [[NSNotificationCenter defaultCenter] postNotificationName:kPYWebViewLoginNotVisibleNotification object:self];
//}

- (void) pyWebLoginSuccess:(PYAccess*)pyAccess {
    NSLog(@"Signin With Success %@ %@",pyAccess.userID,pyAccess.accessToken);
    [pyAccess synchronizeTimeWithSuccessHandler:nil errorHandler:nil];
}
- (void) pyWebLoginAborded:(NSString*)reason {
    NSLog(@"Signin Aborded: %@",reason);
}

- (void) pyWebLoginError:(NSError*)error {
    NSLog(@"Signin Error: %@",error);
}


@end
