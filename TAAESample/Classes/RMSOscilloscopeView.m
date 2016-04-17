//
//  RMSOscilloscopeView.m
//  TAAESample
//
//  Created by 32BT on 17/04/16.
//  Copyright © 2016 A Tasty Pixel. All rights reserved.
//

#import "RMSOscilloscopeView.h"
@import Accelerate;

#define HSB(h, s, b) \
[NSColor colorWithHue:h/360.0 saturation:s brightness:b alpha:1.0]


@interface RMSOscilloscopeView ()
{
	CGPoint mT[kRMSOscilloscopeCount];
}
@end


////////////////////////////////////////////////////////////////////////////////
@implementation RMSOscilloscopeView
////////////////////////////////////////////////////////////////////////////////

- (BOOL) isOpaque
{ return YES; }

////////////////////////////////////////////////////////////////////////////////

- (void)drawRect:(NSRect)dirtyRect
{
#if !TARGET_OS_IOS
	[[NSColor whiteColor] set];
	NSRectFill(self.bounds);
#endif

	CGContextRef context = UIGraphicsGetCurrentContext();
	
	NSRect B = self.bounds;
	CGAffineTransform T = CGAffineTransformIdentity;
	T = CGAffineTransformTranslate(T, 1.5, B.size.height/2.0);
	CGFloat X = (B.size.width-3.0);
	CGFloat Y = (B.size.height-2.0) * pow(2.0, self.gain-1);
	T = CGAffineTransformScale(T, X, Y);
	
	CGPoint *L = (CGPoint *)self.pathL.bytes;
	if (L != nil)
	{
		// scale to bounds
		for (int n=0; n!=kRMSOscilloscopeCount; n++)
		{ mT[n] = CGPointApplyAffineTransform(L[n], T); }

		// draw as line segments
		[HSB(180.0, 1.0, 0.5) set];
		CGContextBeginPath(context);
		CGContextAddLines(context, mT, kRMSOscilloscopeCount);
		CGContextStrokePath(context);
	}

	CGPoint *R = (CGPoint *)self.pathR.bytes;
	if (R != nil)
	{
		// scale to bounds
		for (int n=0; n!=kRMSOscilloscopeCount; n++)
		{ mT[n] = CGPointApplyAffineTransform(R[n], T); }

		// draw as line segments
		[HSB(0.0, 1.0, 1.0) set];
		CGContextBeginPath(context);
		CGContextAddLines(context, mT, kRMSOscilloscopeCount);
		CGContextStrokePath(context);
	}

	[[NSColor blackColor] set];
	NSFrameRect(self.bounds);
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
