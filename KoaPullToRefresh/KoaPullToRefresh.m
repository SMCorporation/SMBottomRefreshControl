//
//  KoaPullToRefresh.m
//  KoaPullToRefresh
//
//  Created by Sergi Gracia on 09/05/13.
//  Copyright (c) 2013 Sergi Gracia. All rights reserved.
//

#import "KoaPullToRefresh.h"
#import <QuartzCore/QuartzCore.h>

#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)
#define fequalzero(a) (fabs(a) < FLT_EPSILON)

static CGFloat KoaPullToRefreshViewHeight = 82;
static CGFloat KoaPullToRefreshViewHeightShowed = 0;
static CGFloat KoaPullToRefreshViewTitleBottomMargin = 12;

@interface KoaPullToRefreshView ()

@property (nonatomic, copy) void (^pullToRefreshActionHandler)(void);
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UILabel *loaderLabel;
@property (nonatomic, readwrite) KoaPullToRefreshState state;
@property (nonatomic, strong) NSMutableArray *titles;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalTopInset;
@property (nonatomic, readwrite) CGFloat originalBottomInset;
@property (nonatomic, assign) BOOL wasTriggeredByUser;
@property (nonatomic, assign) BOOL showsPullToRefresh;
@property (nonatomic, assign) BOOL isObserving;
@property (nonatomic, assign) BOOL programmaticallyLoading;
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
                        pullToRefreshHeightShowed:KoaPullToRefreshViewHeightShowed];
}

- (void)addBottomPullToRefreshWithActionHandler:(void (^)(void))actionHandler
                                backgroundColor:(UIColor *)customBackgroundColor
                      pullToRefreshHeightShowed:(CGFloat)pullToRefreshHeightShowed
{
    [self addBottomPullToRefreshWithActionHandler:actionHandler
                                  backgroundColor:customBackgroundColor
                              pullToRefreshHeight:KoaPullToRefreshViewHeight
                        pullToRefreshHeightShowed:KoaPullToRefreshViewHeightShowed];
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
    KoaPullToRefreshViewHeight = pullToRefreshHeight;
    KoaPullToRefreshViewHeightShowed = pullToRefreshHeightShowed;
    KoaPullToRefreshViewTitleBottomMargin += pullToRefreshHeightShowed;
    
    if (!self.bottomPullToRefreshView) {
        
        //Initial y position
        CGFloat yOrigin = self.contentSize.height;
        
        //Put background extra to fill top white space
        UIView *backgroundExtra = [[UIView alloc] initWithFrame:CGRectMake(0, yOrigin*8, self.bounds.size.width, KoaPullToRefreshViewHeight*8)];
        [backgroundExtra setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [backgroundExtra setBackgroundColor:customBackgroundColor];
        
        //Init pull to refresh view
        KoaPullToRefreshView *view = [[KoaPullToRefreshView alloc] initWithFrame:CGRectMake(0, yOrigin, self.bounds.size.width, KoaPullToRefreshViewHeight + KoaPullToRefreshViewHeightShowed)];
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

- (void)setBottomPullToRefreshView:(KoaPullToRefreshView *)bottomPullToRefreshView {
    [self willChangeValueForKey:@"KoaPullToRefreshView"];
    objc_setAssociatedObject(self, &UIScrollViewPullToRefreshView,
                             bottomPullToRefreshView,
                             OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"KoaPullToRefreshView"];
}

- (KoaPullToRefreshView *)bottomPullToRefreshView {
    return objc_getAssociatedObject(self, &UIScrollViewPullToRefreshView);
}

- (void)setShowsBottomPullToRefresh:(BOOL)showsBottomPullToRefresh {
    self.bottomPullToRefreshView.hidden = !showsBottomPullToRefresh;
    
    if(!showsBottomPullToRefresh) {
        if (self.bottomPullToRefreshView.isObserving) {
            [self removeObserver:self.bottomPullToRefreshView forKeyPath:@"contentOffset"];
            [self removeObserver:self.bottomPullToRefreshView forKeyPath:@"frame"];
            [self.bottomPullToRefreshView resetScrollViewContentInset];
            self.bottomPullToRefreshView.isObserving = NO;
        }
    }else {
        if (!self.bottomPullToRefreshView.isObserving) {
            [self addObserver:self.bottomPullToRefreshView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.bottomPullToRefreshView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.bottomPullToRefreshView forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
            self.bottomPullToRefreshView.isObserving = YES;
            
            CGFloat yOrigin = self.contentSize.height;
            self.bottomPullToRefreshView.frame = CGRectMake(0, yOrigin, self.bounds.size.width, KoaPullToRefreshViewHeight + KoaPullToRefreshViewHeightShowed);
        }
    }
}

- (BOOL)showsBottomPullToRefresh {
    return !self.bottomPullToRefreshView.hidden;
}

@end


#pragma mark - KoaPullToRefresh
@implementation KoaPullToRefreshView

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
        self.state = KoaPullToRefreshStateStopped;
        [self.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [self.loaderLabel setTextAlignment:NSTextAlignmentLeft];
        
        self.titles = [NSMutableArray arrayWithObjects: NSLocalizedString(@"Pull",),
                                                        NSLocalizedString(@"Release",),
                                                        NSLocalizedString(@"Loading",),
                                                        nil];
        
        self.wasTriggeredByUser = YES;
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (self.superview && newSuperview == nil) {
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        if (scrollView.showsBottomPullToRefresh) {
            if (self.isObserving) {
                //If enter this branch, it is the moment just before "KoaPullToRefreshView's dealloc", so remove observer here
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
    CGFloat titleY = KoaPullToRefreshViewHeight - KoaPullToRefreshViewHeightShowed - titleSize.height - KoaPullToRefreshViewTitleBottomMargin;
    
    //Set state of loader label
    switch (self.state) {
        case KoaPullToRefreshStateStopped: {
                [self.loaderLabel setAlpha:0];
                [self.loaderLabel setFrame:CGRectMake(self.frame.size.width/2 - self.loaderLabel.frame.size.width/2,
                                                      titleY + 100,
                                                      self.loaderLabel.frame.size.width,
                                                      self.loaderLabel.frame.size.height)];
                
                self.titleLabel.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2 - 3);
        }
            break;
            
        case KoaPullToRefreshStateLoading: {
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

    if (self.scrollView.contentOffset.y < -self.offsetY && self.programmaticallyLoading) {
        self.scrollView.contentOffset = CGPointMake(0, -self.offsetY);
    }
    
    
    if([keyPath isEqualToString:@"contentOffset"]) {
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    }
    else if([keyPath isEqualToString:@"contentSize"]) {
        [self layoutSubviews];
        
        CGFloat yOrigin;
        yOrigin = self.scrollView.contentSize.height;
        self.frame = CGRectMake(0, yOrigin, self.bounds.size.width, KoaPullToRefreshViewHeight);
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
    [self.titleLabel setAlpha: ((contentOffset.y * 1) / KoaPullToRefreshViewHeight) - 0.1];
    
    if(self.state != KoaPullToRefreshStateLoading) {
        CGFloat scrollOffsetThreshold;
        scrollOffsetThreshold = self.frame.origin.y-self.originalTopInset;
        
        if(!self.scrollView.isDragging && self.state == KoaPullToRefreshStateTriggered)
            self.state = KoaPullToRefreshStateLoading;
        else if(contentOffset.y < scrollOffsetThreshold && self.scrollView.isDragging && self.state == KoaPullToRefreshStateStopped)
            self.state = KoaPullToRefreshStateTriggered;
        else if(contentOffset.y >= scrollOffsetThreshold && self.state != KoaPullToRefreshStateStopped)
            self.state = KoaPullToRefreshStateStopped;
    } else {
        CGFloat offset;
        UIEdgeInsets contentInset;
        offset = MAX(self.scrollView.contentOffset.y * -1, 0.0f);
        offset = MIN(offset, self.originalTopInset + self.bounds.size.height);
        contentInset = self.scrollView.contentInset;
        self.scrollView.contentInset = UIEdgeInsetsMake(contentInset.top, contentInset.left, contentInset.bottom, contentInset.right);
    }
    
    //Set content offset for special cases
    if(self.state != KoaPullToRefreshStateLoading) {
        if (self.scrollView.contentOffset.y > self.scrollView.contentSize.height && self.scrollView.contentOffset.y > 0) {
            [self.scrollView setContentInset:UIEdgeInsetsMake(self.scrollView.contentInset.top,
                                                              self.scrollView.contentInset.left,
                                                              abs(self.scrollView.contentSize.height),
                                                              self.scrollView.contentInset.right)];
        } else if(self.scrollView.contentOffset.y < self.scrollView.contentSize.height) {
            [self.scrollView setContentInset:UIEdgeInsetsZero];
        } else {
            [self.scrollView setContentInset:UIEdgeInsetsMake(self.scrollView.contentInset.top, self.scrollView.contentInset.left, self.frame.size.height, self.scrollView.contentInset.right)];
        }
    }
    self.wasTriggeredByUser = YES;
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

- (void)setTitle:(NSString *)title forState:(KoaPullToRefreshState)state {
    if(!title) {
        title = @"";
    }
    
    if(state == KoaPullToRefreshStateAll) {
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
    self.state = KoaPullToRefreshStateStopped;

//    if(self.scrollView.contentOffset.y < -self.originalTopInset) {
//        [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -self.originalTopInset) animated:YES];
//    }
}

- (void)setState:(KoaPullToRefreshState)newState {
    
    if(_state == newState) {
        return;
    }
    
    KoaPullToRefreshState previousState = _state;
    _state = newState;
    
    [self setNeedsLayout];
    
    switch (newState) {
        case KoaPullToRefreshStateStopped:
            [self stopRotatingIcon];
            [self resetScrollViewContentInset];
            self.wasTriggeredByUser = YES;
            break;
            
        case KoaPullToRefreshStateTriggered:
            break;
            
        case KoaPullToRefreshStateLoading:
            [self startRotatingIcon];
            [self setScrollViewContentInsetForLoading];
            
            if(previousState == KoaPullToRefreshStateTriggered && pullToRefreshActionHandler) {
                pullToRefreshActionHandler();
            }
            
            break;
    }
}


- (void)startRotatingIcon {
    CABasicAnimation *rotation;
    rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotation.fromValue = [NSNumber numberWithFloat:0];
    rotation.toValue = [NSNumber numberWithFloat:(2*M_PI)];
    rotation.duration = 1.2;
    rotation.repeatCount = HUGE_VALF;
    [self.loaderLabel.layer addAnimation:rotation forKey:@"Spin"];
}

- (void)stopRotatingIcon {
    self.programmaticallyLoading = NO;
    [self.loaderLabel.layer removeAnimationForKey:@"Spin"];
}

@end
