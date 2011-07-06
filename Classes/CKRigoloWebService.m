//
//  CKRigoloWebService.m
//  CloudKit
//
//  Created by Sebastien Morel on 11-07-05.
//  Copyright 2011 Wherecloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CKRigoloWebService.h"
#import "CKMapping.h"
#import "CKRigoloDefaultBehaviour.h"
#import "CKNSObject+Invocation.h"

static CKRigoloDefaultBehaviour* CKRigoloDefaultBehaviourInstance = nil;

@implementation CKRigoloItem
@synthesize bundleIdentifier,applicationName,releaseDate,buildVersion,releaseNotes,releaseNotesURL,overTheAirURL;
@end


static NSMutableDictionary* CKRigoloItemMappings = nil;
@interface CKRigoloWebService ()
- (NSMutableDictionary*)rigoloItemMapping;
- (void)onBecomeActive:(NSNotification*)notif;
@end


@implementation CKRigoloWebService
@synthesize delegate = _delegate;


- (id)init {
	[super init];
    self.baseURL = [NSURL URLWithString:@"http://rigolo-api.wherecloud.com/v1/app/"];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    if(CKRigoloDefaultBehaviourInstance == nil){
        CKRigoloDefaultBehaviourInstance = [[CKRigoloDefaultBehaviour alloc]init];
    }
    self.delegate = CKRigoloDefaultBehaviourInstance;
    return self;
}

- (NSMutableDictionary*)rigoloItemMapping{
    if(CKRigoloItemMappings == nil){
        NSMutableDictionary* mappings = [NSMutableDictionary dictionary];
        [mappings mapStringForKeyPath:@"bundle-identifier"  toKeyPath:@"bundleIdentifier"   required:YES];
        [mappings mapStringForKeyPath:@"name"               toKeyPath:@"applicationName"    required:YES];
        [mappings mapDateForKeyPath:  @"release-date"       toKeyPath:@"releaseDate"        required:YES];
        [mappings mapStringForKeyPath:@"build-version"      toKeyPath:@"buildVersion"       required:YES];
        [mappings mapStringForKeyPath:@"release-notes-text" toKeyPath:@"releaseNotes"       required:YES];
        [mappings mapURLForKeyPath:   @"release-notes-url"  toKeyPath:@"releaseNotesURL"    required:NO];
        [mappings mapURLForKeyPath:   @"ota-url"            toKeyPath:@"overTheAirURL"      required:YES];
        CKRigoloItemMappings = mappings;
    }
    return CKRigoloItemMappings;
}

- (void)onBecomeActive:(NSNotification*)notif{
    [self check];
}

- (void)check{
    NSString* buildVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString* bundleIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    CKWebRequest2* request = [self getRequestForPath:@"check.json" params:[NSDictionary dictionaryWithObjectsAndKeys:bundleIdentifier,@"bundle-identifier",buildVersion,@"build-version",nil]];
    request.successBlock = ^(id value){
        NSString* upToDate = [value objectForKey:@"uptodate"];
        NSString* buildVersion = [value objectForKey:@"latestbuild"];
        if([upToDate isEqualToString:@"true"]){
            if([_delegate respondsToSelector:@selector(rigoloWebService:isUpToDateWithVersion:)]){
                [_delegate performSelector:@selector(rigoloWebService:isUpToDateWithVersion:) withObject:self withObject:buildVersion];
            }
        }
        else{
            if([_delegate respondsToSelector:@selector(rigoloWebService:needsUpdateToVersion:)]){
                [_delegate performSelector:@selector(rigoloWebService:needsUpdateToVersion:) withObject:self withObject:buildVersion];
            }
        }
    };
    request.failureBlock = ^(NSError* error){
        NSLog(@"RIGOLO CHECK ERROR : %@",error);
        if([_delegate respondsToSelector:@selector(rigoloWebService:checkFailedWithError:)]){
            [_delegate performSelector:@selector(rigoloWebService:checkFailedWithError:) withObject:self withObject:error];
        }
    };
    
    [self performRequest:request];
}

- (void)list{
    NSString* bundleIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    CKWebRequest2* request = [self getRequestForPath:@"list.json" params:[NSDictionary dictionaryWithObjectsAndKeys:bundleIdentifier,@"bundle-identifier",nil]];
    request.transformBlock = ^(id value){
        NSMutableArray* items = [NSMutableArray array];
        NSError* error;
        for(NSDictionary* dico in value){
            CKRigoloItem* item = [[[CKRigoloItem alloc]initWithDictionary:dico withMappings:[self rigoloItemMapping] error:&error]autorelease];
            [items addObject:item];
        }
        return (id)items;
    };
    request.successBlock = ^(id value){
        if([_delegate respondsToSelector:@selector(rigoloWebService:didReceiveItemList:)]){
            [_delegate performSelector:@selector(rigoloWebService:didReceiveItemList:) withObject:self withObject:value];
        }
    };
    request.failureBlock = ^(NSError* error){
        NSLog(@"RIGOLO LIST ERROR : %@",error);
        if([_delegate respondsToSelector:@selector(rigoloWebService:listFailedWithError:)]){
            [_delegate performSelector:@selector(rigoloWebService:listFailedWithError:) withObject:self withObject:error];
        }
    };
    
    [self performRequest:request];
}

- (void)detailsForVersion:(NSString*)version{
    NSString* bundleIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    CKWebRequest2* request = [self getRequestForPath:@"descriptor.json" params:[NSDictionary dictionaryWithObjectsAndKeys:bundleIdentifier,@"bundle-identifier",version,@"bundle-version",nil]];
    request.transformBlock = ^(id value){
        NSError* error;
        CKRigoloItem* item = [[[CKRigoloItem alloc]initWithDictionary:value withMappings:[self rigoloItemMapping] error:&error]autorelease];
        return (id)item;
    };
    request.successBlock = ^(id value){
        if([_delegate respondsToSelector:@selector(rigoloWebService:didReceiveDetails:)]){
            [_delegate performSelector:@selector(rigoloWebService:didReceiveDetails:) withObject:self withObject:value];
        }
    };
    request.failureBlock = ^(NSError* error){
        NSLog(@"RIGOLO DESCRIPTOR ERROR : %@",error);
        if([_delegate respondsToSelector:@selector(rigoloWebService:detailsForVersion:failedWithError:)]){
            [_delegate performSelector:@selector(rigoloWebService:detailsForVersion:failedWithError:) withObjects:[NSArray arrayWithObjects:self,version,error,nil]];
        }
    };
    
    [self performRequest:request];
}

- (void)install:(CKRigoloItem*)item{
    [[UIApplication sharedApplication]openURL:item.overTheAirURL];
}

@end
