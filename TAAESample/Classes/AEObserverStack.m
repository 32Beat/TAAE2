//
//  AEObserverStack.m
//  TAAESample
//
//  Created by 32BT on 13/04/16.
//  Copyright © 2016 A Tasty Pixel. All rights reserved.
//

#import "AEObserverStack.h"

@interface AEObserverStack ()
{
	NSHashTable *mTable;
}
@end

////////////////////////////////////////////////////////////////////////////////
@implementation AEObserverStack
////////////////////////////////////////////////////////////////////////////////

- (void) addObserver:(id)observer
{
	if ([mTable containsObject:observer])
	{
		NSLog(@"%@", @"attempt to add object more than once!");
		return;
	}
	
	if ([self.delegate observerStack:self willAddObserver:observer])
	{
		if (mTable == nil)
		{ mTable = [NSHashTable weakObjectsHashTable]; }
		[mTable addObject:observer];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) removeObserver:(id)observer
{
	if ([mTable containsObject:observer])
	{
		[mTable removeObject:observer];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateObservers
{ [self updateObserversUsingSelector:self.updateSelector]; }

- (void) updateObserversUsingSelector:(SEL)selector
{ [self updateObserversUsingSelector:selector withObject:self.delegate]; }

////////////////////////////////////////////////////////////////////////////////

- (void) updateObserversUsingSelector:(SEL)selector withObject:(id)object
{
	for(id observer in mTable)
	{
		[observer performSelector:selector withObject:object];
		if ([self.delegate respondsToSelector:
			@selector(observerStack:didUpdateObserver:)])
		{ [self.delegate observerStack:self didUpdateObserver:observer]; }
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateObserversConcurrentlyUsingSelector:(SEL)selector object:(id)object
{
	[[mTable allObjects] enumerateObjectsWithOptions:NSEnumerationConcurrent
	usingBlock:^(id observer, NSUInteger index, BOOL *stop)
	{
		[observer performSelector:selector withObject:object];
		if ([self.delegate respondsToSelector:
			@selector(observerStack:didUpdateObserver:)])
		{
			dispatch_async(dispatch_get_main_queue(),
			^{ [self.delegate observerStack:self didUpdateObserver:observer]; });
		}
	}];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////




