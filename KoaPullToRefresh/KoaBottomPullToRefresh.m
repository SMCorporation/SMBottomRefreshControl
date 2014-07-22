//
//  KoaPullToRefresh.m
//  KoaPullToRefresh
//
//  Created by Sergi Gracia on 09/05/13.
//  Copyright (c) 2013 Sergi Gracia. All rights reserved.
//

#import "KoaBottomPullToRefresh.h"
#import <QuartzCore/QuartzCore.h>

#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)
#define fequalzero(a) (fabs(a) < FLT_EPSILON)

static CGFloat KoaBottomPullToRefreshHeight = 82;
static CGFloat KoaBottomPullToRefreshHeightShowed = 0;
static CGFloat KoaBottomPullToRefreshTitleBottomMargin = 12;

@interface KoaBottomPullToRefresh ()

@property (nonatomic, copy) void (^pullToRefreshActionHandler)(void);
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UILabel *loaderLabel;
@property (nonatomic, readwrite) KoaBottomPullToRefreshState state;
@property (nonatomic, strong) NSMutableArray *titles;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalTopInset;
@property (nonatomic, readwrite) CGFloat originalBottomInset;
@property (nonatomic, assign) BOOL showsPullToRefresh;
@property (nonatomic, assign) BOOL isObserving;
@property (nonatomic, assign) CGFloat offsetY;


- (void)resetScrollViewContentInset;
- (void)setScrollViewContentInsetForLoading;
- (void)setScrollViewContentInset:(UIEdgeInsets)insets;

@end

#pragma mark - UIScrollView (KoaPullToRefresh)
#import <objc/runtime.h>

static char UIScrollViewPullToRefreshView;

@implementation UIScrollView (KoaPullToRefresh)
@dynamic bottomPullToRefreshView, showsBottomPullToRefresh;


- (void)addBottomPullToRefreshWithActionHandler:(void (^)(void))actionHandler
{
    [self addBottomPullToRefreshWithActionHandler:actionHandler backgroundColor:[UIColor grayColor]];
}

- (void)addBottomPullToRefreshWithActionHandler:(void (^)(void))actionHandler
                          backgroundColor:(UIColor *)customBackgroundColor
{
    [self addBottomPullToRefreshWithActionHandler:actionHandler
                                  backgroundColor:customBackgroundColor
                        pullToRefreshHeightShowed:KoaBottomPullToRefreshHeightShowed];
}

- (void)addBottomPullToRefreshWithActionHandler:(void (^)(void))actionHandler
                                backgroundColor:(UIColor *)customBackgroundColor
                      pullToRefreshHeightShowed:(CGFloat)pullToRefreshHeightShowed
{
    [self addBottomPullToRefreshWithActionHandler:actionHandler
                                  backgroundColor:customBackgroundColor
                              pullToRefreshHeight:KoaBottomPullToRefreshHeight
                        pullToRefreshHeightShowed:KoaBottomPullToRefreshHeightShowed];
}

- (void)addBottomPullToRefreshWithActionHandler:(void (^)(void))actionHandler
                          backgroundColor:(UIColor *)customBackgroundColor
                      pullToRefreshHeight:(CGFloat)pullToRefreshHeight
                pullToRefreshHeightShowed:(CGFloat)pullToRefreshHeightShowed
{
    [self addBottomPullToRefreshWithActionHandler:actionHandler
                                  backgroundColor:customBackgroundColor
                              pullToRefreshHeight:pullToRefreshHeight
                        pullToRefreshHeightShowed:pullToRefreshHeightShowed
                      programmingAnimationOffestY:0];
}

- (void)addBottomPullToRefreshWithActionHandler:(void (^)(void))actionHandler
                          backgroundColor:(UIColor *)customBackgroundColor
                      pullToRefreshHeight:(CGFloat)pullToRefreshHeight
                pullToRefreshHeightShowed:(CGFloat)pullToRefreshHeightShowed
              programmingAnimationOffestY:(CGFloat)programmingAnimationOffestY
{
    self.bottomPullToRefreshView.offsetY = programmingAnimationOffestY;
    KoaBottomPullToRefreshHeight = pullToRefreshHeight;
    KoaBottomPullToRefreshHeightShowed = pullToRefreshHeightShowed;
    KoaBottomPullToRefreshTitleBottomMargin += pullToRefreshHeightShowed;
    
    if (!self.bottomPullToRefreshView) {
        
        //Initial y position
        CGFloat yOrigin = (self.contentSize.height < self.frame.size.height) ? self.frame.size.height : self.contentSize.height;
        
        //Put background extra to fill top white space
        UIView *backgroundExtra = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, KoaBottomPullToRefreshHeight*8)];
        [backgroundExtra setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [backgroundExtra setBackgroundColor:customBackgroundColor];
        
        //Init pull to refresh view
        KoaBottomPullToRefresh *view = [[KoaBottomPullToRefresh alloc] initWithFrame:CGRectMake(0, yOrigin, self.bounds.size.width, KoaBottomPullToRefreshHeight + KoaBottomPullToRefreshHeightShowed)];
        view.pullToRefreshActionHandler = actionHandler;
        view.scrollView = self;
        view.backgroundColor = customBackgroundColor;
        [self addSubview:view];
        
        view.originalTopInset = self.contentInset.top;
        view.originalBottomInset = self.contentInset.bottom;
        
        self.bottomPullToRefreshView = view;
        self.showsBottomPullToRefresh = YES;
        
        [view addSubview:backgroundExtra];
        [view sendSubviewToBack:backgroundExtra];
    }
}

- (void)setBottomPullToRefreshView:(KoaBottomPullToRefresh *)bottomPullToRefreshView {
    [self willChangeValueForKey:@"KoaBottomPullToRefresh"];
    objc_setAssociatedObject(self, &UIScrollViewPullToRefreshView,
                             bottomPullToRefreshView,
                             OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"KoaBottomPullToRefresh"];
}

- (KoaBottomPullToRefresh *)bottomPullToRefreshView {
    return objc_getAssociatedObject(self, &UIScrollViewPullToRefreshView);
}

- (void)setShowsBottomPullToRefresh:(BOOL)showsBottomPullToRefresh
{
    self.bottomPullToRefreshView.hidden = !showsBottomPullToRefresh;
    
    if (!showsBottomPullToRefresh) {
        if (self.bottomPullToRefreshView.isObserving) {
            [self removeObserver:self.bottomPullToRefreshView forKeyPath:@"contentOffset"];
            [self removeObserver:self.bottomPullToRefreshView forKeyPath:@"frame"];
            [self.bottomPullToRefreshView resetScrollViewContentInset];
            self.bottomPullToRefreshView.isObserving = NO;
        }
    } else {
        if (!self.bottomPullToRefreshView.isObserving) {
            [self addObserver:self.bottomPullToRefreshView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.bottomPullToRefreshView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.bottomPullToRefreshView forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
            self.bottomPullToRefreshView.isObserving = YES;
        }
        
        CGFloat yOrigin = (self.contentSize.height < self.frame.size.height) ? self.frame.size.height : self.contentSize.height;
        self.bottomPullToRefreshView.frame = CGRectMake(0, yOrigin, self.bounds.size.width, KoaBottomPullToRefreshHeight + KoaBottomPullToRefreshHeightShowed);
    }
}

- (BOOL)showsBottomPullToRefresh {
    return !self.bottomPullToRefreshView.hidden;
}

- (void)relocateBottomPullToRefresh
{
    [self setShowsBottomPullToRefresh:YES];
}

@end


#pragma mark - KoaPullToRefresh
@implementation KoaBottomPullToRefresh

@synthesize pullToRefreshActionHandler, arrowColor, textColor, textFont;
@synthesize state = _state;
@synthesize scrollView = _scrollView;
@synthesize showsPullToRefresh = _showsPullToRefresh;
@synthesize titleLabel = _titleLabel;
@synthesize loaderLabel = _loaderLabel;
@synthesize fontAwesomeIcon = _fontAwesomeIcon;

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        
        // default styling values
        self.textColor = [UIColor darkGrayColor];
        self.backgroundColor = [UIColor whiteColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.state = KoaBottomPullToRefreshStateStopped;
        [self.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [self.loaderLabel setTextAlignment:NSTextAlignmentLeft];
        
        self.titles = [NSMutableArray arrayWithObjects: NSLocalizedString(@"Pull",),
                                                        NSLocalizedString(@"Release",),
                                                        NSLocalizedString(@"Loading",),
                                                        nil];
        
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (self.superview && newSuperview == nil) {
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        if (scrollView.showsBottomPullToRefresh) {
            if (self.isObserving) {
                //If enter this branch, it is the moment just before "KoaBottomPullToRefresh's dealloc", so remove observer here
                [scrollView removeObserver:self forKeyPath:@"contentOffset"];
                [scrollView removeObserver:self forKeyPath:@"contentSize"];
                [scrollView removeObserver:self forKeyPath:@"frame"];
                self.isObserving = NO;
            }
        }
    }
}

- (void)layoutSubviews
{
    CGFloat leftViewWidth = 60;
    CGFloat margin = 10;
    CGFloat labelMaxWidth = self.bounds.size.width - margin - leftViewWidth;
    
    //Set title text
    self.titleLabel.text = [self.titles objectAtIndex:self.state];
    
    //Set title frame
    CGSize titleSize = [self.titleLabel.text sizeWithFont:self.titleLabel.font constrainedToSize:CGSizeMake(labelMaxWidth,self.titleLabel.font.lineHeight) lineBreakMode:self.titleLabel.lineBreakMode];
    CGFloat titleY = KoaBottomPullToRefreshHeight - KoaBottomPullToRefreshHeightShowed - titleSize.height - KoaBottomPullToRefreshTitleBottomMargin;
    
    //Set state of loader label
    switch (self.state) {
        case KoaBottomPullToRefreshStateStopped: {
            [self.loaderLabel setAlpha:0];
            [self.loaderLabel setFrame:CGRectMake(self.frame.size.width/2 - self.loaderLabel.frame.size.width/2,
                                                  titleY + 100,
                                                  self.loaderLabel.frame.size.width,
                                                  self.loaderLabel.frame.size.height)];
                
            self.titleLabel.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2 - 3);
        }
            break;
            
        case KoaBottomPullToRefreshStateLoading: {
            self.titleLabel.center = CGPointMake(self.frame.size.width / 2, titleY + 7);
            
            [self.loaderLabel setAlpha:1];
            [self.loaderLabel setFrame:CGRectMake(self.frame.size.width/2 - self.loaderLabel.frame.size.width/2,
                                                  titleY - 32,
                                                  self.loaderLabel.frame.size.width,
                                                  self.loaderLabel.frame.size.height)];
        }
            break;
    }
}

#pragma mark - Scroll View

- (void)resetScrollViewContentInset
{
    if (self.disable) {
        return;
    }
    
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.bottom = self.originalTopInset;
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInsetForLoading {
    if (self.disable) {
        return;
    }
    
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.bottom = self.frame.size.height;
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset {
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.scrollView.contentInset = contentInset;
                     }
                     completion:NULL];
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self.disable) {
        return;
    }

    if([keyPath isEqualToString:@"contentOffset"]) {
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    }
    else if([keyPath isEqualToString:@"contentSize"]) {
        [self layoutSubviews];

        CGFloat yOrigin = (self.scrollView.contentSize.height < self.frame.size.height) ? self.frame.size.height : self.scrollView.contentSize.height;
        self.frame = CGRectMake(0, yOrigin, self.bounds.size.width, KoaBottomPullToRefreshHeight);
    }
    else if([keyPath isEqualToString:@"frame"]) {
        [self layoutSubviews];
    }
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset
{
    if (self.disable) {
        return;
    }
    
    //Change title label alpha
    [self.titleLabel setAlpha: ((contentOffset.y * 1) / KoaBottomPullToRefreshHeight) - 0.1];
    CGFloat yOrigin = (self.scrollView.contentSize.height < self.frame.size.height) ? self.frame.size.height : self.scrollView.contentSize.height;
    CGFloat offsetForTriggeredCompare = (yOrigin - self.scrollView.frame.size.height) + self.frame.size.height * 0.7;
    
    if (self.state != KoaBottomPullToRefreshStateLoading) {
        
        if (!self.scrollView.isDragging && self.state == KoaBottomPullToRefreshStateTriggered) {
            self.state = KoaBottomPullToRefreshStateLoading;
        }
        else if (contentOffset.y > offsetForTriggeredCompare && self.scrollView.isDragging && self.state == KoaBottomPullToRefreshStateStopped) {
            self.state = KoaBottomPullToRefreshStateTriggered;
        } else if (contentOffset.y < offsetForTriggeredCompare && self.state == KoaBottomPullToRefreshStateTriggered) {
            self.state = KoaBottomPullToRefreshStateStopped;
        }
    }

    /*
    //Set content offset for special cases
    if(self.state != KoaBottomPullToRefreshStateLoading) {
        if (self.scrollView.contentOffset.y > offsetForTriggeredCompare && self.scrollView.contentOffset.y >= 0) {
//            [self.scrollView setContentInset:UIEdgeInsetsMake(self.scrollView.contentInset.top,
//                                                              self.scrollView.contentInset.left,
//                                                              self.frame.size.height,
//                                                              self.scrollView.contentInset.right)];
        } else if(self.scrollView.contentOffset.y < offsetForTriggeredCompare) {
//            [self.scrollView setContentInset:UIEdgeInsetsZero];
        } else {
//            [self.scrollView setContentInset:UIEdgeInsetsMake(self.scrollView.contentInset.top, self.scrollView.contentInset.left, self.frame.size.height, self.scrollView.contentInset.right)];
        }
    }
     */
}


#pragma mark - Getters

- (UILabel *)titleLabel {
    if(!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 210, 20)];
        _titleLabel.text = NSLocalizedString(@"Pull",);
        _titleLabel.font = [UIFont boldSystemFontOfSize:14];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = textColor;
        [self addSubview:_titleLabel];
    }
    return _titleLabel;
}

- (UILabel *)loaderLabel {
    if(!_loaderLabel) {
        _loaderLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width/2 - 17/2, 0, 17, 17)];
        _loaderLabel.text = [NSString fontAwesomeIconStringForIconIdentifier:self.fontAwesomeIcon];
        _loaderLabel.font = [UIFont fontWithName:kFontAwesomeFamilyName size:20];
        _loaderLabel.backgroundColor = [UIColor clearColor];
        _loaderLabel.textColor = textColor;
        [_loaderLabel sizeToFit];
        [self addSubview:_loaderLabel];
    }
    return _loaderLabel;
}

- (NSString *)fontAwesomeIcon {
    if (!_fontAwesomeIcon) {
        _fontAwesomeIcon = @"icon-refresh";
    }
    return _fontAwesomeIcon;
}

- (UIColor *)textColor {
    return self.titleLabel.textColor;
}

- (UIFont *)textFont {
    return self.titleLabel.font;
}

#pragma mark - Setters

- (void)setTitle:(NSString *)title forState:(KoaBottomPullToRefreshState)state {
    if(!title) {
        title = @"";
    }
    
    if(state == KoaBottomPullToRefreshStateAll) {
        [self.titles replaceObjectsInRange:NSMakeRange(0, 3) withObjectsFromArray:@[title, title, title]];
    } else {
        [self.titles replaceObjectAtIndex:state withObject:title];
    }
    
    [self setNeedsLayout];
}

- (void)setTextColor:(UIColor *)newTextColor {
    textColor = newTextColor;
    self.titleLabel.textColor = newTextColor;
    self.loaderLabel.textColor = newTextColor;
}

- (void)setTextFont:(UIFont *)font
{
    [self.titleLabel setFont:font];
}

- (void)setFontAwesomeIcon:(NSString *)fontAwesomeIcon
{
    _fontAwesomeIcon = fontAwesomeIcon;
    _loaderLabel.text = [NSString fontAwesomeIconStringForIconIdentifier:self.fontAwesomeIcon];
}

#pragma mark -

- (void)stopAnimating
{
    self.state = KoaBottomPullToRefreshStateStopped;
}

- (void)setState:(KoaBottomPullToRefreshState)newState {
    
    if(_state == newState) {
        return;
    }
    
    KoaBottomPullToRefreshState previousState = _state;
    _state = newState;
    
    [self setNeedsLayout];
    
    switch (newState) {
        case KoaBottomPullToRefreshStateStopped:
            [self stopRotatingIcon];
            [self resetScrollViewContentInset];
            break;
            
        case KoaBottomPullToRefreshStateTriggered:
            break;
            
        case KoaBottomPullToRefreshStateLoading:
            [self startRotatingIcon];
            [self setScrollViewContentInsetForLoading];
            
            if(previousState == KoaBottomPullToRefreshStateTriggered && pullToRefreshActionHandler) {
                pullToRefreshActionHandler();
            }
            
            break;
    }
}


- (void)startRotatingIcon
{
    CABasicAnimation *rotation;
    rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotation.fromValue = [NSNumber numberWithFloat:0];
    rotation.toValue = [NSNumber numberWithFloat:(2*M_PI)];
    rotation.duration = 1.2;
    rotation.repeatCount = HUGE_VALF;
    [self.loaderLabel.layer addAnimation:rotation forKey:@"Spin"];
}

- (void)stopRotatingIcon
{
    [self.loaderLabel.layer removeAnimationForKey:@"Spin"];
}

@end
