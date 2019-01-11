//
//  MDCTabBarPageViewController.h
//  Pods
//
//  Created by Xuzixiang on 2019/1/10.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "MDCTabBar.h"

@interface UIViewController (TZPopGesture)

/// 给view添加侧滑返回效果
- (void)tz_addPopGestureToView:(UIView *)view;

/// 禁止该页面的侧滑返回
@property (nonatomic, assign) BOOL tz_interactivePopDisabled;

@end

@protocol MDCTabBarPageControllerDelegate;

IB_DESIGNABLE
@interface MDCTabBarPageViewController
    : UIViewController <MDCTabBarDelegate, UIBarPositioningDelegate>

@property (nonatomic, weak, nullable) id<MDCTabBarPageControllerDelegate> delegate;
@property (nonatomic, nonnull, copy) NSArray<UIViewController *> *viewControllers;
@property (nonatomic, weak, nullable) UIViewController *selectedViewController;
@property (nonatomic, readonly, nullable) MDCTabBar *tabBar;
@property (nonatomic, assign) UIBarPosition tabBarPosition;

@property (nonatomic) BOOL tabBarHidden;
- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated;

@end

/** The delegate protocol for MDCTabBarViewController */
@protocol MDCTabBarPageControllerDelegate <NSObject>
@optional

/**
 Called when the user taps on a tab bar item. Not called for programmatic selection.
 
 If you provide this method, you can control whether tapping on a tab bar item actually
 switches to that viewController. If not provided, MDCTabBarViewController will always switch.
 
 @note The tab bar controller will call this method even when the tapped tab bar
 item is the currently-selected tab bar item.
 
 You can also use this method as a willSelectViewController.
 */
- (BOOL)tabBarController:(nonnull MDCTabBarPageViewController *)tabBarController
shouldSelectViewController:(nonnull UIViewController *)viewController;

/**
 Called when the user taps on a tab bar item. Not called for programmatic selection.
 MDCTabBarViewController will call your delegate once it has responded to the user's tap
 by changing the selected view controller.
 
 @note The tab bar controller will call this method even when the tapped tab bar
 item is the currently-selected tab bar item.
 */
- (void)tabBarController:(nonnull MDCTabBarPageViewController *)tabBarController
 didSelectViewController:(nonnull UIViewController *)viewController;

@end

