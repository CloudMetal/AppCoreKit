//
//  CKUIImage+Transformations.m
//  CloudKit
//
//  Created by Fred Brunel on 10-02-03.
//  Copyright 2010 WhereCloud Inc. All rights reserved.
//

#import "CKUIImage+Transformations.h"

@implementation UIImage (CKUIImageTransformationsAdditions)

// Original code by Ian Baird on 3/28/08.
// TouchCode. Copyright 2008 Skorpiostech.

- (UIImage *)imageThatFits:(CGSize)theSize crop:(BOOL)crop
{
    CGRect destRect = CGRectMake(0.0f, 0.0f, theSize.width, theSize.height);
    
	CGImageRef srcImage;
	
	if (!crop) {
		if (self.size.width > self.size.height)
		{
			// Scale height down
			destRect.size.height = ceilf(self.size.height * (theSize.width / self.size.width));
			
			// Recenter
			destRect.origin.y = (theSize.height - destRect.size.height) / 2.0f;
		}
		else if (self.size.width < self.size.height)
		{
			// Scale width down
			destRect.size.width = ceilf(self.size.width * (theSize.height / self.size.height));
			
			// Recenter
			destRect.origin.x = (theSize.width - destRect.size.width) / 2.0f;
		}
		
		srcImage = self.CGImage;
	} else {
		// Crop source image to a square
		CGFloat cropSize = MIN(self.size.width, self.size.height);
		
		CGRect srcRect = CGRectMake((self.size.width - cropSize) / 2,
									(self.size.height - cropSize) / 2,
									cropSize, cropSize);
		
		srcImage = CGImageCreateWithImageInRect(self.CGImage, srcRect);
	}
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef gc = CGBitmapContextCreate(NULL, theSize.width, theSize.height, 8, (4 * theSize.width), colorSpace, kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    CGContextSetInterpolationQuality(gc, kCGInterpolationHigh);
    CGContextDrawImage(gc, destRect, srcImage);
    CGImageRef contextImage = CGBitmapContextCreateImage(gc);
    CGContextRelease(gc);
    
    UIImage *result = [UIImage imageWithCGImage:contextImage];
    CGImageRelease(contextImage);
	
	if (crop) { CGImageRelease(srcImage); }
    
    return result;
}

static void CKCGAddRoundedRectToPath(CGContextRef gc, CGRect rect, CGFloat radius) {
    CGContextBeginPath(gc);
	CGContextSaveGState(gc);
	
	if (radius == 0) {
        CGContextAddRect(gc, rect);
    } else {
		CGContextTranslateCTM(gc, CGRectGetMinX(rect), CGRectGetMinY(rect));
		CGContextScaleCTM(gc, radius, radius);
		CGFloat fw = CGRectGetWidth(rect) / radius;
		CGFloat fh = CGRectGetHeight(rect) / radius;
		CGContextMoveToPoint(gc, fw, fh/2);
		CGContextAddArcToPoint(gc, fw, fh, fw/2, fh, 1);
		CGContextAddArcToPoint(gc, 0, fh, 0, fh/2, 1);
		CGContextAddArcToPoint(gc, 0, 0, fw/2, 0, 1);
		CGContextAddArcToPoint(gc, fw, 0, fw, fh/2, 1);
	}
	
	CGContextClosePath(gc);
	CGContextRestoreGState(gc);
}

- (UIImage *)imageByAddingBorderWithColor:(UIColor *)strokeColor cornerRadius:(CGFloat)radius {
	int w = self.size.width;
	int h = self.size.height;
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef gc = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
	
	// Clip the image
	CGContextSaveGState(gc);
	CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
	CKCGAddRoundedRectToPath(gc, rect, radius);
	CGContextClip(gc);
	CGContextDrawImage(gc, CGRectMake(0, 0, w, h), self.CGImage);
	CGContextRestoreGState(gc);
	
	// Stroke the contour
	if ((strokeColor != nil) && (strokeColor != [UIColor clearColor])) {
		CGContextSaveGState(gc);
		CGContextSetStrokeColorWithColor(gc, strokeColor.CGColor);
		CGContextSetLineWidth(gc, 1.0);
		CKCGAddRoundedRectToPath(gc, CGRectInset(rect, 0.5, 0.5), radius);
		CGContextStrokePath(gc);
		CGContextRestoreGState(gc);
	}
	
	// Get the final image
	CGImageRef contextImage = CGBitmapContextCreateImage(gc);
	CGContextRelease(gc);
	CGColorSpaceRelease(colorSpace);
		
	UIImage *result = [UIImage imageWithCGImage:contextImage];
	CGImageRelease(contextImage);
	
    return result;
}

@end
