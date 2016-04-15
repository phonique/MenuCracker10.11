//
//  AppDelegate.h
//  BarsoomByPH
//
//  Created by Fabrice Leyne on 10/5/15.
//  Copyright © 2015 Fabrice Leyne. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BARSManageSystemHelper.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    BARSManageSystemHelper* systemHelperManager;
    IBOutlet NSTextField* resultTextField;
    IBOutlet NSButton* removeButton;
}

@end

