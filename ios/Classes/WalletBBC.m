#import "WalletBBC.h"
#import <Bip39/Bbc.objc.h>
#import <Bip39/Bip44.objc.h>
#import "WalletUtils.h"

@implementation WalletBBC

+ (void)callFunc:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSArray *allFunc = @[
        @"createBBCTransaction",
        @"validateBBCAddress",
        @"createBBCDexOrderTemplateData",
        @"createBBCKeyPair",
        @"createBBCFromPrivateKey",
        @"addressBBCToPublicKey",
    ];
    NSUInteger func = [allFunc indexOfObject:call.method];
    
    switch(func){
        case 0:
            [self createBBCTransaction:call result:result];
            break;
        case 1:
            [self validateBBCAddress:call result:result];
            break;
        case 2:
            [self createBBCDexOrderTemplateData:call result:result];
            break;
        case 3:
            [self createBBCKeyPair:call result:result];
            break;
        case 4:
            [self createBBCFromPrivateKey:call result:result];
            break;
        case 5:
            [self addressBBCToPublicKey:call result:result];
            break;
        default:
            return;
    }
}

+ (void)createBBCTransaction:(FlutterMethodCall*)call result:(FlutterResult)result {
    @try
    {
        NSError* __autoreleasing error;
        NSArray* utxos = call.arguments[@"utxos"];
        NSString* address = call.arguments[@"address"];
        NSString* anchor = call.arguments[@"anchor"];
        NSNumber* amount = call.arguments[@"amount"];
        NSNumber* fee = call.arguments[@"fee"];
        int version = [call.arguments[@"version"] intValue];
        int lockUntil = [call.arguments[@"lockUntil"] intValue];
        long timestamp = [call.arguments[@"timestamp"] longValue];
        long type = [call.arguments[@"type"] longValue];
        int dataType = [call.arguments[@"dataType"] intValue];
        NSString* data = call.arguments[@"data"];
        NSString* dataWithUUID = call.arguments[@"dataWithUUID"];
        NSString* dataWithFmt = call.arguments[@"dataWithFmt"];
        NSString* templateData = call.arguments[@"templateData"];

        BbcTxBuilder *txBuilder = BbcNewTxBuilder();
        [txBuilder setAnchor:anchor];
        [txBuilder setTimestamp:timestamp];
        [txBuilder setVersion:version];
        [txBuilder setLockUntil:lockUntil];
        [txBuilder setAddress:address];
        [txBuilder setAmount:[amount doubleValue]];
        [txBuilder setFee:[fee doubleValue]];
        [txBuilder setType:type];
        
        if (templateData != (id)[NSNull null] && templateData.length > 0) {
            [txBuilder addTemplateData:templateData];
        }

        if (data != (id)[NSNull null] && data.length > 0) {
            switch(dataType){
                case 2: // setDataWith
                    [txBuilder setDataWith:dataWithUUID timestamp:timestamp dataFmtDesc:dataWithFmt data: stringToData(data)];
                break;
                case 1: // setRawData hex
                    [txBuilder setRawData:hexToData(data)];
                break;
                case 0: // setData String
                default:
                    [txBuilder setData:dataWithFmt data:stringToData(data)];
            }
        }
        
        for (int i = 0; i < utxos.count; i++) {
            NSDictionary* utxo = utxos[i];
            NSString* txid = utxo[@"txId"];
            int vout = [utxo[@"vOut"] intValue];
            [txBuilder addInput:txid vout:vout];
        }

        NSString* signedTx = [txBuilder build:&error];

        if (error) {
            result([FlutterError errorWithCode:@"CreateError" message:error.localizedDescription details:nil]);
            return;
        }
        result(signedTx);
    }
    @catch(NSException *exception) {
        result([FlutterError errorWithCode:@"Error" message:exception.reason details:nil]);
        return;
    }
}

+ (void)validateBBCAddress:(FlutterMethodCall*)call result:(FlutterResult)result {
    @try
    {
        NSError* __autoreleasing error;
        NSString* address = call.arguments[@"address"];

        BbcAddress2pubk(address, &error);

        if (error) {
            result([FlutterError errorWithCode:@"AddressError" message:error.localizedDescription details:nil]);
            return;
        }
        result(@(YES));
    }
    @catch(NSException *exception) {
        result([FlutterError errorWithCode:@"Error" message:exception.reason details:nil]);
        return;
    }
}

+ (void) createBBCDexOrderTemplateData:(FlutterMethodCall*)call result:(FlutterResult)result {
    @try
    {
        NSError* __autoreleasing error;
        NSString* tradePair = call.arguments[@"tradePair"];
        int64_t price = [call.arguments[@"price"] longLongValue];
        int64_t timestamp = [call.arguments[@"timestamp"] longLongValue];
        int32_t fee = [call.arguments[@"fee"] intValue];
        int32_t validHeight = [call.arguments[@"validHeight"] intValue];
        NSString* sellerAddress = call.arguments[@"sellerAddress"];
        NSString* recvAddress = call.arguments[@"recvAddress"];
        NSString* matchAddress = call.arguments[@"matchAddress"];
        NSString* dealAddress = call.arguments[@"dealAddress"];
        
        BbcTemplateInfo *templateInfo = BbcCreateTemplateDataDexOrder(sellerAddress, tradePair, price, fee, recvAddress, validHeight, matchAddress, dealAddress, timestamp, &error);
        
        if (error) {
            result([FlutterError errorWithCode:@"CreateBBCDexOrderError" message:error.localizedDescription details:nil]);
            return;
        }

        NSMutableDictionary *retDict = [NSMutableDictionary dictionaryWithCapacity:2];
        retDict[@"address"] = templateInfo.address;
        retDict[@"rawHex"] = templateInfo.rawHex;
        
        result(retDict);
    }
    @catch(NSException *exception) {
        result([FlutterError errorWithCode:@"Error" message:exception.reason details:nil]);
        return;
    }
}

+ (void) createBBCKeyPair:(FlutterMethodCall*)call result:(FlutterResult)result {
    @try
    {
        NSError* __autoreleasing error;
        NSString* bip44Path = call.arguments[@"bip44Path"];
        NSString* bip44Key = call.arguments[@"bip44Key"];
        
        id<Bip44Deriver> deriver = BbcNewSymbolBip44Deriver(NULL, bip44Path, bip44Key, NULL, &error);

        if (error) {
            result([FlutterError errorWithCode:@"CreateBBCKeyPairError" message:error.localizedDescription details:nil]);
            return;
        }
        
        NSMutableDictionary *retDict = [NSMutableDictionary dictionaryWithCapacity:3];

        retDict[@"address"] = [deriver deriveAddress:&error];
        retDict[@"publicKey"] = [deriver derivePublicKey:&error];
        retDict[@"privateKey"] = [deriver derivePrivateKey:&error];
        
        if (error) {
            result([FlutterError errorWithCode:@"CreateBBCKeyPairError" message:error.localizedDescription details:nil]);
            return;
        }

        result(retDict);
    }
    @catch(NSException *exception) {
        result([FlutterError errorWithCode:@"Error" message:exception.reason details:nil]);
        return;
    }
}

+ (void) createBBCFromPrivateKey:(FlutterMethodCall*)call result:(FlutterResult)result {
    @try
    {
        NSError* __autoreleasing error;
        NSString* privateKey = call.arguments[@"privateKey"];
        
        BbcKeyInfo* keyInfo = BbcParsePrivateKey(privateKey, &error);
        
        if (error) {
            result([FlutterError errorWithCode:@"CreateBBCFromPrivateKeyError" message:error.localizedDescription details:nil]);
            return;
        }
        
        NSMutableDictionary *retDict = [NSMutableDictionary dictionaryWithCapacity:3];

        retDict[@"address"] = keyInfo.address;
        retDict[@"publicKey"] = keyInfo.publicKey;
        retDict[@"privateKey"] = keyInfo.privateKey;

        result(retDict);
    }
    @catch(NSException *exception) {
        result([FlutterError errorWithCode:@"Error" message:exception.reason details:nil]);
        return;
    }
}

+ (void) addressBBCToPublicKey:(FlutterMethodCall*)call result:(FlutterResult)result {
    @try
    {
        NSError* __autoreleasing error;
        NSString* address = call.arguments[@"address"];
        
        NSString* publicKey = BbcAddress2pubk(address, &error);

        if (error) {
            result([FlutterError errorWithCode:@"AddressBBCToPublicKeyError" message:error.localizedDescription details:nil]);
            return;
        }
        
        result(publicKey);
    }
    @catch(NSException *exception) {
        result([FlutterError errorWithCode:@"Error" message:exception.reason details:nil]);
        return;
    }
}

@end
