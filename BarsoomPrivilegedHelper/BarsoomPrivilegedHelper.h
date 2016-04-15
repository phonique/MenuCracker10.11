//
//  PrivilegedHelper.h
//  BarsoomByPH
//
//  Created by Fabrice Leyne on 10/5/15.
//  Copyright © 2015 Fabrice Leyne. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#define kHelperToolMachServiceName @"com.fabriceleyne.barsoomPrivilegedHelper"



@protocol PrivilegedHelperProtocol

@required

- (void)connectWithEndpointReply:(void(^)(NSXPCListenerEndpoint * endpoint))reply;
- (void)prepareForMenuExtras:(void(^)(NSString * version))reply;
- (void)prepareToRemoveForMenuExtras:(void(^)(NSString * version))reply;
- (void)readLicenseKeyAuthorization:(NSData *)authData withReply:(void(^)(NSError * error, NSString * licenseKey))reply;
- (void)writeLicenseKey:(NSString *)licenseKey authorization:(NSData *)authData withReply:(void(^)(NSError * error))reply;

@end



@interface BarsoomPrivilegedHelper : NSObject


- (void)run;


@end
