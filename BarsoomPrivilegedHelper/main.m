//
//  main.m
//  BarsoomPrivilegedHelper
//
//  Created by Fabrice Leyne on 10/5/15.
//  Copyright © 2015 Fabrice Leyne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BarsoomPrivilegedHelper.h"

int main(int argc, const char * argv[]) {
    #pragma unused(argc)
    #pragma unused(argv)

    @autoreleasepool {
        BarsoomPrivilegedHelper *  m;
        
        m = [[BarsoomPrivilegedHelper alloc] init];
        [m run];                // This never comes back...
    }
    
    return EXIT_FAILURE;        // ... so this should never be hit.

}
