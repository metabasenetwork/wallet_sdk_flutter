#import "WalletSdkFlutterPlugin.h"
#import <Bip39/Wallet.objc.h>
#import <WalletCore.h>
#import <WalletETH.h>
#import <WalletBTC.h>
#import <WalletBBC.h>

@implementation WalletSdkFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"wallet_sdk_flutter"
            binaryMessenger:[registrar messenger]];
  WalletSdkFlutterPlugin* instance = [[WalletSdkFlutterPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  [WalletCore callFunc:call result:result];
  [WalletETH callFunc:call result:result];
  [WalletBTC callFunc:call result:result];
  [WalletBBC callFunc:call result:result];
}

@end
