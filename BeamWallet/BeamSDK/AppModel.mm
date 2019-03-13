//
//  AppModel.m
//  BeamTest
//
// 2/28/19.
// Copyright 2018 Beam Development
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Reachability.h"

#import "AppModel.h"
#import "Settings.h"
#import "StringStd.h"
#import "MnemonicModel.h"
#import "WalletModel.h"

#import <SSZipArchive/SSZipArchive.h>

#include "wallet/wallet.h"
#include "wallet/wallet_db.h"
#include "wallet/wallet_network.h"
#include "wallet/wallet_model_async.h"
#include "wallet/wallet_client.h"

#include "utility/bridge.h"
#include "utility/string_helpers.h"
#include "utility/options.h"

#include "mnemonic/mnemonic.h"

#include "common.h"

using namespace beam;
using namespace ECC;
using namespace std;


@implementation AppModel  {
    Reachability *internetReachableFoo;

    IWalletDB::Ptr walletDb;
    WalletModel::Ptr wallet;

    ECC::NoLeak<ECC::uintBig> passwordHash;
    
    NSString *pathLog;
}

+ (AppModel*_Nonnull)sharedManager {
    static AppModel *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

-(id)init{
    self = [super init];
    
    [self createLogger];
    
    _delegates = [[NSHashTable alloc] init];
    
    _transactions = [[NSMutableArray alloc] init];
    
    [self checkEthernetConnection];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshAllInfo)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];

    
    return self;
}

-(void)createLogger {
    NSString *dataPath = [Settings logPath];

    po::variables_map vm;
    
    static auto logger = beam::Logger::create(LOG_LEVEL_DEBUG,LOG_LEVEL_DEBUG,LOG_LEVEL_DEBUG,@"beam_".string,dataPath.string);
    
    auto path = logger->get_current_file_name();
    pathLog =  [NSString stringWithUTF8String:path.c_str()];
    
    LOG_INFO() << "APP RUNNING";
}

-(void)checkEthernetConnection{
    internetReachableFoo = [Reachability reachabilityWithHostName:@"www.google.com"];
    
    internetReachableFoo.reachableBlock = ^(Reachability*reach)
    {
        if (![[AppModel sharedManager] isInternetAvailable]) {
            [[AppModel sharedManager] refreshAllInfo];
        }
        
        [[AppModel sharedManager] setIsInternetAvailable:YES];
    };
    
    internetReachableFoo.unreachableBlock = ^(Reachability*reach)
    {
        [[AppModel sharedManager] setIsInternetAvailable:NO];
        [[AppModel sharedManager] setIsConnected:NO];
        
        for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
        {
            if ([delegate respondsToSelector:@selector(onNetwotkStatusChange:)]) {
                [delegate onNetwotkStatusChange:NO];
            }
        }
    };
    
    [internetReachableFoo startNotifier];
}

-(void)setIsConnected:(BOOL)isConnected {
    if(isConnected && _isConnected==NO && wallet!=nil){
        [self getWalletStatus];
    }
    _isConnected = isConnected;
}


-(BOOL)isWalletAlreadyAdded {
    return [[NSFileManager defaultManager] fileExistsAtPath:Settings.walletStoragePath];
}

-(BOOL)openWallet:(NSString*)pass {
    Rules::get().UpdateChecksum();

    string dbFilePath = Settings.walletStoragePath.string;

    if (!walletDb) {
        walletDb = WalletDB::open(dbFilePath, pass.string);
        if (!walletDb){
            return NO;
        }
    }
    
    [self onWalledOpened:SecString(pass.string)];

    return YES;
}

-(BOOL)canOpenWallet:(NSString*)pass {
    Rules::get().UpdateChecksum();

    string dbFilePath = Settings.walletStoragePath.string;

    walletDb = WalletDB::open(dbFilePath, pass.string);
    if (!walletDb) {
        return NO;
    }
    
    return YES;
}

-(BOOL)createWallet:(NSString*)phrase pass:(NSString*)pass {
    Rules::get().UpdateChecksum();

    string dbFilePath = Settings.walletStoragePath.string;

    //already created. restore wallet?
    if (WalletDB::isInitialized(dbFilePath)) {
        return NO;
    }
    
    //invalid parameters
    if (phrase.isEmpty || pass.isEmpty) {
        return NO;
    }
    
    //convert string phrase to mnemonic WordList
    NSArray *wordsArray = [phrase componentsSeparatedByString:@";"];
    
    vector<string> wordList(wordsArray.count);
    
    for(int i=0; i<wordsArray.count; ++i){
        NSString *word = wordsArray[i];
        wordList[i] = word.string;
    }
    
    auto buf = decodeMnemonic(wordList);
    
    beam::SecString seed;
    seed.assign(buf.data(), buf.size());

    //create wallet db
    walletDb = WalletDB::init(dbFilePath, SecString(pass.string), seed.hash());
    
    if (!walletDb) {
        return NO;
    }
    
    // generate default address
    auto address = wallet::createAddress(*walletDb);
    address.m_label = "default";
    walletDb->saveAddress(address);
    
    [self onWalledOpened:SecString(pass.string)];
    
    return YES;
}

-(void)resetWallet{
    walletDb.reset();
    wallet.reset();
    
    [[NSFileManager defaultManager] removeItemAtPath:Settings.walletStoragePath error:nil];
}

-(void)onWalledOpened:(const SecString&) pass {
    passwordHash = pass.hash();
    
    [self start];
}

-(void)start {
    string nodeAddr = Settings.nodeAddress.string;
    
    wallet = make_shared<WalletModel>(walletDb, nodeAddr);
    
    wallet->getAsync()->setNodeAddress(nodeAddr);
    
    wallet->start();
}


-(void)refreshWallet {
    wallet->getAsync()->refresh();
}

-(void)getWalletStatus {
    wallet->getAsync()->getWalletStatus();
}

-(void)getNetworkStatus {
    wallet->getAsync()->getNetworkStatus();
}

-(void)refreshAllInfo{
    [internetReachableFoo stopNotifier];
    [internetReachableFoo startNotifier];
    
    if (wallet != nil) {
        [self getNetworkStatus];
    }
}

//TODO: TMP Solution
-(NSString* _Nullable)getWalletFirstAddress {
    auto addresses = walletDb->getAddresses(true);
    
    return [NSString stringWithUTF8String:to_string(addresses[0].m_walletID).c_str()];
}

#pragma mark - Address

-(BOOL)isValidAddress:(NSString*_Nonnull)address {
    WalletID walletID(Zero);
    return walletID.FromHex(address.string);
}

-(void)setExpires:(int)hours toAddress:(NSString*)address {
    WalletID walletID(Zero);
    if (walletID.FromHex(address.string))
    {
        std::vector<WalletAddress> addresses = walletDb->getAddresses(true);
        
        for (int i=0; i<addresses.size(); i++)
        {
            NSString *wAddress = [NSString stringWithUTF8String:to_string(addresses[i].m_walletID).c_str()];
            
            if ([wAddress isEqualToString:address])
            {
                addresses[i].m_duration = hours * 60 * 60;
                
                walletDb->saveAddress(addresses[i]);
                
                break;
            }
        }
    }
}

-(void)setWalletComment:(NSString*)comment toAddress:(NSString*_Nonnull)address {
    WalletID walletID(Zero);
    if (walletID.FromHex(address.string))
    {
        std::vector<WalletAddress> addresses = walletDb->getAddresses(true);
        
        for (int i=0; i<addresses.size(); i++)
        {
            NSString *wAddress = [NSString stringWithUTF8String:to_string(addresses[i].m_walletID).c_str()];
            
            if ([wAddress isEqualToString:address])
            {
                addresses[i].m_label = comment.string;
                
                walletDb->saveAddress(addresses[i]);
                
                break;
            }
        }
    }
}

-(void)generateNewWalletAddress {    
    wallet->getAsync()->generateNewAddress();
}

#pragma mark - Delegates

-(void)addDelegate:(id<WalletModelDelegate>) delegate{
    [_delegates addObject: delegate];
}

-(void)removeDelegate:(id<WalletModelDelegate>) delegate {
    [_delegates removeObject: delegate];
}

#pragma mark - Send

-(BOOL)canSend:(double)amount fee:(double)fee {
    if(amount==0)
    {
        return NO;
    }
    
    Amount bAmount = round(amount * Rules::Coin);
    Amount bTotal = bAmount + fee;
    return (_walletStatus.available >= bTotal);
}

-(NSString*)sendError:(double)amount fee:(double)fee {
    Amount bAmount = round(amount * Rules::Coin);
    Amount bTotal = bAmount + fee;
    
    if (amount==0) {
        return @"Amount can't be 0";
    }
    else if(_walletStatus.available <= bTotal)
    {
        double need = double(int64_t(bTotal - _walletStatus.available)) / Rules::Coin;
        
        NSNumberFormatter *currencyFormatter = [NSNumberFormatter new];
        currencyFormatter.usesGroupingSeparator = true;
        currencyFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        currencyFormatter.currencyCode = @"";
        currencyFormatter.currencyCode = @"";
        currencyFormatter.minimumIntegerDigits = 0;
        currencyFormatter.minimumFractionDigits = 0;
        currencyFormatter.minimumSignificantDigits = 0;
        currencyFormatter.maximumIntegerDigits = 20;
        currencyFormatter.maximumFractionDigits = 20;
        currencyFormatter.maximumSignificantDigits = 20;
        
        NSString *beam = [currencyFormatter stringFromNumber:[NSNumber numberWithDouble:need]];
        
        return [NSString stringWithFormat:@"Insufficient funds: you would need %@ beams to complete the transaction",beam];
    }
    else{
        return @"";
    }
}

-(void)send:(double)amount fee:(double)fee to:(NSString*_Nonnull)to comment:(NSString*_Nonnull)comment {
    
    WalletID walletID(Zero);
    if (walletID.FromHex(to.string))
    {
        wallet->getAsync()->sendMoney(walletID, comment.string, amount * Rules::Coin,fee);
    }
}

-(NSString*)getZipLogs {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = [paths objectAtIndex:0];
    
    BOOL isDir=NO;
    
    NSArray *subpaths;
    
    NSString *exportPath = docDirectory;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
   
    if ([fileManager fileExistsAtPath:exportPath isDirectory:&isDir] && isDir){
        subpaths = [fileManager subpathsAtPath:exportPath];
    }
    
    NSString *archivePath = [docDirectory stringByAppendingString:@"/logs.zip"];
    
    [SSZipArchive createZipFileAtPath:archivePath withContentsOfDirectory:[Settings logPath]];
    
    return archivePath;
    
//    NSArray * directoryContents =  [[NSFileManager defaultManager]
//                                    contentsOfDirectoryAtPath:[Settings logPath] error:nil];
//
//    for(NSString *file in directoryContents)
//    {
//        NSString *content = [NSString stringWithContentsOfFile:[[Settings logPath]stringByAppendingPathComponent:file] encoding:NSUTF8StringEncoding error:NULL];
//        NSLog(@"%@",content);
//    }
}

@end
