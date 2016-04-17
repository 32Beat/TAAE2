//
//  RMSOscilloscopeController.m
//  TAAESample
//
//  Created by 32BT on 17/04/16.
//  Copyright © 2016 A Tasty Pixel. All rights reserved.
//
////////////////////////////////////////////////////////////////////////////////
/*
	RMSOscilloscopeController
	-------------------------
	An object for displaying a waveform of the samples in a ringBuffer.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSOscilloscopeController.h"


@interface RMSOscilloscopeController ()
@end

@implementation RMSOscilloscopeController


- (void) updateWithRingBufferModule:(AERingBufferModule *)ringBuffer
{
	NSMutableData *pathL = nil;
	NSMutableData *pathR = nil;
	
	// Check ringBuffer state
	if (ringBuffer.isActive)
	{
		// Get available range and buffer read parameters
		AERange range = [ringBuffer availableRange];
		uint64_t index = range.index + range.count - 1;
		uint64_t indexMask = [ringBuffer indexMask];
		const float *srcPtrL = [ringBuffer samplePtrAtIndex:0];
		const float *srcPtrR = [ringBuffer samplePtrAtIndex:1];

		/*
			we want to traverse about 1/24th second worth of samples,
			preferably with a fixed amount. So we compute a stepsize 
			for source index. It should be at least 1.
		*/
		Float64 samplesPerUpdate = ringBuffer.renderer.sampleRate/24.0;
		Float64 samplesPerStep = samplesPerUpdate / (kRMSOscilloscopeCount-1);
		int srcStep = samplesPerStep + 0.5;
		srcStep = MAX(1, srcStep);
		
		// start of curve
		CGPoint P = { 0.0, 0.0 };
		// count points means (count-1) steps
		CGFloat dx = 1.0/(kRMSOscilloscopeCount-1);

		// dst points
		pathL = [NSMutableData dataWithLength:kRMSOscilloscopeCount * sizeof(CGPoint)];
		pathR = [NSMutableData dataWithLength:kRMSOscilloscopeCount * sizeof(CGPoint)];
		
		CGPoint *L = (CGPoint *)pathL.mutableBytes;
		CGPoint *R = (CGPoint *)pathR.mutableBytes;
		
		// start at first point
		index -= kRMSOscilloscopeCount*srcStep;
		// work towards last point
		for (int n = 0; n!=kRMSOscilloscopeCount; n++)
		{
			P.y = srcPtrL[index&indexMask];
			L[n] = P;
			P.y = srcPtrR[index&indexMask];
			R[n] = P;

			index += srcStep;
			P.x += dx;
		}
	}

	// reduce updates, particularly if nil when inactive
	if ((self.view.pathL != pathL)||
		(self.view.pathR != pathR))
		dispatch_async(dispatch_get_main_queue(),
		^{
			self.view.pathL = pathL;
			self.view.pathR = pathR;
			[self.view setNeedsDisplay];
		});
}

@end
