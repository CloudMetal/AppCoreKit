//
//  CKBasicCellController.m
//  CloudKit
//
//  Created by Olivier Collet on 09-12-15.
//  Copyright 2009 WhereCloud Inc. All rights reserved.
//

#import "CKTableViewCellController.h"
#import "CKManagedTableViewController.h"

@implementation CKTableViewCellController

@synthesize target = _target;
@synthesize action = _action;
@synthesize selectable = _selectable;
@synthesize accessoryType = _accessoryType;
@synthesize parentController = _parentController;
@synthesize indexPath = _indexPath;

- (id)init {
	self = [super init];
	if (self != nil) {
		_selectable = YES;
	}
	return self;
}

- (void)dealloc {
	_target = nil;
	_action = nil;
	_parentController = nil;
	[super dealloc];
}

- (NSString *)identifier {
	return [[self class] description];
}

- (void)setIndexPath:(NSIndexPath *)indexPath {
	// This method is hidden from the public interface and is called by the CKManagedTableViewController
	// when adding the CKTableViewCellController.	
	[_indexPath release];
	_indexPath = [indexPath retain];
}

- (void)setParentController:(CKManagedTableViewController *)parentController {
	// Set a *weak* reference to the parent controller
	// This method is hidden from the public interface and is called by the CKManagedTableViewController
	// when adding the CKTableViewCellController.
	_parentController = parentController;
}

- (UITableViewCell *)tableViewCell {
	return [_parentController.tableView cellForRowAtIndexPath:self.indexPath];
}

#pragma mark Cell Factory

- (UITableViewCell *)cellWithStyle:(UITableViewStyle)style {
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:style reuseIdentifier:[self identifier]] autorelease];
	
	cell.selectionStyle = self.isSelectable ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;
	cell.accessoryType = _accessoryType;

	return cell;
}

#pragma mark CKManagedTableViewController Protocol

- (void)cellDidAppear:(UITableViewCell *)cell {
	return;
}

- (void)cellDidDisappear {
	return;
}

- (UITableViewCell *)loadCell {
	UITableViewCell *cell = [self cellWithStyle:UITableViewCellStyleDefault];
	if (self.selectable == NO) cell.selectionStyle = UITableViewCellSelectionStyleNone;
	return cell;
}

- (void)setupCell:(UITableViewCell *)cell {
	return;
}

- (CGFloat)heightForRow {
	return 44.0f;
}

// Selection

- (NSIndexPath *)willSelectRow {
	return self.isSelectable ? self.indexPath : nil;
}

- (void)didSelectRow {
	if (self.isSelectable) {
		[self.parentController.tableView deselectRowAtIndexPath:self.indexPath animated:YES];
		if (_target && [_target respondsToSelector:_action]) {
			[_target performSelector:_action withObject:self];
		}
	}
}

// Update

- (void)setNeedsSetup {
	if (self.tableViewCell)
		[self setupCell:self.tableViewCell];
}

@end