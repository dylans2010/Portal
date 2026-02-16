#ifndef CMSSIGNERHELPER_H
#define CMSSIGNERHELPER_H

#include <Foundation/Foundation.h>

typedef void (^CMSLogBlock)(NSString* _Nonnull message);

NSData* _Nullable CreateCMSSignature(NSData* _Nonnull p12Data, NSString* _Nonnull p12Password, NSData* _Nonnull cdData, NSData* _Nonnull cdHashesPlist, NSArray<NSData*>* _Nonnull cdHashes, CMSLogBlock _Nullable logBlock, NSError* _Nullable * _Nullable error);

#endif
