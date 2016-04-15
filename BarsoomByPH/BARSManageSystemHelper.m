//
//  BARSManageSystemHelper.m
//  BarsoomByPH
//
//  Created by Fabrice Leyne on 10/5/15.
//  Copyright © 2015 Fabrice Leyne. All rights reserved.
//

#import "BARSManageSystemHelper.h"
#import "BarsoomPrivilegedHelper.h"
#include <ServiceManagement/ServiceManagement.h>
#import "Common.h"

@implementation BARSManageSystemHelper


-(instancetype)init
{
    self = [super init];
    
    if(self)
    {
        [self createAuthorizationToTheSystem];
    }
    
    return self;
}


-(void) createAuthorizationToTheSystem
{
    OSStatus                    err;
    AuthorizationExternalForm   extForm;
        
    err = AuthorizationCreate(NULL, NULL, 0, &self->_authRef);
    if (err == errAuthorizationSuccess) {
        err = AuthorizationMakeExternalForm(self->_authRef, &extForm);
    }
    if (err == errAuthorizationSuccess) {
        self.authorization = [[NSData alloc] initWithBytes:&extForm length:sizeof(extForm)];
    }
    assert(err == errAuthorizationSuccess);
        
    if (self->_authRef) {
        [Common setupAuthorizationRights:self->_authRef];
    }

}

- (void)connectToHelperTool
{
    assert([NSThread isMainThread]);
    if (self.helperToolConnection == nil) {
        self.helperToolConnection = [[NSXPCConnection alloc] initWithMachServiceName:kHelperToolMachServiceName options:NSXPCConnectionPrivileged];
        self.helperToolConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(PrivilegedHelperProtocol)];
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-retain-cycles"
        self.helperToolConnection.invalidationHandler = ^{
            self.helperToolConnection.invalidationHandler = nil;
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.helperToolConnection = nil;
                NSLog(@"connection invalidated\n");
            }];
        };
#pragma clang diagnostic pop
        [self.helperToolConnection resume];
    }
}

- (void)connectAndExecuteCommandBlock:(void(^)(NSError *))commandBlock
{
    assert([NSThread isMainThread]);
    [self connectToHelperTool];
    commandBlock(nil);
}

- (void) installHelper
{
    Boolean             success;
    CFErrorRef          error;
    
    success = SMJobBless(
                         kSMDomainSystemLaunchd,
                         CFSTR("com.fabriceleyne.barsoomPrivilegedHelper"),
                         self->_authRef,
                         &error
                         );
    
    if (success) {
        NSLog(@"success\n");
    } else {
        NSLog(@"error :%@",(__bridge NSError *) error);
        CFRelease(error);
    }
}

- (void) removeHelper
{
    Boolean             success;
    CFErrorRef          error;
    
    success = SMJobRemove(
                         kSMDomainSystemLaunchd,
                         CFSTR("com.fabriceleyne.barsoomPrivilegedHelper"),
                         self->_authRef,
                         true,
                         &error
                         );
    
    if (success) {
        NSLog(@"success\n");
    } else {
        NSLog(@"error :%@",(__bridge NSError *) error);
        CFRelease(error);
    }
}

- (void)checkReadiness
{
    [self connectAndExecuteCommandBlock:^(NSError * connectError) {
        if (connectError != nil) {
            [_delegate performSelector:@selector(displayAnswer:) withObject:[connectError description]];
        } else
        {
            [[self.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError * proxyError) {
                [_delegate performSelector:@selector(displayAnswer:) withObject:[proxyError description]];
            }] prepareForMenuExtras:^(NSString *version) {
                [_delegate performSelector:@selector(displayAnswer:) withObject:version];
            }];
        }        
    }];
}

-(void) removeFilesForHelper
{
    [self connectAndExecuteCommandBlock:^(NSError * connectError) {
        if (connectError != nil) {
            [_delegate performSelector:@selector(displayAnswer:) withObject:[connectError description]];
        } else
        {
            [[self.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError * proxyError) {
                [_delegate performSelector:@selector(displayAnswer:) withObject:[proxyError description]];
            }] prepareToRemoveForMenuExtras:^(NSString *version) {
                [_delegate performSelector:@selector(displayAnswer:) withObject:version];
            }];
        }
    }];
}

-(void) displayAnswer:(NSString*) answer
{
    
}

@end
