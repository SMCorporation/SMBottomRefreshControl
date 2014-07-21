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

@class KoaPullToRefreshView;

@interface UIScrollView (KoaPullToRefresh)

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler;
- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler
                          backgroundColor:(UIColor *)customBackgroundColor;

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler
                          backgroundColor:(UIColor *)customBackgroundColor
                pullToRefreshHeightShowed:(CGFloat)pullToRefreshHeightShowed;

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler
                          backgroundColor:(UIColor *)customBackgroundColor
                pullToRefreshHeightShowed:(CGFloat)pullToRefreshHeightShowed;

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler
                          backgroundColor:(UIColor *)customBackgroundColor
                      pullToRefreshHeight:(CGFloat)pullToRefreshHeight
                pullToRefreshHeightShowed:(CGFloat)pullToRefreshHeightShowed;

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler
                          backgroundColor:(UIColor *)customBackgroundColor
                      pullToRefreshHeight:(CGFloat)pullToRefreshHeight
                pullToRefreshHeightShowed:(CGFloat)pullToRefreshHeightShowed
              programmingAnimationOffestY:(CGFloat)programmingAnimationOffestY;


@property (nonatomic, strong) KoaPullToRefreshView *pullToRefreshView;
@property (nonatomic, assign) BOOL showsPullToRefresh;

@end

enum {
    KoaPullToRefreshStateStopped = 0,
    KoaPullToRefreshStateTriggered,
    KoaPullToRefreshStateLoading,
    KoaPullToRefreshStateAll = 10
};

typedef NSUInteger KoaPullToRefreshState;


@interface KoaPullToRefreshView : UIView

@property (nonatomic, strong) UIColor *arrowColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIFont *textFont;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *loaderLabel;
@property (nonatomic, strong, readonly) NSString *fontAwesomeIcon;
@property (nonatomic, readonly) KoaPullToRefreshState state;
@property (nonatomic, assign) BOOL disable;

- (void)setTitle:(NSString *)title forState:(KoaPullToRefreshState)state;
- (void)setFontAwesomeIcon:(NSString *)fontAwesomeIcon;
- (void)stopAnimating;

@end
