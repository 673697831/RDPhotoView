//
//  RDPhotoView.m
//  RiceDonate
//
//  Created by ozr on 15/12/14.
//  Copyright © 2015年 ricedonate. All rights reserved.
//

#import "RDPhotoView.h"
#import <UIImageView+WebCache.h>
#import "RDToastView.h"

#import "RDLoadingIndicatorHUD.h"

static const NSInteger kImageViewStartTag = 2000;
static const NSInteger kScrollViewStartTag = 3000;

@interface RDImageScrollView:UIScrollView <UIScrollViewDelegate>

@property (nonatomic, weak)   UIImageView *imageView;
@property (nonatomic, assign) CGRect      scaleOriginRect;
@property (nonatomic, assign) CGSize      imageSize;
@property (nonatomic, assign) CGRect      initRect;

- (void) setContentWithFrame:(CGRect) rect bResetFrame:(BOOL)bResetFrame;
- (void) setImage:(UIImage *) image;
- (void) setAnimationRect;
- (void) rechangeInitRect;

@end

@implementation RDImageScrollView

#pragma mark -

- (void) setContentWithFrame:(CGRect) rect bResetFrame:(BOOL)bResetFrame
{
    self.initRect = rect;
    if (bResetFrame) {
        self.imageView.frame = rect;
    }
}

- (void) setAnimationRect
{
    self.imageView.frame = self.scaleOriginRect;
    //避免缩放不正确 不能滑动
    [self setZoomScale:1 animated:NO];
}

- (void) rechangeInitRect
{
    self.zoomScale = 1.0;
    self.imageView.frame = self.initRect;
}

//居中显示逻辑
//- (void) setImage:(UIImage *) image
//{
//    if (image)
//    {
//        self.imageView.image = image;
//        self.imageSize = image.size;
//        
//        //判断首先缩放的值
//        float scaleX = self.frame.size.width/self.imageSize.width;
//        float scaleY = self.frame.size.height/self.imageSize.height;
//        
//        //倍数小的，先到边缘
//        
//        if (scaleX > scaleY)
//        {
//            //Y方向先到边缘
//            float imgViewWidth = self.imageSize.width*scaleY;
//            self.maximumZoomScale = self.frame.size.width/imgViewWidth;
//            
//            self.scaleOriginRect = (CGRect){self.frame.size.width/2-imgViewWidth/2,0,imgViewWidth,self.frame.size.height};
//        }
//        else
//        {
//            //X先到边缘
//            float imgViewHeight = self.imageSize.height*scaleX;
//            self.maximumZoomScale = self.frame.size.height/imgViewHeight;
//            
//            self.scaleOriginRect = (CGRect){0,self.frame.size.height/2-imgViewHeight/2,self.frame.size.width,imgViewHeight};
//        }
//    }
//}

//y方向长图显示逻辑
- (void) setImage:(UIImage *) image
{
    if (image)
    {
        self.imageView.image = image;
        self.imageSize = image.size;
        
        //判断首先缩放的值
        float scaleX = self.frame.size.width/self.imageSize.width;
        float scaleY = self.frame.size.height/self.imageSize.height;
        
        float imgViewHeight = self.imageSize.height*scaleX;
        float imgViewWidth = self.imageSize.width*scaleY;
        //倍数小的，先到边缘
        
        if (scaleX > scaleY)
        {
            //Y方向先到边缘
            self.maximumZoomScale = self.frame.size.width/imgViewWidth;
            
            self.scaleOriginRect = (CGRect){0,0,self.frame.size.width,imgViewHeight};
        }
        else
        {
            //X先到边缘
            self.maximumZoomScale = self.frame.size.height/imgViewHeight;
            
            self.scaleOriginRect = (CGRect){0,self.frame.size.height/2-imgViewHeight/2,self.frame.size.width,imgViewHeight};
        }
    }
}


#pragma mark -
#pragma mark - scroll delegate
- (UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    
    CGSize boundsSize = scrollView.bounds.size;
    CGRect imgFrame = self.imageView.frame;
    CGSize contentSize = scrollView.contentSize;
    
    CGPoint centerPoint = CGPointMake(contentSize.width/2, contentSize.height/2);
    
    // center horizontally
    if (imgFrame.size.width <= boundsSize.width)
    {
        centerPoint.x = boundsSize.width/2;
    }
    
    // center vertically
    if (imgFrame.size.height <= boundsSize.height)
    {
        centerPoint.y = boundsSize.height/2;
    }
    
    self.imageView.center = centerPoint;
}

#pragma mark -

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.bouncesZoom = YES;
        self.backgroundColor = [UIColor clearColor];
        self.delegate = self;
        
        UIImageView *imageView = [UIImageView new];
        imageView.tag = kImageViewStartTag;
        imageView.clipsToBounds = YES;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:imageView];
        _imageView = imageView;
        
    }
    return self;
}

@end

@interface RDPhotoView ()<UIScrollViewDelegate>

@property (nonatomic, weak)   UIScrollView *scrollViewContainer;
@property (nonatomic, weak)   UIView*                     maskView;
@property (nonatomic, weak)   UIPageControl*              pageControl;
@property (nonatomic, strong) NSArray*                    thumbList;
@property (nonatomic, strong) NSArray*                    photoList;
@property (nonatomic, strong) NSArray*                    oldFrameList;
@property (nonatomic, assign) NSInteger                   curPage;
@property (nonatomic, assign) NSInteger                   totalPage;
//@property (nonatomic, weak)   MBProgressHUD*              hud;

- (void)refreshScrollView;
- (void)refreshScrollViewWithoutIndex:(NSInteger)index;
- (NSInteger)getPageIndex:(NSInteger)index;
- (NSArray *)getDisplayImagesWithPageIndex:(NSInteger)index;
- (NSArray *)getDisplayImageUrlsPageIndex:(NSInteger)index;
- (NSArray *)getDisplayOldFramePageIndex:(NSInteger)index;

- (void) showAnimationWithbSuccess:(BOOL)bSuccess;
- (void) addTap;

@end

@implementation RDPhotoView

- (instancetype)initWithImageUrlList:(NSArray *)imageUrlList imageViews:(NSArray *)imageViews index:(NSInteger)index
{
    if (self = [self init]) {
        self.backgroundColor = [UIColor clearColor];
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        
        __unused UIView *maskView = ({
            UIView *maskView = [[UIView alloc] initWithFrame:window.bounds];
            maskView.backgroundColor = [UIColor blackColor];
            maskView.alpha = 0.0;
            [self addSubview:maskView];
            _maskView = maskView;
            maskView;
        });
        
        UIScrollView *scrollViewContainer = ({
            UIScrollView *scrollViewContainer = [[UIScrollView alloc] initWithFrame:self.bounds];
            scrollViewContainer.delegate = self;
            scrollViewContainer.pagingEnabled = YES;
            scrollViewContainer.showsHorizontalScrollIndicator = NO;
            scrollViewContainer.showsVerticalScrollIndicator = NO;
            scrollViewContainer.userInteractionEnabled = NO;
            scrollViewContainer.contentSize = CGSizeMake(3 * self.bounds.size.width, self.bounds.size.height);
            [self addSubview:scrollViewContainer];
            _scrollViewContainer = scrollViewContainer;
            scrollViewContainer;
        });
        
        NSMutableArray *mutaThumb = [NSMutableArray new];
        NSMutableArray *mutaFrame = [NSMutableArray new];
        NSMutableArray *mutaPhoto = [NSMutableArray new];
        
        for (int i = 0; i < imageUrlList.count; i ++) {
            UIImageView *imageView = imageViews[i];
            CGRect oldframe =[imageView convertRect:imageView.bounds toView:window];
            NSValue *frameValue = [NSValue valueWithCGRect:oldframe];
            UIImage *thumbImage = imageView.image;
            NSString *url = imageUrlList[i];
            [mutaThumb addObject:thumbImage];
            [mutaFrame addObject:frameValue];
            [mutaPhoto addObject:url];
        }

        _totalPage = imageUrlList.count;
        _curPage = index + 1;
        _thumbList = mutaThumb;
        _oldFrameList = mutaFrame;
        _photoList = mutaPhoto;
        
        for (int i = 0; i < 3; i ++) {
            RDImageScrollView *sc = [[RDImageScrollView alloc] initWithFrame:(CGRect){i*window.bounds.size.width,0,window.bounds.size}];
            sc.tag = kScrollViewStartTag + i;
            [scrollViewContainer addSubview:sc];
        }

        __unused UIPageControl* pageControl = ({
            UIPageControl* pageControl = [UIPageControl new];
            [self addSubview:pageControl];
            _pageControl = pageControl;
            _pageControl.numberOfPages = imageUrlList.count;
            _pageControl.currentPage = index;
            
            [pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(self).with.offset(-20);
                make.centerX.equalTo(self);
            }];
            
            if (imageUrlList.count == 1) {
                pageControl.hidden = YES;
                scrollViewContainer.contentSize = window.bounds.size;
            }
            
            pageControl;
        });

        self.scrollViewContainer.contentOffset = CGPointMake(self.scrollViewContainer.frame.size.width, 0);
        self.pageControl.currentPage = self.curPage - 1;
        [self refreshScrollViewWithoutIndex:1];
        
    }
    return self;
}

- (void)showAnimationWithbSuccess:(BOOL)bSuccess
{
    RDImageScrollView *scrollView1 = [self.scrollViewContainer viewWithTag:kScrollViewStartTag + 1];
    [UIView animateWithDuration:.4 animations:^{
        if (bSuccess) {
            [scrollView1 setAnimationRect];
        }
        self.maskView.alpha = 1.0;
    } completion:^(BOOL finished) {
        [self addTap];
    }];
}

- (void) addTap
{
    self.scrollViewContainer.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap= [UITapGestureRecognizer new];
    @weakify(self);
    [tap.rac_gestureSignal subscribeNext:^(id x) {
        @strongify(self);
        self.scrollViewContainer.userInteractionEnabled = NO;
        RDImageScrollView *curScrollView = [self.scrollViewContainer viewWithTag:kScrollViewStartTag + 1];
        [UIView animateWithDuration:.5 animations:^{
            self.maskView.alpha = 0;
            [curScrollView rechangeInitRect];
        } completion:^(BOOL finished) {
            [self close];
        }];
    }];
    tap.numberOfTouchesRequired = 1; //手指数
    tap.numberOfTapsRequired = 1; //tap次数
    
    [self.scrollViewContainer addGestureRecognizer:tap];
}

- (void)show
{
    [super show];
    NSArray *curImages = [self getDisplayImagesWithPageIndex:self.curPage];
    NSArray *curImageUrl = [self getDisplayImageUrlsPageIndex:self.curPage];
    RDImageScrollView *scrollView1 = [self.scrollViewContainer viewWithTag:kScrollViewStartTag + 1];
    __block BOOL bshow = YES;
    [scrollView1.imageView sd_setImageWithURL:[NSURL URLWithString:curImageUrl[1]]
                             placeholderImage:curImages[1]
                                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL)
    {
        if (error) {
            [self showAnimationWithbSuccess:NO];
            if (!self.hud) {
                self.hud = [RDLoadingIndicatorHUD showHUDAddedTo:self animated:YES];
            }
            [self.hud hide:YES];
        }else
        {
            [self showAnimationWithbSuccess:YES];
            bshow = NO;
            [self.hud hide:YES];
        }
    }];
    
    if (!self.hud && bshow) {
        self.hud = [RDLoadingIndicatorHUD showHUDAddedTo:self animated:YES];
        self.maskView.alpha = 1.0;
        scrollView1.imageView.center = self.scrollViewContainer.center;
    }
    
}

- (void)refreshScrollViewWithoutIndex:(NSInteger)index
{
    NSArray *curImages = [self getDisplayImagesWithPageIndex:self.curPage];
    NSArray *curImageUrl = [self getDisplayImageUrlsPageIndex:self.curPage];
    NSArray *curFrames = [self getDisplayOldFramePageIndex:self.curPage];
    
    for (NSInteger i = 0; i < 3; i++)
    {
        RDImageScrollView *scrollView = (RDImageScrollView *)[self.scrollViewContainer viewWithTag:kScrollViewStartTag + i];
        scrollView.zoomScale = 1;
      
        UIImageView *imageView = scrollView.imageView;
        
        //滑动不用重设
        [scrollView setContentWithFrame:[curFrames[i] CGRectValue] bResetFrame:index != -1];
        
        [scrollView setImage:curImages[i]];

        [imageView sd_setImageWithURL:[NSURL URLWithString:curImageUrl[i]]
                     placeholderImage:curImages[i]
                            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL)
        {
            
            if (error) {
                imageView.center = self.scrollViewContainer.center;
            }else
            {
                if (index != i) {
                    [scrollView setAnimationRect];
                }
            }

        }];
    }
    
    self.scrollViewContainer.contentOffset = CGPointMake(self.scrollViewContainer.frame.size.width, 0);
    self.pageControl.currentPage = self.curPage - 1;
}

- (void)refreshScrollView
{
    [self refreshScrollViewWithoutIndex:-1];
}

- (NSInteger)getPageIndex:(NSInteger)index
{
    // value＝1为第一张，value = 0为前面一张
    if (index == 0)
    {
        index = self.totalPage;
    }
    
    if (index == self.totalPage + 1)
    {
        index = 1;
    }
    
    return index;
}

- (NSArray *)getDisplayImagesWithPageIndex:(NSInteger)index
{
    NSInteger pre = [self getPageIndex:self.curPage-1];
    NSInteger last = [self getPageIndex:self.curPage+1];
    
    NSMutableArray *images = [NSMutableArray new];
    
    [images addObject:[self.thumbList objectAtIndex:pre-1]];
    [images addObject:[self.thumbList objectAtIndex:self.curPage-1]];
    [images addObject:[self.thumbList objectAtIndex:last-1]];
    
    return images;
}

- (NSArray *)getDisplayImageUrlsPageIndex:(NSInteger)index
{
    NSInteger pre = [self getPageIndex:self.curPage-1];
    NSInteger last = [self getPageIndex:self.curPage+1];
    
    NSMutableArray *imageUrls = [NSMutableArray new];
    
    [imageUrls addObject:[self.photoList objectAtIndex:pre-1]];
    [imageUrls addObject:[self.photoList objectAtIndex:self.curPage-1]];
    [imageUrls addObject:[self.photoList objectAtIndex:last-1]];
    
    return imageUrls;
}

- (NSArray *)getDisplayOldFramePageIndex:(NSInteger)index
{
    NSInteger pre = [self getPageIndex:self.curPage-1];
    NSInteger last = [self getPageIndex:self.curPage+1];
    
    NSMutableArray *frameList = [NSMutableArray new];
    
    [frameList addObject:[self.oldFrameList objectAtIndex:pre-1]];
    [frameList addObject:[self.oldFrameList objectAtIndex:self.curPage-1]];
    [frameList addObject:[self.oldFrameList objectAtIndex:last-1]];
    
    return frameList;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return [scrollView viewWithTag:kImageViewStartTag];
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
    
    if (aScrollView != self.scrollViewContainer) {
        return;
    }
    
    NSInteger x = aScrollView.contentOffset.x;
    //NSInteger y = aScrollView.contentOffset.y;
    
    // 往下翻一张
    if (x >= 2 * self.scrollViewContainer.frame.size.width)
    {
        self.curPage = [self getPageIndex:self.curPage+1];
        [self refreshScrollView];
    }
    
    if (x <= 0)
    {
        self.curPage = [self getPageIndex:self.curPage-1];
        [self refreshScrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView
{
    //NSInteger x = aScrollView.contentOffset.x;
    //NSInteger y = aScrollView.contentOffset.y;
    
    //NSLog(@"--end  x=%d  y=%d", x, y);
    
    // 水平滚动
    if (aScrollView != self.scrollViewContainer) {
        return;
    }
    self.scrollViewContainer.contentOffset = CGPointMake(self.scrollViewContainer.frame.size.width, 0);
    
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
