//
//  CKSerializer.h
//  CloudKit
//
//  Created by Sebastien Morel on 11-05-18.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CKProperty.h"
#import "CKDocumentArray.h"

#import "CKUIColor+ValueTransformer.h"
#import "CKUIImage+ValueTransformer.h"
#import "CKNSNumber+ValueTransformer.h"
#import "CKNSURL+ValueTransformer.h"
#import "CKNSDate+ValueTransformer.h"
#import "CKNSArray+ValueTransformer.h"
#import "CKCollection+ValueTransformer.h"
#import "CKNSIndexPath+ValueTransformer.h"
#import "CKNSObject+ValueTransformer.h"
#import "CKNSValueTransformer+NativeTypes.h"
#import "CKNSValueTransformer+CGTypes.h"

/** TODO
 */
@interface NSValueTransformer (CKAddition)

+ (id)transform:(id)object inProperty:(CKProperty*)property;
+ (id)transform:(id)source toClass:(Class)type;
+ (id)transformProperty:(CKProperty*)property toClass:(Class)type;
+ (void)transform:(NSDictionary*)source toObject:(id)target;

@end
