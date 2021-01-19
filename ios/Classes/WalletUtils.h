//
//  WalletUtils.h
//

#ifndef WalletUtils_h
#define WalletUtils_h

#endif /* WalletUtils_h */

#import <Foundation/Foundation.h>

NSData *hexToData(NSString *str);

NSString *hexToBase64(NSString *str);

NSData *stringToData(NSString *str);

NSString *dataToHex(NSData *data);

NSData *reverseData(NSData *data);
