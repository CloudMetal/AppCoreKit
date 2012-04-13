//
//  CKObjectCarouselViewController.m
//  CloudKit
//
//  Created by Sebastien Morel on 11-04-07.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import "CKObjectCarouselViewController.h"
#import "CKTableViewCellController.h"
#import "CKNSObject+Bindings.h"
#import "CKCollectionController.h"


@interface UIViewWithIdentifier : UIView{
	id reuseIdentifier;
}
@property (nonatomic,retain) id reuseIdentifier;
@end

@implementation UIViewWithIdentifier
@synthesize reuseIdentifier;
- (void)dealloc{ self.reuseIdentifier = nil; [super dealloc]; }
@end


@interface CKObjectCarouselViewController ()
@property (nonatomic, retain) NSMutableDictionary* headerViewsForSections;
@end

@implementation CKObjectCarouselViewController
@synthesize carouselView = _carouselView;
@synthesize headerViewsForSections = _headerViewsForSections;
@synthesize pageControl = _pageControl;

- (void)dealloc {
	[NSObject removeAllBindingsForContext:[NSString stringWithFormat:@"<%p>_pageControl",self]];
	[_carouselView release];
	_carouselView = nil;
	[_headerViewsForSections release];
	_headerViewsForSections = nil;
	[_pageControl release];
	_pageControl = nil;
	[super dealloc];
}

- (void)loadView {
	[super loadView];
	if (self.view == nil) {
		CGRect theViewFrame = [[UIScreen mainScreen] applicationFrame];
		UIView *theView = [[[UITableView alloc] initWithFrame:theViewFrame] autorelease];
		theView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		self.view = theView;
	}
	
	if (self.carouselView == nil) {
		if ([self.view isKindOfClass:[CKCarouselView class]]) {
			// TODO: Assert - Should not be allowed
			self.carouselView = (CKCarouselView *)self.view;
		} else {
			CGRect theViewFrame = self.view.bounds;
			CKCarouselView *theCarouselView = [[[CKCarouselView alloc] initWithFrame:theViewFrame] autorelease];
			theCarouselView.delegate = self;
			theCarouselView.dataSource = self;
			theCarouselView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
			[self.view addSubview:theCarouselView];
			self.carouselView = theCarouselView;
		}
	}
	
	//DEBUG :
	self.carouselView.clipsToBounds = YES;
	self.carouselView.spacing = 20;
}

- (void)updateParams{
	if(self.params == nil){
		self.params = [NSMutableDictionary dictionary];
	}
	
	[self.params setObject:[NSValue valueWithCGSize:self.carouselView.bounds.size] forKey:CKTableViewAttributeBounds];
	[self.params setObject:[NSNumber numberWithInt:self.interfaceOrientation] forKey:CKTableViewAttributeInterfaceOrientation];
	[self.params setObject:[NSNumber numberWithDouble:0] forKey:CKTableViewAttributeAnimationDuration];
	[self.params setObject:[NSValue valueWithNonretainedObject:self] forKey:CKTableViewAttributeParentController];
    
	[self.params setObject:[NSNumber numberWithBool:NO] forKey:CKTableViewAttributeEditable];//NOT SUPPORTED FOR CAROUSEL
	[self.params setObject:[NSNumber numberWithBool:YES] forKey:CKTableViewAttributePagingEnabled];//NOT SUPPORTED FOR CAROUSEL
	[self.params setObject:[NSNumber numberWithInt:CKTableViewOrientationLandscape] forKey:CKTableViewAttributeOrientation];//NOT SUPPORTED FOR CAROUSEL
}

- (void)scrollToPage:(id)page{
	[self.carouselView setContentOffset:_pageControl.currentPage animated:YES];
}

- (void)updatePageControlPage:(id)page{
	_pageControl.currentPage = (_pageControl.currentPage + 1 >= self.carouselView.numberOfPages) ? self.carouselView.currentPage - 1 :  self.carouselView.currentPage +1;
	_pageControl.currentPage = self.carouselView.currentPage;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	if(_pageControl){
		[NSObject beginBindingsContext:[NSString stringWithFormat:@"<%p>_pageControl",self]];
		[self.carouselView bind:@"currentPage" target:self action:@selector(updatePageControlPage:)];
		[self.carouselView bind:@"numberOfPages" toObject:_pageControl withKeyPath:@"numberOfPages"];
		[_pageControl bindEvent:UIControlEventTouchUpInside target:self action:@selector(scrollToPage:)];
		[NSObject endBindingsContext];
	}
}

- (void)viewDidUnload {
    [super viewDidUnload];
	[NSObject removeAllBindingsForContext:[NSString stringWithFormat:@"<%p>_pageControl",self]];
	self.carouselView = nil;
	self.pageControl = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self updateParams];
	
	[self updateVisibleViewsRotation];
	
	[self reload];
    
	for(int i =0; i< [self numberOfSections];++i){
		[self fetchMoreIfNeededAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:i]];
	}
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration{
	[super willAnimateRotationToInterfaceOrientation:interfaceOrientation duration:duration];
	[self.carouselView reloadData];
	[self.carouselView updateViewsAnimated:YES];
}

#pragma mark CKCarouselViewDataSource

- (NSInteger)numberOfSectionsInCarouselView:(CKCarouselView*)carouselView{
	return [self numberOfSections];
}

- (NSInteger)carouselView:(CKCarouselView*)carouselView numberOfRowsInSection:(NSInteger)section{
	return [self numberOfObjectsForSection:section];
}

- (CGSize) carouselView:(CKCarouselView*)carouselView sizeForViewAtIndexPath:(NSIndexPath*)indexPath{	
	return [self sizeForViewAtIndexPath:indexPath];
}

- (UIView*)dequeueReusableViewWithIdentifier:(NSString*)identifier{
	return [self.carouselView dequeueReusableViewWithIdentifier:identifier];
}

- (UIView*)carouselView:(CKCarouselView*)carouselView viewForRowAtIndexPath:(NSIndexPath*)indexPath{
	UIView* view = [self createViewAtIndexPath:indexPath];
	[self fetchMoreIfNeededAtIndexPath:indexPath];
	return view;
}

#pragma mark CKCarouselViewDelegate

- (UIView*) carouselView:(CKCarouselView*)carouselView viewForHeaderInSection:(NSInteger)section{
	UIView* view = _headerViewsForSections ? [_headerViewsForSections objectForKey:[NSNumber numberWithInt:section]] : nil;
	if(view){
		return view;
	}
	
	//if([_objectController conformsToProtocol:@protocol(CKObjectController) ]){
	if([_objectController respondsToSelector:@selector(headerViewForSection:)]){
		view = [_objectController headerViewForSection:section];
		if(_headerViewsForSections == nil){
			self.headerViewsForSections = [NSMutableDictionary dictionary];
		}
		if(view != nil){
			[_headerViewsForSections setObject:view forKey:[NSNumber numberWithInt:section]];
		}
	}
	//}
	return view;
}

- (void) carouselView:(CKCarouselView*)carouselView viewDidDisappearAtIndexPath:(NSIndexPath*)indexPath{
	CKItemViewController* controller = [self controllerAtIndexPath:indexPath];
	if(controller && [controller respondsToSelector:@selector(viewDidDisappear)]){
		[controller viewDidDisappear];
	}
}

- (void) carouselView:(CKCarouselView*)carouselView viewDidAppearAtIndexPath:(NSIndexPath*)indexPath{
	CKItemViewController* controller = [self controllerAtIndexPath:indexPath];
	if(controller && [controller respondsToSelector:@selector(viewDidAppear:)]){
		UIView* view = [self.carouselView viewAtIndexPath:indexPath];
		[controller viewDidAppear:view];
	}	
}

- (void) carouselViewDidScroll:(CKCarouselView*)carouselView{
}

#pragma mark CKObjectControllerDelegate

- (void)onReload{
	[self.carouselView reloadData];
}

- (void)onBeginUpdates{
}

- (void)onEndUpdates{
	[self.carouselView reloadData];
}

- (void)onInsertObjects:(NSArray*)objects atIndexPaths:(NSArray*)indexPaths{
    //implement animations
}

- (void)onRemoveObjects:(NSArray*)objects atIndexPaths:(NSArray*)indexPaths{
    //implement animations
}

- (void)scrollToRowAtIndexPath:(NSIndexPath*)indexPath animated:(BOOL)animated{
	CGFloat offset = [self.carouselView pageForIndexPath:indexPath];
	[self.carouselView setContentOffset:offset animated:animated];
}

#pragma mark CKObjectCarouselViewController

/*
- (UIView*)viewAtIndexPath:(NSIndexPath *)indexPath{
	return [self.carouselView viewAtIndexPath:indexPath];
}
 */

- (NSArray*)visibleIndexPaths{
	return [self.carouselView visibleIndexPaths];
}

@end
