#import "WalletCore.h"
#import <Bip39/Bbc.objc.h>
#import <Bip39/Crypto.objc.h>
#import "WalletUtils.h"

@implementation WalletCore

+ (void)callFunc:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSArray *allFunc = @[
        @"generateMnemonic", 
        @"validateMnemonic", 
        @"importMnemonic",
        @"exportPrivateKey",
        @"signTx", 
        @"signMsg",
        @"signMsgWithPKAndBlake",
    ];
    NSUInteger func = [allFunc indexOfObject:call.method];
    
    switch(func){
        case 0:
            [self generateMnemonic:call result:result];
            break;
        case 1:
            [self validateMnemonic:call result:result];
            break;
        case 2:
            [self importMnemonic:call result:result];
            break;
        case 3:
            [self exportPrivateKey:call result:result];
            break;
        case 4:
            [self signTx:call result:result];
            break;
        case 5:
            [self signMsg:call result:result];
            break;
        case 6:
            [self signMsgWithPKAndBlake:call result:result];
            break;
        default:
            return;
    }
}

+ (WalletWallet*) getWalletInstance:(NSMutableDictionary*)arguments
                              error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    
    NSString* mnemonic = arguments[@"mnemonic"];
    NSString* path = arguments[@"path"];
    NSString* password = arguments[@"password"];
    bool beta = [arguments[@"beta"] boolValue];
    bool useBip44 = [arguments[@"useBip44"] boolValue];
    bool shareAccountWithParentChain = arguments[@"shareAccountWithParentChain"];

    WalletWalletOptions* options = [WalletWalletOptions new];
    
    // Common configs
    id<WalletWalletOption> pathOption = WalletWithPathFormat(path);
    id<WalletWalletOption> passwordOption = WalletWithPassword(password);
    id<WalletWalletOption> shareAccountWithParentChainOption = WalletWithShareAccountWithParentChain(shareAccountWithParentChain);
    [options add:pathOption];
    [options add:passwordOption];
    [options add:shareAccountWithParentChainOption];

    if(useBip44 == YES) {
        id<WalletWalletOption> withFlagBBC = WalletWithFlag(WalletFlagBBCUseStandardBip44ID);
        [options add:withFlagBBC];
    }

    WalletWallet* wallet = WalletBuildWalletFromMnemonic(mnemonic, beta, options, error);
    return wallet;
}

+ (void)generateMnemonic:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSError* __autoreleasing error;
    NSString* mnemonic = WalletNewMnemonic(&error);
    if (error) {
        result([FlutterError errorWithCode:@"GenerateMnemonicError" message:error.localizedDescription details:nil]);
        return;
    }
    result(mnemonic);
}

+ (void)validateMnemonic:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSError* __autoreleasing error;
    NSString* mnemonic = call.arguments;
    @try
    {
        WalletValidateMnemonic(mnemonic, &error);
        if (error) {
            result([FlutterError errorWithCode:@"MnemonicError" message:error.localizedDescription details:nil]);
            return;
        }
        result(@(YES));
    }
    @catch(NSException *exception) {
        result([FlutterError errorWithCode:@"Error" message:exception.reason details:nil]);
        return;
    }
}

+ (void)importMnemonic:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSError* __autoreleasing error;
    NSString* mnemonic = call.arguments[@"mnemonic"];
    NSString* symbolsAll = call.arguments[@"symbols"];
    
    @try
    {
        WalletValidateMnemonic(mnemonic, &error);
        if (error) {
            result([FlutterError errorWithCode:@"MnemonicError" message:@"Mnemonic is invalid" details:nil]);
            return;
        }
        
        WalletWallet* wallet = [self getWalletInstance:call.arguments error:&error];
        if (error) {
            result([FlutterError errorWithCode:@"ImportMnemonicError" message:error.localizedDescription details:nil]);
            return;
        }
        
        NSArray *symbols = [symbolsAll componentsSeparatedByString: @","];
        NSMutableDictionary *keyInfo = [NSMutableDictionary dictionaryWithCapacity:[symbols count]];

        for (NSString *symbol in symbols) {
            NSMutableDictionary *keys = [NSMutableDictionary dictionaryWithCapacity:3];
            keys[@"address"] = [wallet deriveAddress:symbol error:&error];
            keys[@"publicKey"] = [wallet derivePublicKey:symbol error:&error];
            keys[@"privateKey"] = [wallet derivePrivateKey:symbol error:&error];
            if (error) {
                result([FlutterError errorWithCode:@"DeriveAddressError" message:error.localizedDescription details:nil]);
                return;
            }
            keyInfo[symbol] = keys;
        }
        result(keyInfo);
    }
    @catch(NSException *exception) {
        result([FlutterError errorWithCode:@"Error" message:exception.reason details:nil]);
        return;
    }
}

+ (void)exportPrivateKey:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSError* __autoreleasing error;
    NSString* mnemonic = call.arguments[@"mnemonic"];
    NSString* symbol = call.arguments[@"symbol"];
    
    @try
    {
        WalletValidateMnemonic(mnemonic, &error);
        if (error) {
            result([FlutterError errorWithCode:@"MnemonicError" message:@"Mnemonic is invalid" details:nil]);
            return;
        }
        
        WalletWallet* wallet = [self getWalletInstance:call.arguments error:&error];
        if (error) {
            result([FlutterError errorWithCode:@"ExportPrivateKeyError" message:error.localizedDescription details:nil]);
            return;
        }
        
        NSString* privateKey = [wallet derivePrivateKey:symbol error:&error];
        
        if (error) {
            result([FlutterError errorWithCode:@"ExportPrivateKeyError" message:error.localizedDescription details:nil]);
            return;
        }

        result(privateKey);
    }
    @catch(NSException *exception) {
        result([FlutterError errorWithCode:@"Error" message:exception.reason details:nil]);
        return;
    }
}

+ (void)signTx:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSError* __autoreleasing error;
    NSString* mnemonic = call.arguments[@"mnemonic"];
    NSString* symbol = call.arguments[@"symbol"];
    NSString* rawTx = call.arguments[@"rawTx"];

    WalletValidateMnemonic(mnemonic, &error);
    if (error) {
        result([FlutterError errorWithCode:@"ValidateMnemonicError" message:@"Mnemonic is invalid" details:nil]);
        return;
    }
    
    @try
    {
        WalletWallet* wallet = [self getWalletInstance:call.arguments error:&error];
        
        if (error) {
            result([FlutterError errorWithCode:@"ImportMnemonicError" message:error.localizedDescription details:nil]);
            return;
        }
        
        NSString* signedTx = [wallet sign:symbol msg:rawTx error:&error];
        if (error) {
            result([FlutterError errorWithCode:@"SignError" message:error.localizedDescription details:nil]);
            return;
        }
        result(signedTx);
    }
    @catch(NSException *exception) {
        result([FlutterError errorWithCode:@"Error" message:exception.reason details:nil]);
        return;
    }
}

+ (void)signMsg:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSError* __autoreleasing error;
    NSString* mnemonic = call.arguments[@"mnemonic"];
    NSString* symbol = call.arguments[@"symbol"];
    NSString* msg = call.arguments[@"msg"];

    WalletValidateMnemonic(mnemonic, &error);
    if (error) {
        result([FlutterError errorWithCode:@"ValidateMnemonicError" message:@"Mnemonic is invalid" details:nil]);
        return;
    }
    
    @try
    {
        WalletWallet* wallet = [self getWalletInstance:call.arguments error:&error];
        
        if (error) {
            result([FlutterError errorWithCode:@"ImportMnemonicError" message:error.localizedDescription details:nil]);
            return;
        }
        
        NSString* privateKey = [wallet derivePrivateKey:symbol error:&error];
        
        NSData* privateKeyByte = CryptoHexDecodeThenReverse(privateKey, &error);
        
        if (error) {
            result([FlutterError errorWithCode:@"SignMsgError" message:error.localizedDescription details:nil]);
            return;
        }
        
        NSData* signedByte = CryptoEd25519sign(privateKeyByte, stringToData(msg));
        
        NSString* signedMsg = dataToHex(signedByte);
        
        result(signedMsg);
    }
    @catch(NSException *exception) {
        result([FlutterError errorWithCode:@"Error" message:exception.reason details:nil]);
        return;
    }
}


+ (void)signMsgWithPKAndBlake:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSError* __autoreleasing error;
    NSString* privateKey = call.arguments[@"privateKey"];
    NSString* msg = call.arguments[@"msg"];

    @try
    {
        NSData* privateKeyByte = CryptoHexDecodeThenReverse(privateKey, &error);
        
        if (error) {
            result([FlutterError errorWithCode:@"SignMsgError" message:error.localizedDescription details:nil]);
            return;
        }
        
        NSData* blake2Byte = CryptoBlake2b256(stringToData(msg));
        
        NSData* signedByte = CryptoEd25519sign(privateKeyByte, blake2Byte);
        
        NSString* signedMsg = dataToHex(signedByte);
        
        result(signedMsg);
    }
    @catch(NSException *exception) {
        result([FlutterError errorWithCode:@"Error" message:exception.reason details:nil]);
        return;
    }
}

@end

