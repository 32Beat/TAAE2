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


@implementation RMSOscilloscopeController

- (void) updateWithRingBufferModule:(AERingBufferModule *)ringBuffer
{
	NSMutableData *dataL = nil;
	NSMutableData *dataR = nil;
	
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
		
		// create room for dst samples
		dataL = [NSMutableData floatArrayWithCapacity:kRMSOscilloscopeCount];
		dataR = [NSMutableData floatArrayWithCapacity:kRMSOscilloscopeCount];
		
		// get corresponding pointers
		float *L = (float *)dataL.mutableBytes;
		float *R = (float *)dataR.mutableBytes;
		
		// move index to oldest src sample
		index -= kRMSOscilloscopeCount*srcStep;
		// work towards newest src sample
		for (int n = 0; n!=kRMSOscilloscopeCount; n++)
		{
			L[n] = srcPtrL[index&indexMask];
			R[n] = srcPtrR[index&indexMask];
			index += srcStep;
		}
	}

	// reduce updates, particularly if nil when inactive
	if ((self.view.dataL != dataL)||
		(self.view.dataR != dataR))
		dispatch_async(dispatch_get_main_queue(),
		^{
			self.view.dataL = dataL;
			self.view.dataR = dataR;
			[self.view setNeedsDisplay];
		});
}

@end
