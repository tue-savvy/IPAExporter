//
//  SigningIdentity.m
//  IPAExporter
//
//  Created by Tue Nguyen on 10/11/14.
//  Copyright (c) 2014 HOME. All rights reserved.
//

#import "SigningIdentity.h"
#import "Provisioning.h"
#import <Security/Security.h>

@interface SigningIdentity()

@end
@implementation SigningIdentity
- (instancetype)initWithProvision:(Provisioning *)provision certificateData:(NSData *)certificateData {
    self = [super init];
    if (self) {
        self.provision = provision;
        _certificateData = certificateData;
        [self _loadCertData];
    }
    return self;
}
- (void)_loadCertData {
    SecCertificateRef certRef = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef)(self.certificateData));
    CFStringRef commonName;
    SecCertificateCopyCommonName(certRef, &commonName);
    self.commonName = CFBridgingRelease(commonName);
    CFRelease(certRef);
}

+ (NSArray *)keychainsIdenities {
    NSMutableArray *keychainsIdentities = [NSMutableArray array];
    
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  (__bridge id)kCFBooleanTrue, (__bridge id)kSecReturnRef,
                                  (__bridge id)kSecMatchLimitAll, (__bridge id)kSecMatchLimit,
                                  kCFNull, kSecMatchValidOnDate,
                                  @"iPhone", kSecMatchSubjectStartsWith,
                                  nil];

    NSArray *secItemClasses = [NSArray arrayWithObjects:
//                               (__bridge id)kSecClassGenericPassword,
//                               (__bridge id)kSecClassInternetPassword,
//                               (__bridge id)kSecClassCertificate,
//                               (__bridge id)kSecClassKey,
                               (__bridge id)kSecClassIdentity,
                               nil];

    for (id secItemClass in secItemClasses) {
        [query setObject:secItemClass forKey:(__bridge id)kSecClass];

        CFTypeRef result = NULL;
        SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);

        if (result) {
            NSArray *identityArray = (__bridge NSArray *)(result);
            for (id obj in identityArray) {
                SecIdentityRef identityRef = (__bridge SecIdentityRef)(obj);
                SecCertificateRef certKeychains = NULL;
                SecIdentityCopyCertificate(identityRef, &certKeychains);
                if (certKeychains != NULL) {
                    NSData *keychainCertData = (NSData *)CFBridgingRelease(SecCertificateCopyData(certKeychains));
                    SigningIdentity *si = [[SigningIdentity alloc] initWithProvision:nil certificateData:keychainCertData];
                    if ([si.commonName hasPrefix:@"iPhone Developer"] || [si.commonName hasPrefix:@"iPhone Distribution"]) {
                        [keychainsIdentities addObject:si];
                    }
                    CFRelease(certKeychains);
                }
            }
        }


        if (result != NULL) CFRelease(result);
    }
    return keychainsIdentities;
}
@end


//    NSURL *URL = [NSURL fileURLWithPath:@"/Users/Tue/Desktop/LOCFOOD_Merchant_DEV.mobileprovision"];
//
//    NSData *fileData = nil;
//
//    fileData = [NSData dataWithContentsOfURL:URL];
//
//    // Insert code here to initialize your application
//    CMSDecoderRef decoder = NULL;
//    CMSDecoderCreate(&decoder);
//    CMSDecoderUpdateMessage(decoder, fileData.bytes, fileData.length);
//    CMSDecoderFinalizeMessage(decoder);
//    CFDataRef dataRef = NULL;
//    CMSDecoderCopyContent(decoder, &dataRef);
//    NSData *data = (NSData *)CFBridgingRelease(dataRef);
//
//    NSDictionary *propertyList = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:NULL];
//    NSData *certData = [propertyList[@"DeveloperCertificates"] firstObject];
//    SecCertificateRef certRef = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef)(certData));
//    NSData *serialFromProvisioning = (__bridge NSData *)(SecCertificateCopySerialNumber(certRef, NULL));
//    NSLog(@"%@", propertyList);
//
//    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithObjectsAndKeys:
//                                  (__bridge id)kCFBooleanTrue, (__bridge id)kSecReturnRef,
//                                  (__bridge id)kSecMatchLimitAll, (__bridge id)kSecMatchLimit,
//                                  nil];
//
//    NSArray *secItemClasses = [NSArray arrayWithObjects:
////                               (__bridge id)kSecClassGenericPassword,
////                               (__bridge id)kSecClassInternetPassword,
////                               (__bridge id)kSecClassCertificate,
////                               (__bridge id)kSecClassKey,
//                               (__bridge id)kSecClassIdentity,
//                               nil];
//
//    for (id secItemClass in secItemClasses) {
//        [query setObject:secItemClass forKey:(__bridge id)kSecClass];
//
//        CFTypeRef result = NULL;
//        SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
//
//        if (result) {
//            NSArray *identityArray = (__bridge NSArray *)(result);
//            for (id obj in identityArray) {
//                SecIdentityRef identityRef = (__bridge SecIdentityRef)(obj);
//                SecCertificateRef certKeychains = NULL;
//                SecIdentityCopyCertificate(identityRef, &certKeychains);
//                NSData *keychainCertData = (__bridge NSData *)(SecCertificateCopyData(certKeychains));
//                BOOL isEqual = [keychainCertData isEqualToData:certData];
//                NSLog(@"%d", isEqual);
//            }
//        }
//
//        NSLog(@"%@", (__bridge id)result);
//
//        if (result != NULL) CFRelease(result);
//    }