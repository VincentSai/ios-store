/*
 * Copyright (C) 2012 Soomla Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "StorageManager.h"
#import "KeyValDatabase.h"
#import "VirtualCurrencyStorage.h"
#import "VirtualGoodStorage.h"
#import "NonConsumableStorage.h"
#import "ObscuredNSUserDefaults.h"
#import "StoreConfig.h"
#import "StoreEncryptor.h"
#import "KeyValueStorage.h"
#import "StoreUtils.h"
#import "VirtualItemStorage.h"
#import "VirtualItem.h"
#import "VirtualGood.h"
#import "VirtualCurrency.h"

//@interface StorageManager (Private)
//- (void)migrateOldData;
//@end

@implementation StorageManager

@synthesize kvDatabase, virtualCurrencyStorage, virtualGoodStorage, nonConsumableStorage, keyValueStorage;

static NSString* TAG = @"SOOMLA StorageManager";

+ (StorageManager*)getInstance{
    static StorageManager* _instance = nil;
    
    @synchronized( self ) {
        if( _instance == nil ) {
            _instance = [[StorageManager alloc ] init];
        }
    }
    
    return _instance;
}

- (id)init{
    self = [super init];
    if (self){
        self.kvDatabase = [[KeyValDatabase alloc] init];
        self.virtualCurrencyStorage = [[VirtualCurrencyStorage alloc] init];
        self.virtualGoodStorage = [[VirtualGoodStorage alloc] init];
        self.nonConsumableStorage = [[NonConsumableStorage alloc] init];
        self.keyValueStorage = [[KeyValueStorage alloc] init];
        
        int mt_ver = [ObscuredNSUserDefaults intForKey:@"MT_VER" withDefaultValue:0];
        int sa_ver_old = [ObscuredNSUserDefaults intForKey:@"SA_VER_OLD" withDefaultValue:-1];
        int sa_ver_new = [ObscuredNSUserDefaults intForKey:@"SA_VER_NEW" withDefaultValue:1];
        if (mt_ver < METADATA_VERSION || sa_ver_old < sa_ver_new) {
            [ObscuredNSUserDefaults setInt:METADATA_VERSION forKey:@"MT_VER"];
            [ObscuredNSUserDefaults setInt:sa_ver_new forKey:@"SA_VER_OLD"];
            
            [kvDatabase deleteKeyValWithKey:[StoreEncryptor encryptString:[KeyValDatabase keyMetaStoreInfo]]];
            [kvDatabase deleteKeyValWithKey:[StoreEncryptor encryptString:[KeyValDatabase keyMetaStorefrontInfo]]];
        }
    }
    
    return self;
}

- (VirtualItemStorage*)virtualItemStorage:(VirtualItem*)item {
    VirtualItemStorage* storage = nil;
    
    if ([item isKindOfClass:[VirtualGood class]]) {
        storage = self.virtualGoodStorage;
    }else if ([item isKindOfClass:[VirtualCurrency class]]) {
        storage = self.virtualCurrencyStorage;
    }
    
    return storage;
}

+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    return success;
}

+ (NSString *) applicationDirectory
{
    static NSString* appDir = nil;
    
    if (appDir == nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        if ([paths count] == 0)
        {
            // *** creation and return of error object omitted for space
            return nil;
        }
        
        NSString *basePath = [paths objectAtIndex:0];
        NSError *error;
        
        NSFileManager *fManager = [NSFileManager defaultManager];
        if (![fManager fileExistsAtPath:basePath]) {
            if (![fManager createDirectoryAtPath:basePath
                     withIntermediateDirectories:YES
                                      attributes:nil
                                           error:&error])
            {
                LogError(TAG, ([NSString stringWithFormat:@"Create directory error: %@", error]));
                return nil;
            }
        }
        appDir = [basePath copy];
    }
    return appDir;
}

@end
