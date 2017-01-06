//
//  RDLoadingIndicatorHUD.m
//  RiceDonate
//
//  Created by ozr on 16/12/19.
//  Copyright © 2016年 ricedonate. All rights reserved.
//

#import "RDLoadingIndicatorHUD.h"
#import "RDLoadingIndicatorView.h"

@implementation RDLoadingIndicatorHUD

+ (MB_INSTANCETYPE)showHUDAddedTo:(UIView *)view animated:(BOOL)animated
{
    UIView *lastHud = [MBProgressHUD HUDForView:view];
    if (lastHud) {
        [lastHud removeFromSuperview];
    }
    id hud = [super showHUDAddedTo:view animated:animated];
    RDLoadingIndicatorView *loadingView= [[RDLoadingIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    loadingView.frame = CGRectMake(0, 0, 20, 20);
    loadingView.center = ((UIView *)hud).center;
    [hud addSubview:loadingView];
    [loadingView startAnimating];
    
    ((MBProgressHUD *)hud).mode = MBProgressHUDModeCustomView;
    ((MBProgressHUD *)hud).customView = loadingView;
    ((MBProgressHUD *)hud).color = [UIColor clearColor];
    [hud setRemoveFromSuperViewOnHide:YES];
    return hud;
}

@end
