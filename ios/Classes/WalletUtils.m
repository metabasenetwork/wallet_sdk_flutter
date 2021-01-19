#import "WalletUtils.h"

static inline char itoh(int i) {
    if (i > 9) return 'A' + (i - 10);
    return '0' + i;
}

NSMutableData* hexToData(NSString *str) {
    str = [str lowercaseString];
    NSMutableData *data= [NSMutableData new];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i = 0;
    int length = (int) str.length;
    while (i < length-1) {
        char c = [str characterAtIndex:i++];
        if (c < '0' || (c > '9' && c < 'a') || c > 'f')
            continue;
        byte_chars[0] = c;
        byte_chars[1] = [str characterAtIndex:i++];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    return data;
}

NSString* hexToBase64(NSString *str) {
    NSMutableData *hexData =  [[NSMutableData alloc] initWithCapacity:8];

    NSData *newData = reverseData(hexToData(str));
    [hexData appendData:newData];

    NSString *base64String = [hexData base64EncodedStringWithOptions: 0];

    return base64String;
}

NSData* stringToData(NSString *str) {
    NSData* data = [str dataUsingEncoding:NSUTF8StringEncoding];
    return data;
}

NSString* dataToHex(NSData *data) {
    NSUInteger i, len;
    unsigned char *buf, *bytes;

    len = data.length;
    bytes = (unsigned char*)data.bytes;
    buf = malloc(len*2);

    for (i=0; i<len; i++) {
        buf[i*2] = itoh((bytes[i] >> 4) & 0xF);
        buf[i*2+1] = itoh(bytes[i] & 0xF);
    }

    return [[NSString alloc] initWithBytesNoCopy:buf
                                          length:len*2
                                        encoding:NSASCIIStringEncoding
                                    freeWhenDone:YES];
}

NSData* reverseData(NSData *data) {
    const char *bytes = [data bytes];
    long idx = [data length] - 1;
    char *reversedBytes = calloc(sizeof(char),[data length]);
    for (int i = 0; i < [data length]; i++) {
        reversedBytes[idx--] = bytes[i];
    }
    NSData *reversedData = [NSData dataWithBytes:reversedBytes length:[data length]];
    free(reversedBytes);
    return reversedData;
}
