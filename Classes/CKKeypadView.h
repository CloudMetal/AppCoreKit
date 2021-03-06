//
//  CKKeypadView.h
//  AppCoreKit
//
//  Created by Olivier Collet.
//  Copyright 2010 WhereCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 */
typedef enum {
	CKKeypadViewKeyZero = 0,
	CKKeypadViewKeyOne = 1,
	CKKeypadViewKeyTwo = 2,
	CKKeypadViewKeyThree = 3,
	CKKeypadViewKeyFour = 4,
	CKKeypadViewKeyFive = 5,
	CKKeypadViewKeySix = 6,
	CKKeypadViewKeySeven = 7,
	CKKeypadViewKeyEight = 8,
	CKKeypadViewKeyNine = 9,
	CKKeypadViewKeyNone = 1000,
	CKKeypadViewKeyBackspace = 1001
} CKKeypadViewKey;


@class CKKeypadView;


// CKKeypadViewDelegate

/**
 */
@protocol CKKeypadViewDelegate
@optional
- (BOOL)keypadView:(CKKeypadView *)keypadView shouldSelectKey:(CKKeypadViewKey)key;
- (void)keypadView:(CKKeypadView *)keypadView didSelectKey:(CKKeypadViewKey)key;
@end


// CKKeypadView

/**
 */
@interface CKKeypadView : UIView {
	NSString *_value;

	id<CKKeypadViewDelegate> _delegate;
}

@property (nonatomic, retain) NSString *value;
@property (nonatomic, assign) IBOutlet id<CKKeypadViewDelegate> delegate;

@end
