//
//  RMSOscilloscopeView.m
//  TAAESample
//
//  Created by 32BT on 17/04/16.
//  Copyright © 2016 A Tasty Pixel. All rights reserved.
//

#import "RMSOscilloscopeView.h"
@import Accelerate;



////////////////////////////////////////////////////////////////////////////////
@implementation NSMutableData (RMSExtension)

+ (instancetype) floatArrayWithCapacity:(size_t)N;
{ return [self dataWithLength:N*sizeof(float)]; }

- (float *) mutablePtr
{ return (float *)self.mutableBytes; }

- (const float *) constPtr
{ return (const float *)self.bytes; }

@end
////////////////////////////////////////////////////////////////////////////////





#define HSB(h, s, b) \
[NSColor colorWithHue:h/360.0 saturation:s brightness:b alpha:1.0]


@interface RMSOscilloscopeView ()
{
	float mX[kRMSOscilloscopeCount];
	float mY[kRMSOscilloscopeCount];
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
	
	NSRect B = self.bounds;
	
	// initialize x coordinates using Accelerate framework
	const vDSP_Length N = kRMSOscilloscopeCount;
	float offsetX = 1.0;
	float stepX = (B.size.width-2.0)/(kRMSOscilloscopeCount-1);
	vDSP_vramp(&offsetX, &stepX, mX, 1, N);
	
	// draw samples for left channel in blue, if available
	const float *L = (const float *)self.dataL.bytes;
	if (L != nil)
	{
		[HSB(180.0, 1.0, 0.5) set];
		[self drawSamples:L];
	}

	// draw samples for right channel in red, if available
	const float *R = (const float *)self.dataR.bytes;
	if (R != nil)
	{
		[HSB(0.0, 1.0, 1.0) set];
		[self drawSamples:R];
	}

	// frame view with black
	[[NSColor blackColor] set];
	NSFrameRect(self.bounds);
}

////////////////////////////////////////////////////////////////////////////////

- (void)drawSamples:(const float *)S
{
	// prepare transform for y coordinates
	NSRect B = self.bounds;
	float offsetY = 0.5 * B.size.height;
	float scaleY = (B.size.height-2.0) * pow(2.0, self.gain-1);

	// transform y coordinates using Accelerate framework
	vDSP_vsmsa(S, 1, &scaleY, &offsetY, mY, 1, kRMSOscilloscopeCount);
	
	// draw coordinates as connected lines
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, mX[0], mY[0]);
	for (int n=1; n!=kRMSOscilloscopeCount; n++)
	{ CGContextAddLineToPoint(context, mX[n], mY[n]); }
	
	// NOTE: this is the slowboat call:
	CGContextStrokePath(context);
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
