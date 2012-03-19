//
//  DGPagedView.m
//
//  Created by Daniel García on 23/02/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "DGScrollView.h"
#import <QuartzCore/CATransaction.h>

#define kPageControlHeight 36.0f

@interface DGScrollView (){

}
@property (nonatomic) NSUInteger currentPage;
@property (retain,nonatomic) UIPageControl* pageControl;
- (UIView *)dummyViewWithFrame:(CGRect)frame;
- (void) updatePageControlPosition;
- (void) checkAndInsertPageAtIndex:(NSInteger)index;
- (void) changePage:(UIPageControl*) aPageControl;
- (void) changePage:(UIPageControl*) aPageControl animated:(BOOL)animated;
@end

@implementation DGScrollView
@synthesize views,contentViews,currentPage;
@synthesize pageControl;
#pragma mark -
#pragma mark Subclass

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.delegate=nil;
        self.pagingEnabled = YES;
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.scrollsToTop = NO;
        //Page control
        self.currentPage=0;
        CGRect frame = CGRectMake(self.contentOffset.x, 0, self.frame.size.width, kPageControlHeight);
        UIPageControl* aPageControl = [[UIPageControl alloc] initWithFrame:frame];
        [aPageControl addTarget:self action:@selector(changePage:) forControlEvents:UIControlEventValueChanged];
        aPageControl.defersCurrentPageDisplay = YES;
        aPageControl.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin);
        [self addSubview:aPageControl];
        pageControl = aPageControl;  
        self.pageControlHidden=NO;
    }
    return self;
}

#pragma mark Content Management
- (void) addPage:(UIView *)view {
    [self addPage:view atIndex:[self.views count]];
}
- (void) addPage:(UIView *)view atIndex:(NSUInteger)index {
    [view retain];
    NSMutableArray *newViews=[self.views mutableCopy];
    if(index<[newViews count]){
        id previousObject =[newViews objectAtIndex:index];
        [newViews removeObject:previousObject];
    }
    CGRect frame=self.frame;
    frame.origin.x=frame.origin.x + (index * frame.size.width);
    frame.origin.y=0;
    view.frame=frame;
    [newViews insertObject:view atIndex:index];
    self.views=[newViews autorelease];
    [self insertSubview:view belowSubview:self.pageControl];
    [view release];
    //DebugLog(@"Add %d %@",index,self.views);
    [self updatePageControlPosition];
}
- (void) removePage:(UIView *)view {
    [view removeFromSuperview];
}
- (void)removePageAtIndex:(NSUInteger)index {
    if(index<[self.views count]){
        UIView *viewToRemove=[self.views objectAtIndex:index];
        NSMutableArray *newViews=[self.views mutableCopy];
        [newViews removeObject:viewToRemove]; 
        if(index!=([self.views count]-1)){
            [newViews insertObject:[self dummyViewWithFrame:viewToRemove.frame] atIndex:index];
        }
        self.views=newViews;
        [newViews release];
        [self removePage:viewToRemove];
        //////DebugLog(@"Remove %d %@",index,self.views);
        [self updatePageControlPosition];
    }
}
- (UIView *)dummyViewWithFrame:(CGRect)frame{
    UIView *dummyView=[[UIView alloc]initWithFrame:frame];
    dummyView.tag=1;
    return [dummyView autorelease];
}
- (UIView *)pageAtIndex:(NSUInteger)index {
    return (UIView *)[self.views objectAtIndex:index];
}
- (void) emptyPages {
    for (UIView* view in self.views) {
        if(view.tag!=1)
            [view removeFromSuperview];
    }
    self.views=nil;
    [self setNeedsLayout];
}

- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event 
{	
    if(self.delegate){
        CGFloat pageWidth = self.frame.size.width;
        float fractionalPage = self.contentOffset.x / pageWidth;
        NSInteger page = lround(fractionalPage);
        [(id <DGScrollViewDelegate>)self.delegate didSelectPageAtIndex:page]; 
    }
}
#pragma mark Layout
- (BOOL) pageControlHidden{
    return self.pageControl.hidden;
}
- (void)setPageControlHidden:(BOOL)pageControlHidden{
    self.pageControl.hidden=pageControlHidden;
}
- (void) checkAndInsertPageAtIndex:(NSInteger)index{
    UIView *viewToShow=nil;
    if(index<[self.views count]){
        viewToShow=[self pageAtIndex:index];
        if(viewToShow.tag==1){
            viewToShow=nil;
        }
    }
    if(viewToShow==nil){
        [self addPage:[(id <DGScrollViewDataSource>)self.delegate pagedView:(id <DGScrollViewDelegate>)self.delegate pageViewAtIndex:index] atIndex:index];
    }
}
- (void) updatePageControlPosition{
    if(!self.pageControlHidden){
        NSInteger totalPages=[(id <DGScrollViewDataSource>)self.delegate numberOfPagesInPagedView:(id <DGScrollViewDelegate>)self.delegate];
        self.pageControl.numberOfPages = totalPages;
    }
}
- (void) layoutSubviews {
    [super layoutSubviews];
    CGFloat pageWidth = self.frame.size.width;
    float fractionalPage = self.contentOffset.x / pageWidth;
    NSInteger actualPage=self.currentPage;
    NSInteger appearingPage;
    if(actualPage<fractionalPage){
        appearingPage=ceil(fractionalPage);
    }else {
        appearingPage=floor(fractionalPage);
    }
    if((int)fractionalPage==fractionalPage){
        self.currentPage=(int)fractionalPage;
        [self updatePageControlPosition];
    }
    NSInteger totalPages=[(id <DGScrollViewDataSource>)self.delegate numberOfPagesInPagedView:(id <DGScrollViewDelegate>)self.delegate];
    if(totalPages>0 && appearingPage>=0 && appearingPage<totalPages){
        [self checkAndInsertPageAtIndex:appearingPage];
        if(actualPage<=appearingPage && (appearingPage+1)<totalPages){
            [self checkAndInsertPageAtIndex:(appearingPage+1)];
        }
        if(actualPage>appearingPage && (appearingPage-1)>=0){
            [self checkAndInsertPageAtIndex:(appearingPage-1)];
        }
        UIEdgeInsets inset = self.scrollIndicatorInsets;
        CGFloat heightInset = inset.top + inset.bottom;
        self.contentSize = CGSizeMake(self.frame.size.width * [self.views count], self.frame.size.height - heightInset);
    }
    //Avoid that the pageControl move
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    CGRect frame = self.pageControl.frame;
    frame.origin.x = self.contentOffset.x;
    frame.origin.y = self.frame.size.height - 50 - self.scrollIndicatorInsets.bottom - self.scrollIndicatorInsets.top;
    frame.size.width = self.frame.size.width;
    self.pageControl.frame = frame;
    [CATransaction commit];
}

#pragma mark -
#pragma mark Getters/Setters

- (void) setFrame:(CGRect) newFrame {
    [super setFrame:newFrame];
}
- (void) changePage:(UIPageControl*) aPageControl {
    [self changePage:aPageControl animated:YES];
}
- (void) changePage:(UIPageControl*) aPageControl animated:(BOOL)animated{
    [self setPage:aPageControl.currentPage animated:animated];
}

- (void) setContentOffset:(CGPoint) new {
    new.y = -self.scrollIndicatorInsets.top;
    [super setContentOffset:new];
    self.pageControl.currentPage = self.page; //Update the page number
}

- (NSArray*) views {
    if (views==nil) {
        views = [[NSArray alloc]init];
    }
    return views;
}
- (NSArray*) contentViews {
    if (contentViews==nil) {
        contentViews = [[NSArray alloc]init];
    }
    return contentViews;
}
- (NSUInteger) page {
    return (self.contentOffset.x + self.frame.size.width / 2) / self.frame.size.width;
}

- (void) setPage:(NSUInteger)page {
    [self setPage:page animated:NO];
}

- (void) setPage:(NSUInteger)page animated:(BOOL) animated {
    [self emptyPages];
    NSMutableArray *newArray=[[NSMutableArray alloc]init];
    for(int i=0;i<=page;i++){
        CGRect frame=self.frame;
        frame.origin.x=frame.origin.x + (i * frame.size.width);
        frame.origin.y=0;
        [newArray insertObject:[self dummyViewWithFrame:frame] atIndex:i];
    }
    self.views=[newArray autorelease];
    UIEdgeInsets inset = self.scrollIndicatorInsets;
    CGFloat heightInset = inset.top + inset.bottom;
    self.contentSize = CGSizeMake(self.frame.size.width * [self.views count], self.frame.size.height - heightInset);
    self.currentPage=page;
    [self checkAndInsertPageAtIndex:(page-1)];
    [self layoutSubviews];
    [self setContentOffset:CGPointMake(page * self.frame.size.width, - self.scrollIndicatorInsets.top) animated:animated];
}

#pragma mark Dealloc

- (void)dealloc {    
    [views release];
    [pageControl release];
    [super dealloc];
}


@end
