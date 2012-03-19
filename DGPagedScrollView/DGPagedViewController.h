//
//  DGPagedView.m
//
//  Created by Daniel García on 23/02/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DGScrollView.h"
@interface DGPagedViewController : UIViewController<UIScrollViewDelegate,DGScrollViewDelegate,DGScrollViewDataSource>{
}
@property (nonatomic,readonly) NSInteger currentPage;
@property (nonatomic, readonly) DGScrollView* scrollView;
@property (nonatomic) BOOL pageControlHidden;
- (void) setPage:(NSUInteger)page animated:(BOOL) animated;
- (void) reloadData;
//Data Source Methods
- (NSInteger)numberOfPagesInPagedView:(DGPagedViewController *)pagedView;
- (UIView *)pagedView:(DGPagedViewController *)pagedView pageViewAtIndex:(NSUInteger)index;
//Delegate Methods
- (void)didSelectPageAtIndex:(NSUInteger)index;
@end