#include "CMSSignerHelper.h"
#include <openssl/pkcs12.h>
#include <openssl/cms.h>
#include <openssl/err.h>
#include <openssl/pem.h>
#include <openssl/bio.h>
#include <openssl/x509.h>

NSData* CreateCMSSignature(NSData* p12Data, NSString* p12Password, NSData* cdData, NSData* cdHashesPlist, NSArray<NSData*>* cdHashes, NSError** error) {
    OpenSSL_add_all_algorithms();
    ERR_load_crypto_strings();

    const char* password = [p12Password UTF8String];
    BIO* p12Bio = BIO_new_mem_buf([p12Data bytes], (int)[p12Data length]);
    PKCS12* p12 = d2i_PKCS12_bio(p12Bio, NULL);
    BIO_free(p12Bio);

    if (!p12) {
        if (error) *error = [NSError errorWithDomain:@"CMSSigner" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Failed to parse P12"}];
        return nil;
    }

    EVP_PKEY* pkey = NULL;
    X509* cert = NULL;
    STACK_OF(X509)* ca = NULL;

    if (PKCS12_parse(p12, password, &pkey, &cert, &ca) != 1) {
        PKCS12_free(p12);
        if (error) *error = [NSError errorWithDomain:@"CMSSigner" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Failed to parse P12 contents"}];
        return nil;
    }
    PKCS12_free(p12);

    int nFlags = CMS_PARTIAL | CMS_DETACHED | CMS_NOSMIMECAP | CMS_BINARY;
    CMS_ContentInfo* cms = CMS_sign(NULL, NULL, ca, NULL, nFlags);
    if (!cms) {
        EVP_PKEY_free(pkey); X509_free(cert); sk_X509_pop_free(ca, X509_free);
        if (error) *error = [NSError errorWithDomain:@"CMSSigner" code:3 userInfo:@{NSLocalizedDescriptionKey: @"Failed to initialize CMS"}];
        return nil;
    }

    CMS_SignerInfo* si = CMS_add1_signer(cms, cert, pkey, EVP_sha256(), nFlags);
    if (!si) {
        CMS_ContentInfo_free(cms); EVP_PKEY_free(pkey); X509_free(cert); sk_X509_pop_free(ca, X509_free);
        if (error) *error = [NSError errorWithDomain:@"CMSSigner" code:4 userInfo:@{NSLocalizedDescriptionKey: @"Failed to add signer to CMS"}];
        return nil;
    }

    // Add signed attributes
    // 1.2.840.113635.100.9.1 - CDHashes Plist
    ASN1_OBJECT* obj1 = OBJ_txt2obj("1.2.840.113635.100.9.1", 1);
    CMS_signed_add1_attr_by_OBJ(si, obj1, V_ASN1_OCTET_STRING, [cdHashesPlist bytes], (int)[cdHashesPlist length]);
    ASN1_OBJECT_free(obj1);

    // 1.2.840.113635.100.9.2 - CDHashes raw
    ASN1_OBJECT* obj2 = OBJ_txt2obj("1.2.840.113635.100.9.2", 1);
    X509_ATTRIBUTE* attr = X509_ATTRIBUTE_new();
    X509_ATTRIBUTE_set1_object(attr, obj2);
    for (NSData* hash in cdHashes) {
        X509_ATTRIBUTE_set1_data(attr, V_ASN1_OCTET_STRING, [hash bytes], (int)[hash length]);
    }
    CMS_signed_add1_attr(si, attr);
    X509_ATTRIBUTE_free(attr);
    ASN1_OBJECT_free(obj2);

    BIO* in = BIO_new_mem_buf([cdData bytes], (int)[cdData length]);
    if (CMS_final(cms, in, NULL, nFlags) != 1) {
        BIO_free(in); CMS_ContentInfo_free(cms); EVP_PKEY_free(pkey); X509_free(cert); sk_X509_pop_free(ca, X509_free);
        if (error) *error = [NSError errorWithDomain:@"CMSSigner" code:5 userInfo:@{NSLocalizedDescriptionKey: @"Failed to finalize CMS"}];
        return nil;
    }
    BIO_free(in);

    BIO* out = BIO_new(BIO_s_mem());
    i2d_CMS_bio(out, cms);

    BUF_MEM* bptr = NULL;
    BIO_get_mem_ptr(out, &bptr);
    NSData* signature = [NSData dataWithBytes:bptr->data length:bptr->length];

    BIO_free(out);
    CMS_ContentInfo_free(cms);
    EVP_PKEY_free(pkey);
    X509_free(cert);
    sk_X509_pop_free(ca, X509_free);

    return signature;
}
