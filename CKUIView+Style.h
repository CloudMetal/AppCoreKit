//
//  CKUIView+Style.h
//  CloudKit
//
//  Created by Sebastien Morel on 11-04-20.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CKGradientView.h"
#import "CKNSObject+Introspection.h"


/* TODO :
     utiliser l'introspection pour pouvoir setter n'importe quelle property via les styles avec les types supportes par le style serializer
     le style serializer aura surement besoin d'un enum manager pour le parsing car c les types qui n'ont rien pour etre introspectes (= int)
     faudra enregistrer les enums qu'on veut pouvoir utiliser avec l'introspection en utilisant le helper CKEnumDictionary
 */



typedef enum{
	CKViewCornerStyleDefault,//in this case, we set the corner style of the parent controller (table plain or grouped)
	//in the following case, we force the corner style of the cell and bypass the parent controller style
	CKViewCornerStyleRounded,
	CKViewCornerStyleRoundedTop,
	CKViewCornerStyleRoundedBottom,
	CKViewCornerStylePlain
}CKViewCornerStyle;

extern NSString* CKStyleBackgroundColor;
extern NSString* CKStyleBackgroundGradientColors;
extern NSString* CKStyleBackgroundGradientLocations;
extern NSString* CKStyleBackgroundImage;
extern NSString* CKStyleCornerStyle;
extern NSString* CKStyleCornerSize;
extern NSString* CKStyleAlpha;

@interface NSMutableDictionary (CKViewStyle)

- (UIColor*)backgroundColor;
- (NSArray*)backgroundGradientColors;
- (NSArray*)backgroundGradientLocations;
- (UIImage*)backgroundImage;
- (CKViewCornerStyle)cornerStyle;
- (CGSize)cornerSize;
- (CGFloat)alpha;

@end


@interface UIView (CKStyle) 

- (void)applyStyle:(NSMutableDictionary*)style;
- (void)applyStyle:(NSMutableDictionary*)style propertyName:(NSString*)propertyName;

+ (BOOL)applyStyle:(NSMutableDictionary*)style toView:(UIView*)view propertyName:(NSString*)propertyName appliedStack:(NSMutableSet*)appliedStack delegate:(id)delegate;
+ (BOOL)applyStyle:(NSMutableDictionary*)style toView:(UIView*)view propertyName:(NSString*)propertyName appliedStack:(NSMutableSet*)appliedStack;

//private
+ (BOOL)needSubView:(NSMutableDictionary*)style forView:(UIView*)view propertyName:(NSString*)propertyName;
@end

@interface NSObject (CKStyle)

- (void)applySubViewsStyle:(NSMutableDictionary*)style appliedStack:(NSMutableSet*)appliedStack delegate:(id)delegate;

@end

@protocol CKStyleDelegate
@optional

- (CKRoundedCornerViewType)view:(UIView*)view cornerStyleWithStyle:(NSMutableDictionary*)style;
- (BOOL)object:(id)object shouldReplaceViewWithDescriptor:(CKClassPropertyDescriptor*)descriptor;

@end