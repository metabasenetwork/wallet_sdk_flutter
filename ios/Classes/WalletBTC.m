#import "WalletBTC.h"
#import <Bip39/Btc.objc.h>
#import "WalletUtils.h"

@implementation WalletBTC

+ (void)callFunc:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSArray *allFunc = @[@"createBTCTransaction", @"validateBTCAddress"];
    NSUInteger func = [allFunc indexOfObject:call.method];
    
    switch(func){
        case 0:
            [self createBTCTransaction:call result:result];
            break;
        case 1:
            [self validateBTCAddress:call result:result];
            break;
        default:
            return;
    }
}

+ (void)createBTCTransaction:(FlutterMethodCall*)call result:(FlutterResult)result {
    @try
    {
        NSError* __autoreleasing error;
        NSArray* utxos = call.arguments[@"utxos"];
        NSString* toAddress = call.arguments[@"toAddress"];
        NSString* fromAddress = call.arguments[@"fromAddress"];
        double amount = [call.arguments[@"amount"] doubleValue];
        long feeRate = [call.arguments[@"feeRate"] longValue];
        bool beta = [call.arguments[@"beta"] boolValue];
        bool isGetFee = [call.arguments[@"isGetFee"] boolValue];

        int64_t chainNet = BtcChainMainNet;
        
        if( beta == YES ) {
            chainNet = BtcChainRegtest;
        }
        
        BtcBTCUnspent *unspent = [BtcBTCUnspent new];
        for (int i = 0; i < utxos.count; i++) {
            NSDictionary* utxo = utxos[i];
            NSString* txid = utxo[@"txId"];
            long vOut = [utxo[@"vOut"] longValue];
            double vAmount = [utxo[@"vAmount"] doubleValue];
            [unspent add:txid vOut:vOut amount:vAmount scriptPubKey:@"" redeemScript:@""];
        }

        // Output
        BtcBTCAmount *btcAmount = BtcNewBTCAmount(amount, &error);
        BtcBTCAddress *btcToAddress = BtcNewBTCAddressFromString(toAddress, chainNet, &error);
        BtcBTCOutputAmount *outputAmount = [BtcBTCOutputAmount new];
        [outputAmount add:btcToAddress amount:btcAmount];
        
        // Address
        BtcBTCAddress *changeAddress = BtcNewBTCAddressFromString(fromAddress, chainNet, &error);

        if (error) {
            result([FlutterError errorWithCode:@"AddressError" message:error.localizedDescription details:nil]);
            return;
        }

        BtcBTCTransaction *signTx = BtcNewBTCTransaction(unspent, outputAmount, changeAddress, feeRate, chainNet, &error);
        
        NSString *resultText;
        if( isGetFee == YES ) {
            double feeInBtc = 0;
            [signTx getFee:&feeInBtc error:&error];
            resultText = [[NSNumber numberWithDouble:feeInBtc] stringValue];
            
            if (error) {
                result([FlutterError errorWithCode:@"FeeError" message:error.localizedDescription details:nil]);
                return;
            }
        } else {
            resultText = [signTx encodeToSignCmd:&error];
        }
        
        if (error) {
            result([FlutterError errorWithCode:@"CreateError" message:error.localizedDescription details:nil]);
            return;
        }
    
        result(resultText);
    }
    @catch(NSException *exception) {
        result([FlutterError errorWithCode:@"Error" message:exception.reason details:nil]);
        return;
    }
}


+ (void)validateBTCAddress:(FlutterMethodCall*)call result:(FlutterResult)result {
    @try
    {
        NSError* __autoreleasing error;
        NSString* address = call.arguments[@"address"];
        bool beta = [call.arguments[@"beta"] boolValue];

        int64_t chainNet = BtcChainMainNet;
        if( beta == YES ) {
            chainNet = BtcChainRegtest;
        }

        BtcNewBTCAddressFromString(address, chainNet, &error);

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

@end
