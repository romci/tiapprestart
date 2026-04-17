/**
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */

#import "TiApp.h"
#import "InfoRbornTiapprestartModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "TiLayoutQueue.h"

@implementation InfoRbornTiapprestartModule

#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"8f8d3e85-3c4f-4b18-b6c5-6fb0722ea8c9";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"info.rborn.tiapprestart";
}

#pragma Public APIs

-(void)restartApp:(id)unused
{
    TiThreadPerformOnMainThread(^{
        [[[TiApp app] controller] shutdownUi:self];
    }, NO);
}

-(void)_resumeRestart:(id)unused
{
    UIApplication * app = [UIApplication sharedApplication];
    TiApp * appDelegate = [TiApp app];
    [TiLayoutQueue resetQueue];
    
    /* Begin backgrounding simulation */
    [appDelegate applicationWillResignActive:app];
    [appDelegate applicationDidEnterBackground:app];
    [appDelegate endBackgrounding];
    /* End backgrounding simulation */

    /* Tear down the old view system inside an autorelease pool so iOS 26
       releases the old UINavigationController fully before the new one is built. */
    @autoreleasepool {
        [[appDelegate window] removeFromSuperview];
    }

    /* Disconnect the old modules. */
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    NSMutableArray * delegateModules = (NSMutableArray *)[appDelegate valueForKey:@"modules"];
    for (TiModule * thisModule in delegateModules) {
        [nc removeObserver:thisModule];
    }
    /* Because of other issues, we must leak the modules as well as the runtime */
    [delegateModules copy];
    [delegateModules removeAllObjects];

    /* Disconnect the Kroll bridge, and spoof the shutdown */
    [nc removeObserver:[appDelegate krollBridge]];
    NSNotification *notification = [NSNotification notificationWithName:kTiContextShutdownNotification object:[appDelegate krollBridge]];
    [nc postNotification:notification];

    /* Defer re-launch to the next run loop cycle so the old UINavigationController
       and UIWindow are fully deallocated by UIKit before the new hierarchy is built.
       This prevents the iOS 26 "Cannot form weak reference to deallocating object" abort. */
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            [appDelegate application:app didFinishLaunchingWithOptions:[appDelegate launchOptions]];
            [appDelegate applicationWillEnterForeground:app];
            [appDelegate applicationDidBecomeActive:app];
        }
    });
}

@end
