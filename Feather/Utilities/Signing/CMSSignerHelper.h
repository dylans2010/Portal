#ifndef CMSSIGNERHELPER_H
#define CMSSIGNERHELPER_H

#include <Foundation/Foundation.h>

NSData* _Nullable CreateCMSSignature(NSData* _Nonnull p12Data, NSString* _Nonnull p12Password, NSData* _Nonnull cdData, NSData* _Nonnull cdHashesPlist, NSArray<NSData*>* _Nonnull cdHashes, NSError* _Nullable * _Nullable error);

#endif
