//
//  AppDelegate.m
//

//
//  Created by Fabrice Leyne on 10/5/15.
//  Copyright © 2015 Fabrice Leyne. All rights reserved.
//

#import "AppDelegate.h"
#define priviledgeHelperName @"com.fabriceleyne.barsoomPrivilegedHelper"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    systemHelperManager = [BARSManageSystemHelper new];
    [systemHelperManager setDelegate:self];
    [self updateRemoveButton];
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-(IBAction) actionRemove:(id)sender
{
    [systemHelperManager removeFilesForHelper];
    [systemHelperManager removeHelper];
    [self updateRemoveButton];
}

-(IBAction) actionInstall:(id)sender
{
    [self checkAndOrInstall];
}

-(void) checkAndOrInstall
{
   bool isExisting = [[NSFileManager defaultManager] fileExistsAtPath:[self plistPath]];
   if(!isExisting)
    {
        [systemHelperManager installHelper];
        [systemHelperManager checkReadiness];
    }
    else
    {
        [systemHelperManager checkReadiness];
    }
    [self updateRemoveButton];
    
}

-(NSString*) plistPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSLocalDomainMask, YES);
    NSString *libDirectory = paths[0];
    libDirectory = [libDirectory stringByAppendingPathComponent:@"PrivilegedHelperTools"];
    libDirectory = [libDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",priviledgeHelperName]];
    
    return libDirectory;
}

-(void) displayAnswer:(NSString*) answer
{
    [resultTextField setStringValue:answer];
}

-(void) updateRemoveButton
{
       bool isExisting = [[NSFileManager defaultManager] fileExistsAtPath:[self plistPath]];
       if(isExisting)
           [removeButton setEnabled:YES];
        else
           [removeButton setEnabled:NO];
}



@end
