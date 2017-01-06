//
//  RDCustomAlertView.m
//  RiceDonate
//
//  Created by ozr on 12/26/14.
//  Copyright (c) 2014 tietie tech. All rights reserved.
//

#import "RDCustomAlertView.h"
#import <objc/runtime.h>

NSString * const RDPopViewOperationQueueSemaphoreSingalNotification  = @"com.ricedonate.popViewOperationQueue.semaphoreSingal";

@interface RDCustomAlertView ()

@property (nonatomic, weak) UIWindow *parentWindow;

@end

@implementation RDCustomAlertView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5f];
    }
    return self;
}

- (void)show
{
    
    if (objc_getAssociatedObject(self, _cmd)) return;
    else objc_setAssociatedObject(self, _cmd, @"Show", OBJC_ASSOCIATION_RETAIN);
    
    self.hidden = NO;

    self.parentWindow = [UIApplication sharedApplication].keyWindow;
    [self.parentWindow addSubview:self];
}

- (void)close
{
    
    if (objc_getAssociatedObject(self, _cmd)) return;
    else objc_setAssociatedObject(self, _cmd, @"Close", OBJC_ASSOCIATION_RETAIN);
    
    self.hidden = YES;
    for (UIView *v in [self subviews]) {
        [v removeFromSuperview];
    }
    
    [self removeFromSuperview];
    
    if (self.completeHandler) {
        self.completeHandler();
    }
}

@end

@interface RDPopViewOperationQueue ()
{
    dispatch_semaphore_t _semaphore;
    NSOperationQueue *_operationQueue;
}

@end

@implementation RDPopViewOperationQueue

- (instancetype)init
{
    if (self = [super init]) {
        _semaphore = dispatch_semaphore_create(1) ;//创建一个初始信号量为1的semaphore
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
        
        [[[NSNotificationCenter defaultCenter] rac_addObserverForName:RDPopViewOperationQueueSemaphoreSingalNotification
                                                              object:nil] subscribeNext:^(id x) {
            dispatch_semaphore_signal(_semaphore);
        }];
    }
    
    return self;
}

- (void)waitWithBlock:(void (^)())block
{
    [_operationQueue addOperationWithBlock:^{
        dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_main_queue(), [block copy]);
    }];
}

+ (RDPopViewOperationQueue *) sharedInstance
{
    static RDPopViewOperationQueue* instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [RDPopViewOperationQueue new];
    });
    
    return instance;
}

+ (void)waitWithBlock:(void (^)())block
{
    return [[self sharedInstance] waitWithBlock:block];
}

//+ (void)lockQueue
//{
//    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);/
//}

@end
