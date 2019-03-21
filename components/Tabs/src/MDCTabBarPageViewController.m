// Copyright 2017-present the Material Components for iOS authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "MDCTabBarPageViewController.h"

@interface MDCTabBarPageViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, readwrite, nonnull) MDCTabBar *tabBar;
@property (nonatomic, strong) UIScrollView *contentView;

@end

@implementation MDCTabBarPageViewController {
    /** For showing/hiding, Animation needs to know where it wants to end up. */
    BOOL _tabBarWantsToBeHidden;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    if (self.tabBar) {
        return;
    }
    MDCTabBar *tabBar = [[MDCTabBar alloc] initWithFrame:CGRectZero];
    tabBar.alignment = MDCTabBarAlignmentJustified;
    tabBar.delegate = self;
    self.tabBar = tabBar;

    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.bounces = NO;
    scrollView.delegate = self;
    scrollView.pagingEnabled = YES;
    self.contentView = scrollView;
    self.tabBarPosition = UIBarPositionTop;
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIView *view = self.view;
    view.clipsToBounds = YES;
    view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth
        | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin
        | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [view addSubview:self.contentView];
    [view addSubview:self.tabBar];
    [self updateOldViewControllers:nil to:_viewControllers];
    [self updateOldSelectedViewController:nil to:_selectedViewController];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateLayout];
}

#pragma mark - Properties

- (BOOL)tabBarHidden
{
    return self.tabBar.hidden;
}

- (void)setTabBarHidden:(BOOL)hidden
{
    [self setTabBarHidden:hidden animated:NO];
}

- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (_tabBar.hidden != hidden) {
        if (animated) {
            // Before entering our animation block put the view's layout in a good state.
            [self.view layoutIfNeeded];
        }
        _tabBarWantsToBeHidden = hidden;
        // Hiding the tab bar has the side effect of growing the current viewController to use that
        // space. This does that in its layoutSubViews.
        [self.view setNeedsLayout];
        if (animated) {
            if (!hidden) {
                // If we are showing, set the state before the animation.
                _tabBar.hidden = hidden;
            }
            [UIView animateWithDuration:0.3
                animations:^{ [self.view layoutIfNeeded]; }
                completion:^(__unused BOOL finished) {
                    // If we are hiding, set the state after the animation.
                    self.tabBar.hidden = hidden;
                }];
        } else {
            _tabBar.hidden = hidden;
        }
    }
}

- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers
{
    NSArray<UIViewController *> *oldViewControllers = _viewControllers;
    _viewControllers = [viewControllers copy];
    [self updateOldViewControllers:oldViewControllers to:viewControllers];
}

- (void)updateOldViewControllers:(NSArray<UIViewController *> *)oldViewControllers
                              to:(NSArray<UIViewController *> *)viewControllers
{
    if (!self.isViewLoaded || [oldViewControllers isEqual:viewControllers]) {
        return;
    }

    if (![oldViewControllers isEqual:viewControllers]) {
        // For all view controllers that this is removing, follow UIViewController.h's rules for
        // for removing a child view controller. See the comments in UIViewController.h for more
        // information.
        for (UIViewController *viewController in oldViewControllers) {
            if (![viewControllers containsObject:viewController]) {
                [viewController willMoveToParentViewController:nil];
                if (viewController.isViewLoaded) {
                    [viewController.view removeFromSuperview];
                }
                [viewController removeFromParentViewController];
            }
        }
        // Show the newly-visible view controller.
        [self updateTabBarItems];
    }
}

- (void)updateOldSelectedViewController:(nullable UIViewController *)oldSelectedViewController
                                     to:(nullable UIViewController *)selectedViewController
{
    if (!self.isViewLoaded || oldSelectedViewController == selectedViewController) {
        return;
    }
    if (selectedViewController) {
        NSAssert([_viewControllers containsObject:selectedViewController], @"not one of us.");
    }

    if (![self.childViewControllers containsObject:selectedViewController]) {
        [self addChildViewController:selectedViewController];
        UIView *view = selectedViewController.view;
        [self.contentView addSubview:view];
        [selectedViewController didMoveToParentViewController:self];
    }
    [self updateTabBarItems];
    BOOL animated = NO;
    [oldSelectedViewController beginAppearanceTransition:NO animated:animated];
    [selectedViewController beginAppearanceTransition:YES animated:animated];

    [self transitionViewsWithoutAnimationFromViewController:oldSelectedViewController
                                           toViewController:selectedViewController];

    [oldSelectedViewController endAppearanceTransition];
    [selectedViewController endAppearanceTransition];

    if (selectedViewController) {
        self.tabBar.selectedItem = selectedViewController.tabBarItem;
    }
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)setSelectedViewController:(nullable UIViewController *)selectedViewController
{
    UIViewController *oldSelectedViewController = _selectedViewController;
    _selectedViewController = selectedViewController;
    if (_selectedViewController) {
        NSUInteger index = [_viewControllers indexOfObject:_selectedViewController];
        [_contentView setContentOffset:CGPointMake(index * self.view.frame.size.width, 0)];
    }
    [self updateOldSelectedViewController:oldSelectedViewController to:selectedViewController];
}

#pragma mark - private

// Encapsulate the actual view handling.
- (void)transitionViewsWithoutAnimationFromViewController:(UIViewController *)from
                                         toViewController:(UIViewController *)to
{
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    //    from.view.hidden = YES;
    //    to.view.hidden = NO;
}

// Either this has just come into existence or its array of viewControllers has changed.
// Update the TabBar from the array of viewControllers.
- (void)updateTabBarItems
{
    NSMutableArray<UITabBarItem *> *items = [NSMutableArray array];
    BOOL hasTitles = NO;
    BOOL hasImages = NO;
    for (UIViewController *child in _viewControllers) {
        UITabBarItem *tabBarItem = child.tabBarItem;
        [items addObject:tabBarItem];
        if (tabBarItem.title.length) {
            hasTitles = YES;
        }
        if (tabBarItem.image) {
            hasImages = YES;
        }
    }
    // This class preserves the invariant that if the selected controller is not nil, it is
    // contained
    // in the array of viewControllers.
    if (![_viewControllers containsObject:_selectedViewController]) {
        self.selectedViewController = nil;
    }
    self.tabBar.items = items;
    // The default height of the tab bar depends on the underlying UITabBarItems of
    // the viewControllers.
    if (hasImages && hasTitles) {
        self.tabBar.itemAppearance = MDCTabBarItemAppearanceTitledImages;
    } else if (hasImages) {
        self.tabBar.itemAppearance = MDCTabBarItemAppearanceImages;
    } else {
        self.tabBar.itemAppearance = MDCTabBarItemAppearanceTitles;
    }
    [self.view bringSubviewToFront:self.tabBar];
}

- (nullable UIViewController *)controllerWithView:(nullable UIView *)view
{
    for (UIViewController *child in _viewControllers) {
        if (child.view == view) {
            return child;
        }
    }
    return nil;
}

- (void)updateLayout
{
    CGRect bounds = self.view.bounds;
    CGFloat tabBarHeight = [[_tabBar class] defaultHeightForBarPosition:self.tabBarPosition
                                                         itemAppearance:_tabBar.itemAppearance];

    CGFloat safeAreaPadding = 0;
    CGRect subViewFrame = bounds;
    CGRect tabBarFrame = CGRectZero;

    if (@available(iOS 11.0, *)) {
        safeAreaPadding = self.tabBarPosition == UIBarPositionBottom
            ? self.view.safeAreaInsets.bottom
            : self.view.safeAreaInsets.top;
    }

    if (self.tabBarPosition == UIBarPositionBottom) {
        CGFloat tabH = safeAreaPadding + tabBarHeight;
        subViewFrame = CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width,
            _tabBarWantsToBeHidden ? bounds.size.height : bounds.size.height - tabH);
        tabBarFrame
            = CGRectMake(bounds.origin.x, CGRectGetMaxY(subViewFrame), bounds.size.width, tabH);
    } else {
        tabBarFrame = CGRectMake(bounds.origin.x, bounds.origin.y + self.view.safeAreaInsets.top,
            bounds.size.width, tabBarHeight);
        subViewFrame = CGRectMake(bounds.origin.x,
            _tabBarWantsToBeHidden ? bounds.origin.y : CGRectGetMaxY(tabBarFrame),
            bounds.size.width,
            _tabBarWantsToBeHidden ? bounds.size.height
                                   : bounds.size.height - CGRectGetMaxY(tabBarFrame));
    }

    CGFloat w = subViewFrame.size.width;
    CGFloat h = subViewFrame.size.height;
    NSInteger viewControllerCount = _viewControllers.count;

    _tabBar.frame = tabBarFrame;
    _contentView.frame = subViewFrame;
    _contentView.contentSize = CGSizeMake(viewControllerCount * w, h);

    for (int i = 0; i < viewControllerCount; i++) {
        UIViewController *page = _viewControllers[i];
        if (!page) {
            continue;
        }
        CGRect nextFrame = CGRectMake(i * w, 0, w, h);
        page.view.frame = nextFrame;
    }
}

#pragma mark -  UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat offset = _contentView.contentOffset.x;
    CGFloat w = offset / scrollView.frame.size.width;
    NSUInteger page = lround(w);

    UIViewController *contentViewController = _viewControllers[page];

    if (!(contentViewController == self.selectedViewController)) {
        if (page >= 0 && page < _viewControllers.count) {
            [self setSelectedViewController:contentViewController];
        }
    }
}

//- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
//{
//    CGFloat offset = _contentView.contentOffset.x;
//    CGFloat w = offset / scrollView.frame.size.width;
//    NSUInteger page = lround(w);
//
//    UIViewController *contentViewController = _viewControllers[page];
//
//    if (!(contentViewController == self.selectedViewController)) {
//        if (page >= 0 && page < _viewControllers.count) {
//            [self setSelectedViewController:contentViewController];
//        }
//    }
//}

#pragma mark -  MDCTabBarDelegate

- (BOOL)tabBar:(UITabBar *)tabBar shouldSelectItem:(UITabBarItem *)item
{
    if ([_delegate respondsToSelector:@selector(tabBarController:shouldSelectViewController:)]) {
        NSUInteger index = [tabBar.items indexOfObject:item];
        if (index < _viewControllers.count) {
            UIViewController *newSelected = _viewControllers[index];
            return [_delegate tabBarController:self shouldSelectViewController:newSelected];
        }
    }
    return YES;
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    NSUInteger index = [tabBar.items indexOfObject:item];
    if (index < _viewControllers.count) {
        UIViewController *newSelected = _viewControllers[index];
        if (newSelected != self.selectedViewController) {
            self.selectedViewController = newSelected;
        }
        if ([_delegate respondsToSelector:@selector(tabBarController:didSelectViewController:)]) {
            [_delegate tabBarController:self didSelectViewController:newSelected];
        }
    }
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    if (_tabBar == bar) {
        return self.tabBarPosition;
    } else {
        return UIBarPositionAny;
    }
}

#pragma mark - UIViewController status bar

- (nullable UIViewController *)childViewControllerForStatusBarStyle
{
    return _selectedViewController;
}

- (nullable UIViewController *)childViewControllerForStatusBarHidden
{
    return _selectedViewController;
}

-(BOOL)forceEnableInteractivePopGestureRecognizer {
    return YES;
}

@end
