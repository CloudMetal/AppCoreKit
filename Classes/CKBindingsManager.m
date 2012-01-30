//
//  CKBindingsManager.m
//  CloudKit
//
//  Created by Sebastien Morel on 11-03-11.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import "CKBindingsManager.h"
#import "CKBinding.h"
#import "CKWeakRef.h"
#import <objc/runtime.h>

@interface CKBindingsManager ()
@property (nonatomic, retain) NSDictionary *bindingsPoolForClass;
@property (nonatomic, retain) NSDictionary *bindingsForContext;
@property (nonatomic, retain) NSMutableSet *contexts;
@end

static CKBindingsManager* CKBindingsDefauktManager = nil;
@implementation CKBindingsManager
@synthesize bindingsForContext = _bindingsForContext;
@synthesize bindingsPoolForClass = _bindingsPoolForClass;
@synthesize contexts = _contexts;

- (id)init{
	[super init];
	self.bindingsForContext = [NSMutableDictionary dictionary];
	self.bindingsPoolForClass = [NSMutableDictionary dictionary];
	self.contexts = [NSMutableSet set];
	return self;
}

- (void)dealloc{
	[_bindingsForContext release];
	[_bindingsPoolForClass release];
	[_contexts release];
	[super dealloc];
}

+ (CKBindingsManager*)defaultManager{
	if(CKBindingsDefauktManager == nil){
		CKBindingsDefauktManager = [[CKBindingsManager alloc]init];
	}
	return CKBindingsDefauktManager;
}

- (NSString*)description{
	return [_bindingsForContext description];
}

//The client should release the object returned !
- (id)dequeueReusableBindingWithClass:(Class)bindingClass{
	NSString* className = NSStringFromClass(bindingClass);//[NSString stringWithUTF8String:class_getName(bindingClass)];
	NSMutableArray* bindings = [_bindingsPoolForClass valueForKey:className];
	if(!bindings){
		bindings = [NSMutableArray array];
		[_bindingsPoolForClass setValue:bindings forKey:className];
	}
	
	if([bindings count] > 0){
		id binding = [[bindings lastObject]retain];
		[bindings removeLastObject];
		return binding;
	}
	
	return [[bindingClass alloc]init];
}

- (void)bind:(CKBinding*)binding withContext:(id)context{
    [binding bind];
    
	NSMutableSet* bindings = [_bindingsForContext objectForKey:context];
	if(!bindings){
		[_contexts addObject:context];
		bindings = [NSMutableSet setWithCapacity:500];
		[_bindingsForContext setObject:bindings forKey:context];
	}
	[bindings addObject:binding];
    binding.context = context;
}


- (void)unregister:(CKBinding*)binding{
	id context = binding.context;
    if(context == nil)
        return;
	
	NSMutableSet* bindings = [_bindingsForContext objectForKey:context];
	if(!bindings){
		//Already unbinded
		return;
	}
	
	//Put the binding in the reusable queue
	NSString* className = NSStringFromClass([binding class]);//[NSString stringWithUTF8String:class_getName([binding class])];
	NSMutableArray* queuedBindings = [_bindingsPoolForClass valueForKey:className];
	if(!queuedBindings){
		queuedBindings = [NSMutableArray array];
		[_bindingsPoolForClass setValue:queuedBindings forKey:className];
	}
    
	[queuedBindings addObject:binding];
    [bindings removeObject:binding];
    [binding reset];
	
    //Here we get the bindings again as [binding reset] could clear blocks retaining objects that could clear the same context ...
	bindings = [_bindingsForContext objectForKey:context];
	if(bindings && [bindings count] <= 0){
		[_bindingsForContext removeObjectForKey:context];
		[_contexts removeObject:context];
	}	
}

- (void)unbind:(CKBinding*)binding{
    [binding unbind];
	[self unregister:binding];
}

- (void)unbindAllBindingsWithContext:(id)context{
	NSMutableSet* bindings = [_bindingsForContext objectForKey:context];
	if(!bindings || [bindings count] <= 0){
		return;
	}
	
    //prevents unregistration while unbinding dependencies :
    //for example a block binding release a value that gets deallocated
    //another binding depends on this value and is notified via weakref
	for(CKBinding* binding in bindings){
        binding.context = nil;
    }
    
    for(CKBinding* binding in bindings){
        [binding unbind];
		
		NSString* className = NSStringFromClass([binding class]);//[NSString stringWithUTF8String:class_getName([binding class])];
		NSMutableArray* queuedBindings = [_bindingsPoolForClass valueForKey:className];
		if(!queuedBindings){
			queuedBindings = [NSMutableArray array];
			[_bindingsPoolForClass setValue:queuedBindings forKey:className];
		}
		[queuedBindings addObject:binding];
        [binding reset];
	}
    
	[_bindingsForContext removeObjectForKey:context];
	[_contexts removeObject:context];
}

@end
