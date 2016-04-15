//
//  BARSManageSystemHelper.h
//  BarsoomByPH
//
//  Created by Fabrice Leyne on 10/5/15.
//  Copyright © 2015 Fabrice Leyne. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BARSManageSystemHelper : NSObject
{
    AuthorizationRef    _authRef;
}

@property (atomic, copy,   readwrite) NSData *                  authorization;
@property (atomic, strong, readwrite) NSXPCConnection *         helperToolConnection;
@property (nonatomic, assign) id delegate;

- (void) checkReadiness;
-(void) removeFilesForHelper;
- (void) installHelper;
- (void) removeHelper;
-(void) displayAnswer:(NSString*) answer;

@end
