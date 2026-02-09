//
//  p12_password_check.cpp
//  feather
//
//  Created by HAHALOSAH on 8/6/24.
//

#include "openssl_tools.hpp"
#include "common.h"

#include <openssl/pem.h>
#include <openssl/cms.h>
#include <openssl/err.h>
#include <openssl/provider.h>
#include <openssl/pkcs12.h>
#include <openssl/conf.h>
#include <openssl/evp.h>
#include <openssl/x509.h>

#include <string>

using namespace std;

bool p12_password_check(NSString *file, NSString *pass) {
	const std::string strFile = [file cStringUsingEncoding:NSUTF8StringEncoding];
	const std::string strPass = [pass cStringUsingEncoding:NSUTF8StringEncoding];
	
	BIO *bio = BIO_new_file(strFile.c_str(), "rb");
	if (!bio) {
		NSLog(@"Failed to open .p12 file");
		return false;
	}
	
	OSSL_PROVIDER_load(NULL, "legacy");
	
	PKCS12 *p12 = d2i_PKCS12_bio(bio, NULL);
	BIO_free(bio);
	
	if (!p12) {
		NSLog(@"Failed to parse PKCS12");
		return false;
	}
	
	if( PKCS12_verify_mac(p12, NULL, 0) ) {
		return true;
	} else if( PKCS12_verify_mac(p12, strPass.c_str(), -1) ) {
		return true;
	} else {
		return false;
	}
	
	PKCS12_free(p12);
	return false;
}

NSData* p12_reencrypt(NSData *p12_data, NSString *old_pass, NSString *new_pass, NSString **error_msg) {
    if (!p12_data) {
        if (error_msg) *error_msg = @"No P12 data provided";
        return nil;
    }

    const void *data = [p12_data bytes];
    int len = (int)[p12_data length];
    const char *old_p = [old_pass UTF8String];
    const char *new_p = [new_pass UTF8String];

    PKCS12 *p12 = NULL;
    EVP_PKEY *pkey = NULL;
    X509 *cert = NULL;
    STACK_OF(X509) *ca = NULL;

    BIO *in = BIO_new_mem_buf(data, len);
    if (!in) {
        if (error_msg) *error_msg = @"Failed to create input BIO";
        return nil;
    }

    p12 = d2i_PKCS12_bio(in, NULL);
    BIO_free(in);

    if (!p12) {
        if (error_msg) *error_msg = @"Failed to parse PKCS12 data. File may be corrupt.";
        return nil;
    }

    OSSL_PROVIDER *legacy = OSSL_PROVIDER_load(NULL, "legacy");
    OSSL_PROVIDER *default_prov = OSSL_PROVIDER_load(NULL, "default");

    // Copy passwords to temporary buffers that we can wipe
    char *old_pass_buf = NULL;
    if (old_p) {
        old_pass_buf = strdup(old_p);
    }

    char *new_pass_buf = NULL;
    if (new_p) {
        new_pass_buf = strdup(new_p);
    }

    if (!PKCS12_parse(p12, old_pass_buf ? old_pass_buf : "", &pkey, &cert, &ca)) {
        unsigned long err = ERR_get_error();
        const char *err_str = ERR_reason_error_string(err);
        if (error_msg) {
            *error_msg = [NSString stringWithFormat:@"Incorrect password or corrupt file: %s", err_str ? err_str : "Unknown OpenSSL error"];
        }
        if (old_pass_buf) {
            OPENSSL_cleanse(old_pass_buf, strlen(old_pass_buf));
            free(old_pass_buf);
        }
        if (new_pass_buf) {
            OPENSSL_cleanse(new_pass_buf, strlen(new_pass_buf));
            free(new_pass_buf);
        }
        PKCS12_free(p12);
        if (legacy) OSSL_PROVIDER_unload(legacy);
        if (default_prov) OSSL_PROVIDER_unload(default_prov);
        return nil;
    }
    PKCS12_free(p12);

    if (old_pass_buf) {
        OPENSSL_cleanse(old_pass_buf, strlen(old_pass_buf));
        free(old_pass_buf);
    }

    // Use "Feather-Certificate" as the friendly name
    PKCS12 *new_p12 = PKCS12_create(new_pass_buf ? new_pass_buf : (char *)"", "Feather-Certificate", pkey, cert, ca, 0, 0, 0, 0, 0);

    if (new_pass_buf) {
        OPENSSL_cleanse(new_pass_buf, strlen(new_pass_buf));
        free(new_pass_buf);
    }

    // Clean up extracted keys and certs immediately to keep them in memory only
    if (pkey) {
        EVP_PKEY_free(pkey);
    }
    if (cert) {
        X509_free(cert);
    }
    if (ca) {
        sk_X509_pop_free(ca, X509_free);
    }

    if (!new_p12) {
        unsigned long err = ERR_get_error();
        const char *err_str = ERR_reason_error_string(err);
        if (error_msg) {
            *error_msg = [NSString stringWithFormat:@"Failed to create new PKCS12: %s", err_str ? err_str : "Unknown OpenSSL error"];
        }
        if (legacy) OSSL_PROVIDER_unload(legacy);
        if (default_prov) OSSL_PROVIDER_unload(default_prov);
        return nil;
    }

    BIO *out = BIO_new(BIO_s_mem());
    if (!out) {
        if (error_msg) *error_msg = @"Failed to create output BIO";
        PKCS12_free(new_p12);
        return nil;
    }

    if (!i2d_PKCS12_bio(out, new_p12)) {
        if (error_msg) *error_msg = @"Failed to encode new PKCS12";
        PKCS12_free(new_p12);
        BIO_free(out);
        return nil;
    }

    PKCS12_free(new_p12);

    BUF_MEM *bptr = NULL;
    BIO_get_mem_ptr(out, &bptr);

    NSData *result = nil;
    if (bptr && bptr->data && bptr->length > 0) {
        result = [NSData dataWithBytes:bptr->data length:bptr->length];
    } else {
        if (error_msg) *error_msg = @"Failed to retrieve encoded PKCS12 data";
    }

    BIO_free(out);

    if (legacy) OSSL_PROVIDER_unload(legacy);
    if (default_prov) OSSL_PROVIDER_unload(default_prov);

    return result;
}

// This is fucking bullshit IMO.
//
// In total, I probably wasted a total of 1.5 hours on this
// Feel free to increment the counter until someone finds a proper fix
//
// hours_wasted = 1.5
//
// TODO: FIX
void password_check_fix_WHAT_THE_FUCK(NSString *path) {
	string strProvisionFile = [path cStringUsingEncoding:NSUTF8StringEncoding];
	string strProvisionData;
	ZFile::ReadFile(strProvisionFile.c_str(), strProvisionData);
	
	BIO *in = BIO_new(BIO_s_mem());
	OPENSSL_assert((size_t)BIO_write(in, strProvisionData.data(), (int)strProvisionData.size()) == strProvisionData.size());
	d2i_CMS_bio(in, NULL);
}

void password_check_fix_WHAT_THE_FUCK_free(NSString *path) {
	string strProvisionFile = [path cStringUsingEncoding:NSUTF8StringEncoding];
	string strProvisionData;
	ZFile::ReadFile(strProvisionFile.c_str(), strProvisionData);
	
	BIO *in = BIO_new(BIO_s_mem());
	if (!in) return;
	
	if ((size_t)BIO_write(in, strProvisionData.data(), (int)strProvisionData.size()) != strProvisionData.size()) {
		BIO_free(in);
		return;
	}
	
	CMS_ContentInfo *cms = d2i_CMS_bio(in, NULL);
	if (cms) CMS_ContentInfo_free(cms);
	// free my boy
	BIO_free(in);
}
