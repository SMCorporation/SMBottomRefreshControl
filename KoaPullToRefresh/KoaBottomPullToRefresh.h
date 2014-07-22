//
//  KoaPullToRefresh.h
//  KoaPullToRefresh
//
//  Created by Sergi Gracia on 09/05/13.
//  Copyright (c) 2013 Sergi Gracia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AvailabilityMacros.h>
#import "NSString+FontAwesome.h"
#import "UIFont+FontAwesome.h"

@class KoaBottomPullToRefresh;

@interface UIScrollView (KoaPullToRefresh)

- (void)addBottomPullToRefreshWithActionHandler:(void (^)(void))actionHandler;
- (void)addBottomPullToRefreshWithActionHandler:(void (^)(void))actionHandler
                                backgroundColor:(UIColor *)customBackgroundColor;

- (void)addBottomPullToRefreshWithActionHandler:(void (^)(void))actionHandler
                                backgroundColor:(UIColor *)customBackgroundColor
                      pullToRefreshHeightShowed:(CGFloat)pullToRefreshHeightShowed;

- (void)addBottomPullToRefreshWithActionHandler:(void (^)(void))actionHandler
                                backgroundColor:(UIColor *)customBackgroundColor
                            pullToRefreshHeight:(CGFloat)pullToRefreshHeight
                      pullToRefreshHeightShowed:(CGFloat)pullToRefreshHeightShowed;



@property (nonatomic, strong) KoaBottomPullToRefresh *bottomPullToRefreshView;
@property (nonatomic, assign) BOOL showsBottomPullToRefresh;

- (void)relocateBottomPullToRefresh;

@end

enum {
    KoaBottomPullToRefreshStateStopped = 0,
    KoaBottomPullToRefreshStateTriggered,
    KoaBottomPullToRefreshStateLoading,
    KoaBottomPullToRefreshStateAll = 10
};

typedef NSUInteger KoaBottomPullToRefreshState;


@interface KoaBottomPullToRefresh : UIView

@property (nonatomic, strong) UIColor *arrowColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIFont *textFont;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *loaderLabel;
@property (nonatomic, strong, readonly) NSString *fontAwesomeIcon;
@property (nonatomic, readonly) KoaBottomPullToRefreshState state;
@property (nonatomic, assign) BOOL disable;

- (void)setTitle:(NSString *)title forState:(KoaBottomPullToRefreshState)state;
- (void)setFontAwesomeIcon:(NSString *)fontAwesomeIcon;
- (void)stopAnimating;

@end
