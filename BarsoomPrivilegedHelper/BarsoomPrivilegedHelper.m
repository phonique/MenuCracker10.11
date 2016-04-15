//
//  PrivilegedHelper.m
//  BarsoomByPH
//
//  Created by Fabrice Leyne on 10/5/15.
//  Copyright © 2015 Fabrice Leyne. All rights reserved.
//

#import "BarsoomPrivilegedHelper.h"
#import "Common.h"
#define certifKey @"or anchor apple generic and certificate leaf[subject.OU] = \"XXXXXXXXXX\""
#define bundleID "com.apple.security.coderequirements"
#define privilegedHelper @"com.fabriceleyne.barsoomPrivilegedHelper"

@interface BarsoomPrivilegedHelper () <NSXPCListenerDelegate, PrivilegedHelperProtocol>

@property (atomic, strong, readwrite) NSXPCListener *    listener;

@end

@implementation BarsoomPrivilegedHelper
- (id)init
{
    self = [super init];
    if (self != nil) {
        // Set up our XPC listener to handle requests on our Mach service.
        self->_listener = [[NSXPCListener alloc] initWithMachServiceName:kHelperToolMachServiceName];
        self->_listener.delegate = self;
    }
    return self;
}


- (void)run
{
    // Tell the XPC listener to start processing requests.
    
    [self.listener resume];
    
    // Run the run loop forever.
    
    [[NSRunLoop currentRunLoop] run];
}


- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    assert(listener == self.listener);
    #pragma unused(listener)
    assert(newConnection != nil);
    
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(PrivilegedHelperProtocol)];
    newConnection.exportedObject = self;
    [newConnection resume];
    
    return YES;
}






- (NSError *)checkAuthorization:(NSData *)authData command:(SEL)command
// Check that the client denoted by authData is allowed to run the specified command.
// authData is expected to be an NSData with an AuthorizationExternalForm embedded inside.
{
#pragma unused(authData)
    NSError *                   error;
    OSStatus                    err;
    OSStatus                    junk;
    AuthorizationRef            authRef;
    
    assert(command != nil);
    
    authRef = NULL;
    
    // First check that authData looks reasonable.
    
    error = nil;
    if ( (authData == nil) || ([authData length] != sizeof(AuthorizationExternalForm)) ) {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:paramErr userInfo:nil];
    }
    
    // Create an authorization ref from that the external form data contained within.
    
    if (error == nil) {
        err = AuthorizationCreateFromExternalForm([authData bytes], &authRef);
        
        // Authorize the right associated with the command.
        
        if (err == errAuthorizationSuccess) {
            AuthorizationItem   oneRight = { NULL, 0, NULL, 0 };
            AuthorizationRights rights   = { 1, &oneRight };
            
            oneRight.name = [[Common authorizationRightForCommand:command] UTF8String];
            assert(oneRight.name != NULL);
            
            err = AuthorizationCopyRights(
                                          authRef,
                                          &rights,
                                          NULL,
                                          kAuthorizationFlagExtendRights | kAuthorizationFlagInteractionAllowed,
                                          NULL
                                          );
        }
        if (err != errAuthorizationSuccess) {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
        }
    }
    
    if (authRef != NULL) {
        junk = AuthorizationFree(authRef, 0);
        assert(junk == errAuthorizationSuccess);
    }
    
    return error;
}


- (BOOL)isValidLicenseKey:(NSString *)licenseKey
{
    BOOL        success;
    NSUUID *    uuid;

    success = (licenseKey != nil);
    if (success) {
        uuid = [[NSUUID alloc] initWithUUIDString:licenseKey];
        success = (uuid != nil);
    }

    return success;
}

#pragma mark * PrivilegedHelperProtocol implementation
- (void)connectWithEndpointReply:(void (^)(NSXPCListenerEndpoint *))reply
{
    reply([self.listener endpoint]);
}

- (void)prepareForMenuExtras:(void(^)(NSString * version))reply
{
    if([self readPreferences])
        [self writePreferences];
    
    reply(@"MenuExtras Ready");
}

static NSString * kLicenseKeyDefaultsKey = @"licenseKey";

- (void)readLicenseKeyAuthorization:(NSData *)authData withReply:(void(^)(NSError * error, NSString * licenseKey))reply
// Part of the HelperToolProtocol.  Gets the current license key from the defaults database.
{
    NSString *  licenseKey;
    NSError *   error;
    
    error = [self checkAuthorization:authData command:_cmd];
    if (error == nil) {
        licenseKey = [[NSUserDefaults standardUserDefaults] stringForKey:kLicenseKeyDefaultsKey];
    } else {
        licenseKey = nil;
    }
    
    reply(error, licenseKey);
}

- (void)writeLicenseKey:(NSString *)licenseKey authorization:(NSData *)authData withReply:(void(^)(NSError * error))reply
// Part of the HelperToolProtocol.  Saves the license key to the defaults database.
{
    NSError *   error;
    
    error = nil;
    if ( ! [self isValidLicenseKey:licenseKey] ) {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:paramErr userInfo:nil];
    }
    if (error == nil) {
        error = [self checkAuthorization:authData command:_cmd];
    }
    if (error == nil) {
        [[NSUserDefaults standardUserDefaults] setObject:licenseKey forKey:kLicenseKeyDefaultsKey];
    }
    
    reply(error);
}


-(void) writePreferences
{
    CFStringRef key = CFSTR("Entitlements");
    
    CFStringRef aValue = (CFStringRef) certifKey;

    NSString* entitlements = [self existingKey];
    
    if([entitlements length] != 0)
        aValue = (__bridge CFStringRef) [NSString stringWithFormat:@"%@ %@", entitlements, certifKey];
    else
        aValue = (__bridge CFStringRef) [NSString stringWithFormat:@"%@ %@", @"always", certifKey];
    
    CFPreferencesSetValue(key, aValue,
                          CFSTR(bundleID), kCFPreferencesAnyUser,
                          kCFPreferencesCurrentHost);
    
    CFPreferencesSynchronize(CFSTR(bundleID),
                             kCFPreferencesAnyUser,
                             kCFPreferencesCurrentHost) ;
    
    [self restartSUIServer];
}

-(bool) readPreferences
{
    NSString* entitlements = [self existingKey];
    
    if([entitlements length] == 0) return YES;
    
    if ([entitlements rangeOfString:certifKey].location == NSNotFound)
        return YES;
    
    return NO;
}

-(NSString*) plistPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSLocalDomainMask, YES);
    NSString *libDirectory = paths[0];
    libDirectory = [libDirectory stringByAppendingPathComponent:@"Preferences"];
    libDirectory = [libDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%s.plist",bundleID]];

    return libDirectory;
}

-(NSString*) priviledgedPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSLocalDomainMask, YES);
    NSString *libDirectory = paths[0];
    libDirectory = [libDirectory stringByAppendingPathComponent:@"PrivilegedHelperTools"];
    libDirectory = [libDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",privilegedHelper]];
    
    return libDirectory;
}


-(NSString*) existingKey
{
    NSDictionary* dico = [[NSDictionary alloc] initWithContentsOfFile:[self plistPath]];
    if(!dico) return @"";
    
    NSString* entitlements = [dico objectForKey:@"Entitlements"];
    if(!entitlements) return @"";

    return entitlements;
}


-(void) restartSUIServer
{
    NSString *identifier = @"com.apple.systemuiserver";
    NSArray *selectedApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:identifier];
    NSRunningApplication* app = [selectedApps firstObject];
    if(!app) return;
    NSInteger pid = [app processIdentifier];
    kill((pid_t)pid, SIGKILL );
}

- (void)prepareToRemoveForMenuExtras:(void(^)(NSString * version))reply
{
    bool isExisting = [[NSFileManager defaultManager] fileExistsAtPath:[self plistPath]];
 
    if(isExisting)
        [[NSFileManager defaultManager]  removeItemAtPath:[self plistPath] error:nil];

    
    bool isExistingPriv = [[NSFileManager defaultManager] fileExistsAtPath:[self priviledgedPath]];
    
    if(isExistingPriv)
        [[NSFileManager defaultManager]  removeItemAtPath:[self priviledgedPath] error:nil];

    [self restartSUIServer];
    
    reply(@"MenuCracker Removed");
}


@end
