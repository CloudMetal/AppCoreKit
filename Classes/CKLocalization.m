//
//  CKLocalization.m
//  AppCoreKit
//
//  Created by Olivier Collet.
//  Copyright 2010 WhereCloud Inc. All rights reserved.
//

#import "CKLocalization.h"
#import "CKLocalizationManager_Private.h"
#import "CKLiveProjectFileUpdateManager.h"
#import "NSObject+Singleton.h"
#import "CKCascadingTree.h"

NSString *CKLocalizationCurrentLocalization(void) {
	NSArray *l18n = [[NSBundle mainBundle] preferredLocalizations];
	return [l18n objectAtIndex:0];
}

static NSMutableArray* kLocalizationStringTableNames = nil;

void CKResetLanguageFileCache(){
    [kLocalizationStringTableNames release];
    kLocalizationStringTableNames = nil;
}

NSString* CKGetLocalizedString(NSBundle* bundle,NSString* key,NSString* value){
    //Find all localization tables
    if(kLocalizationStringTableNames == nil){
        NSMutableArray* files = [NSMutableArray array];
        
        NSArray* stringsURLs = [bundle URLsForResourcesWithExtension:@"strings" subdirectory:nil];
        
#if TARGET_IPHONE_SIMULATOR        
        NSMutableArray *newStringsURL = [NSMutableArray arrayWithCapacity:stringsURLs.count];
        for (NSURL *filePathURL in stringsURLs) {
            NSString *localPath = [[CKLiveProjectFileUpdateManager sharedInstance] projectPathOfFileToWatch:filePathURL.path handleUpdate:^(NSString *localPath) {
                NSString *tempPath = NSTemporaryDirectory();
                tempPath = [tempPath stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
                
                [[NSFileManager defaultManager] createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:nil];
                
                for (NSURL *URL in newStringsURL) {
                    NSString *localizationPath = [tempPath stringByAppendingPathComponent:URL.path.stringByDeletingLastPathComponent.lastPathComponent];
                    [[NSFileManager defaultManager] createDirectoryAtPath:localizationPath withIntermediateDirectories:YES attributes:nil error:nil];
                    
                    NSString *lastPath = [localizationPath stringByAppendingPathComponent:URL.lastPathComponent];
                    [[NSFileManager defaultManager] copyItemAtPath:localPath toPath:lastPath error:nil];
                }
                
                [[CKLocalizationManager sharedManager] reloadBundleAtPath:tempPath];
                
                [[CKLocalizationManager sharedManager] refreshUI];
                [[NSNotificationCenter defaultCenter] postNotificationName:CKCascadingTreeFilesDidUpdateNotification object:nil];
            }];
            
            [newStringsURL addObject:[NSURL fileURLWithPath:localPath]];
        }
        
        stringsURLs = newStringsURL;
#endif
        
        for(NSURL* stringsURL in stringsURLs){
            NSString* fileName = [[stringsURL absoluteString]lastPathComponent];
            NSRange range = [fileName rangeOfString:@"."];
            if(range.location != NSNotFound){
                NSString* file = [fileName substringToIndex:range.location];
                //priority to application table
                if([file isEqualToString:@"Localizable"]){
                    [files insertObject:file atIndex:0];
                }
                [files addObject:file];
            }
        }
        kLocalizationStringTableNames = [files retain];
    }
    
    for(NSString* tableName in kLocalizationStringTableNames){
        NSString* result =  [bundle localizedStringForKey:key value:value table:tableName];
        if(![result isEqualToString:key])
            return result;
    }
    return value;
}

CKLocalizedString* CKLocalizedStringWithString(NSString* string){
    if([string isKindOfClass:[CKLocalizedString class]]){
        return (CKLocalizedString*)string;
    }
    return [[[CKLocalizedString alloc]initWithLocalizedKey:string]autorelease];
}
