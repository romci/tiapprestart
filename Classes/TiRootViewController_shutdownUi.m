//
//  TiRootViewController_shutdownUi.m
//  tiapprestart
//
//  Created by Dan Tamas on 15/03/2014.
//
//

#import "TiRootViewController_shutdownUi.h"

@implementation TiRootViewController (ShutdownUI)


-(void)shutdownUi:(id)arg
{
  //FIRST DISMISS ALL MODAL WINDOWS
  UIViewController *topVC = [self topPresentedController];
  if (topVC != self) {
    UIViewController *presenter = [topVC presentingViewController];
    [presenter dismissViewControllerAnimated:NO
                                  completion:^{
                                    [self shutdownUi:arg];
                                  }];
    return;
  }

  //At this point all modal stuff is done. Go ahead and clean up proxies.
  NSArray *modalCopy = [modalWindows copy];
  NSArray *windowCopy = [containedWindows copy];

  /* On iOS 26+, calling windowWillClose/windowDidClose triggers a UINavigationController
     deallocation cascade that causes "Cannot form weak reference to deallocating object"
     aborts. Since _resumeRestart already leaks the entire UIWindow hierarchy intentionally,
     these close notifications are unnecessary — the JS runtime is being torn down anyway.
     Orphan modal and contained windows without actively closing them. */
  [modalCopy release];
  [windowCopy release];

  DebugLog(@"[INFO] UI SHUTDOWN COMPLETE. TRYING TO RESUME RESTART");
  if ([arg respondsToSelector:@selector(_resumeRestart:)]) {
    [arg performSelector:@selector(_resumeRestart:) withObject:nil];
  } else {
    DebugLog(@"[WARN] Could not resume. No selector _resumeRestart: found for arg");
  }
}

@end
