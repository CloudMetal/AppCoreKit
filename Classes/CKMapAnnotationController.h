//
//  CKMapAnnotationController.h
//  CloudKit
//
//  Created by Sebastien Morel on 11-05-25.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import "CKItemViewController.h"
#import <MapKit/MapKit.h>

typedef enum CKMapAnnotationStyle{
	CKMapAnnotationCustom,
	CKMapAnnotationPin
}CKMapAnnotationStyle;

@interface CKMapAnnotationController : CKItemViewController {
	CKMapAnnotationStyle _style;
}

@property (nonatomic,assign) CKMapAnnotationStyle style;

- (MKAnnotationView*)loadAnnotationView;
- (MKAnnotationView*)viewWithStyle:(CKMapAnnotationStyle)style;

@end