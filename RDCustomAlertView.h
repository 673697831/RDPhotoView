//
//  RDCustomAlertView.h
//  RiceDonate
//
//  Created by ozr on 12/26/14.
//  Copyright (c) 2014 tietie tech. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString * const RDPopViewOperationQueueSemaphoreSingalNotification;

@interface RDPopViewOperationQueue : NSObject

+ (void)waitWithBlock:(void (^)())block;

@end

@interface RDCustomAlertView : UIView

@property (nonatomic, copy)  void (^completeHandler)();

- (void)show;
- (void)close;

@end
