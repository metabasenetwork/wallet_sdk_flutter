#import "WalletETH.h"
#import <Bip39/Eth.objc.h>
#import "WalletUtils.h"

@implementation WalletETH

+ (void)callFunc:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSArray *allFunc = @[@"createETHTransaction", @"validateETHAddress"];
    NSUInteger func = [allFunc indexOfObject:call.method];
    
    switch(func){
        case 0:
            [self createETHTransaction:call result:result];
            break;
        case 1:
            [self validateETHAddress:call result:result];
            break;
        default:
            return;
    }
}

+ (void)createETHTransaction:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSError* __autoreleasing error;
    NSString* address = call.arguments[@"address"];
    NSString* contract = call.arguments[@"contract"];
    int nonce = [call.arguments[@"nonce"] intValue];
    int64_t amount = [call.arguments[@"amount"] doubleValue];
    int64_t gasPrice = [call.arguments[@"gasPrice"] doubleValue];
    int64_t gasLimit = [call.arguments[@"gasLimit"] doubleValue];

    EthETHAddress *ethAddress = [EthETHAddress new];
    [ethAddress setHex:address error:&error];
    if (error) {
        result([FlutterError errorWithCode:@"AddressError" message:error.localizedDescription details:nil]);
        return;
    }

    EthBigInt *ethAmount = [[EthBigInt alloc] init:amount];
    EthBigInt *ethAmountAbi = [[EthBigInt alloc] init:amount];
    EthBigInt *ethGasPrice = [[EthBigInt alloc] init:gasPrice];

    NSData *erc20Data = nil;

    if (contract.length > 0) {
        ethAmount = [ethAmount init:0];
        EthERC20InterfaceABIHelper *erc20ABI = [EthERC20InterfaceABIHelper new];
        erc20Data = [erc20ABI packedTransfer:ethAddress tokens:ethAmountAbi error:&error];
        if (error) {
            result([FlutterError errorWithCode:@"EthERC20InterfaceABIHelper" message:error.localizedDescription details:nil]);
            return;
        }
        [ethAddress setHex:contract error:&error];
        if (error) {
            result([FlutterError errorWithCode:@"AddressError" message:error.localizedDescription details:nil]);
            return;
        }
    } 

    EthETHTransaction *transaction = [[EthETHTransaction alloc] init:nonce
                                                                  to:ethAddress
                                                              amount:ethAmount
                                                            gasLimit:gasLimit
                                                            gasPrice:ethGasPrice
                                                                data:erc20Data];

    NSString *signedTx = [transaction encodeRLP:&error];
    
    if (error) {
        result([FlutterError errorWithCode:@"TransactionError" message:error.localizedDescription details:nil]);
        return;
    }
    
    result(signedTx);
}

+ (void)validateETHAddress:(FlutterMethodCall*)call result:(FlutterResult)result {
    @try
    {
        NSError* __autoreleasing error;
        NSString* address = call.arguments[@"address"];

        EthETHAddress *checkAddress = [EthETHAddress new];
        [checkAddress setHex:address error:&error];

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
