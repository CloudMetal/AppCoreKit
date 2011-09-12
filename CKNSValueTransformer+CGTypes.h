//
//  CKNSValueTransformer+CGTypes.h
//  CloudKit
//
//  Created by Sebastien Morel on 11-08-11.
//  Copyright 2011 Wherecloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface NSValueTransformer (CKCGTypes)

+ (CGSize)parseStringToCGSize:(NSString*)str;
+ (CGSize)convertCGSizeFromObject:(id)object;
+ (CGRect)parseStringToCGRect:(NSString*)str;
+ (CGRect)convertCGRectFromObject:(id)object;
+ (CGPoint)parseStringToCGPoint:(NSString*)str;
+ (CGPoint)convertCGPointFromObject:(id)object;

+ (UIEdgeInsets)parseStringToUIEdgeInsets:(NSString*)str;
+ (UIEdgeInsets)convertUIEdgeInsetsFromObject:(id)object;

+ (CGColorRef)convertCGColorRefFromObject:(id)object;

@end
