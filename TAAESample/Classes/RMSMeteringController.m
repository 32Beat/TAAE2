//
//  RMSMeteringController.m
//  TAAESample
//
//  Created by 32BT on 11/04/16.
//  Copyright © 2016 A Tasty Pixel. All rights reserved.
//

#import "RMSMeteringController.h"
#import "rmslevels_t.h"
#import "RMSLevelsView.h"


@interface RMSMeteringController ()
{
	uint64_t mIndex;
	
	Float64 mEngineRate;
	rmsengine_t mEngineL;
	rmsengine_t mEngineR;
	
	IBOutlet RMSLevelsView *mLevelsViewL;
	IBOutlet RMSLevelsView *mLevelsViewR;
}
@end

@implementation RMSMeteringController

// This is called in a backgroundthread, but not the audiothread
// so we are free to use whatever language constructs we like

- (void) updateWithRingBufferModule:(AERingBufferModule *)ringBuffer
{
	// Reinitialize engines if necessary
	Float64 sampleRate = ringBuffer.renderer.sampleRate;
	if (mEngineRate != sampleRate)
	{
		mEngineRate = sampleRate;
		mEngineL = RMSEngineInit(sampleRate);
		mEngineR = RMSEngineInit(sampleRate);
	}
	
	// Compute samplerange since last update
	AERange range = [ringBuffer availableRange];
	
	if (mIndex < range.index)
	{ mIndex = range.index; }
	range.count -= mIndex-range.index;
	
	// Process samples
	for (uint64_t n=range.count; n!=0; n--)
	{
		RMSEngineAddSample(&mEngineL, [ringBuffer valueAtIndex0:mIndex]);
		RMSEngineAddSample(&mEngineR, [ringBuffer valueAtIndex1:mIndex]);
		mIndex += 1;
	}
	
	// Transfer result to view on main
	rmsresult_t L = RMSEngineFetchResult(&mEngineL);
	rmsresult_t R = RMSEngineFetchResult(&mEngineR);
	
	dispatch_async(dispatch_get_main_queue(),
	^{
		mLevelsViewL.levels = L;
		mLevelsViewR.levels = R;
	});
}


@end
