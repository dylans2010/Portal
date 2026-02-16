#include "CMSSignerHelper.h"
#include <openssl/pkcs12.h>
#include <openssl/cms.h>
#include <openssl/err.h>
#include <openssl/pem.h>
#include <openssl/bio.h>
#include <openssl/x509.h>

static const char* s_szAppleDevCACert =
"-----BEGIN CERTIFICATE-----\n"
"MIIEIjCCAwqgAwIBAgIIAd68xDltoBAwDQYJKoZIhvcNAQEFBQAwYjELMAkGA1UE\n"
"BhMCVVMxEzARBgNVBAoTCkFwcGxlIEluYy4xJjAkBgNVBAsTHUFwcGxlIENlcnRp\n"
"ZmljYXRpb24gQXV0aG9yaXR5MRYwFAYDVQQDEw1BcHBsZSBSb290IENBMB4XDTEz\n"
"MDIwNzIxNDg0N1oXDTIzMDIwNzIxNDg0N1owgZYxCzAJBgNVBAYTAlVTMRMwEQYD\n"
"VQQKDApBcHBsZSBJbmMuMSwwKgYDVQQLDCNBcHBsZSBXb3JsZHdpZGUgRGV2ZWxv\n"
"cGVyIFJlbGF0aW9uczFEMEIGA1UEAww7QXBwbGUgV29ybGR3aWRlIERldmVsb3Bl\n"
"ciBSZWxhdGlvbnMgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwggEiMA0GCSqGSIb3\n"
"DQEBAQUAA4IBDwAwggEKAoIBAQDKOFSmy1aqyCQ5SOmM7uxfuH8mkbw0U3rOfGOA\n"
"YXdkXqUHI7Y5/lAtFVZYcC1+xG7BSoU+L/DehBqhV8mvexj/avoVEkkVCBmsqtsq\n"
"Mu2WY2hSFT2Miuy/axiV4AOsAX2XBWfODoWVN2rtCbauZ81RZJ/GXNG8V25nNYB2\n"
"NqSHgW44j9grFU57Jdhav06DwY3Sk9UacbVgnJ0zTlX5ElgMhrgWDcHld0WNUEi6\n"
"Ky3klIXh6MSdxmilsKP8Z35wugJZS3dCkTm59c3hTO/AO0iMpuUhXf1qarunFjVg\n"
"0uat80YpyejDi+l5wGphZxWy8P3laLxiX27Pmd3vG2P+kmWrAgMBAAGjgaYwgaMw\n"
"HQYDVR0OBBYEFIgnFwmpthhgi+zruvZHWcVSVKO3MA8GA1UdEwEB/wQFMAMBAf8w\n"
"HwYDVR0jBBgwFoAUK9BpR5R2Cf70a40uQKb3R01/CF4wLgYDVR0fBCcwJTAjoCGg\n"
"H4YdaHR0cDovL2NybC5hcHBsZS5jb20vcm9vdC5jcmwwDgYDVR0PAQH/BAQDAgGG\n"
"MBAGCiqGSIb3Y2QGAgEEAgUAMA0GCSqGSIb3DQEBBQUAA4IBAQBPz+9Zviz1smwv\n"
"j+4ThzLoBTWobot9yWkMudkXvHcs1Gfi/ZptOllc34MBvbKuKmFysa/Nw0Uwj6OD\n"
"Dc4dR7Txk4qjdJukw5hyhzs+r0ULklS5MruQGFNrCk4QttkdUGwhgAqJTleMa1s8\n"
"Pab93vcNIx0LSiaHP7qRkkykGRIZbVf1eliHe2iK5IaMSuviSRSqpd1VAKmuu0sw\n"
"ruGgsbwpgOYJd+W+NKIByn/c4grmO7i77LpilfMFY0GCzQ87HUyVpNur+cmV6U/k\n"
"TecmmYHpvPm0KdIBembhLoz2IYrF+Hjhga6/05Cdqa3zr/04GpZnMBxRpVzscYqC\n"
"tGwPDBUf\n"
"-----END CERTIFICATE-----\n";

static const char* s_szAppleDevCACertG3 =
"-----BEGIN CERTIFICATE-----\n"
"MIIEUTCCAzmgAwIBAgIQfK9pCiW3Of57m0R6wXjF7jANBgkqhkiG9w0BAQsFADBi\n"
"MQswCQYDVQQGEwJVUzETMBEGA1UEChMKQXBwbGUgSW5jLjEmMCQGA1UECxMdQXBw\n"
"bGUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxFjAUBgNVBAMTDUFwcGxlIFJvb3Qg\n"
"Q0EwHhcNMjAwMjE5MTgxMzQ3WhcNMzAwMjIwMDAwMDAwWjB1MUQwQgYDVQQDDDtB\n"
"cHBsZSBXb3JsZHdpZGUgRGV2ZWxvcGVyIFJlbGF0aW9ucyBDZXJ0aWZpY2F0aW9u\n"
"IEF1dGhvcml0eTELMAkGA1UECwwCRzMxEzARBgNVBAoMCkFwcGxlIEluYy4xCzAJ\n"
"BgNVBAYTAlVTMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2PWJ/KhZ\n"
"C4fHTJEuLVaQ03gdpDDppUjvC0O/LYT7JF1FG+XrWTYSXFRknmxiLbTGl8rMPPbW\n"
"BpH85QKmHGq0edVny6zpPwcR4YS8Rx1mjjmi6LRJ7TrS4RBgeo6TjMrA2gzAg9Dj\n"
"+ZHWp4zIwXPirkbRYp2SqJBgN31ols2N4Pyb+ni743uvLRfdW/6AWSN1F7gSwe0b\n"
"5TTO/iK1nkmw5VW/j4SiPKi6xYaVFuQAyZ8D0MyzOhZ71gVcnetHrg21LYwOaU1A\n"
"0EtMOwSejSGxrC5DVDDOwYqGlJhL32oNP/77HK6XF8J4CjDgXx9UO0m3JQAaN4LS\n"
"VpelUkl8YDib7wIDAQABo4HvMIHsMBIGA1UdEwEB/wQIMAYBAf8CAQAwHwYDVR0j\n"
"BBgwFoAUK9BpR5R2Cf70a40uQKb3R01/CF4wRAYIKwYBBQUHAQEEODA2MDQGCCsG\n"
"AQUFBzABhihodHRwOi8vb2NzcC5hcHBsZS5jb20vb2NzcDAzLWFwcGxlcm9vdGNh\n"
"MC4GA1UdHwQnMCUwI6AhoB+GHWh0dHA6Ly9jcmwuYXBwbGUuY29tL3Jvb3QuY3Js\n"
"MB0GA1UdDgQWBBQJ/sAVkPmvZAqSErkmKGMMl+ynsjAOBgNVHQ8BAf8EBAMCAQYw\n"
"EAYKKoZIhvdjZAYCAQQCBQAwDQYJKoZIhvcNAQELBQADggEBAK1lE+j24IF3RAJH\n"
"Qr5fpTkg6mKp/cWQyXMT1Z6b0KoPjY3L7QHPbChAW8dVJEH4/M/BtSPp3Ozxb8qA\n"
"HXfCxGFJJWevD8o5Ja3T43rMMygNDi6hV0Bz+uZcrgZRKe3jhQxPYdwyFot30ETK\n"
"XXIDMUacrptAGvr04NM++i+MZp+XxFRZ79JI9AeZSWBZGcfdlNHAwWx/eCHvDOs7\n"
"bJmCS1JgOLU5gm3sUjFTvg+RTElJdI+mUcuER04ddSduvfnSXPN/wmwLCTbiZOTC\n"
"NwMUGdXqapSqqdv+9poIZ4vvK7iqF0mDr8/LvOnP6pVxsLRFoszlh6oKw0E6eVza\n"
"UDSdlTs=\n"
"-----END CERTIFICATE-----\n";

static const char* s_szAppleRootCACert =
"-----BEGIN CERTIFICATE-----\n"
"MIIEuzCCA6OgAwIBAgIBAjANBgkqhkiG9w0BAQUFADBiMQswCQYDVQQGEwJVUzET\n"
"MBEGA1UEChMKQXBwbGUgSW5jLjEmMCQGA1UECxMdQXBwbGUgQ2VydGlmaWNhdGlv\n"
"biBBdXRob3JpdHkxFjAUBgNVBAMTDUFwcGxlIFJvb3QgQ0EwHhcNMDYwNDI1MjE0\n"
"MDM2WhcNMzUwMjA5MjE0MDM2WjBiMQswCQYDVQQGEwJVUzETMBEGA1UEChMKQXBw\n"
"bGUgSW5jLjEmMCQGA1UECxMdQXBwbGUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkx\n"
"FjAUBgNVBAMTDUFwcGxlIFJvb3QgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw\n"
"ggEKAoIBAQDkkakJH5HbHkdQ6wXtXnmELes2oldMVeyLGYne+Uts9QerIjAC6Bg+\n"
"+FAJ039BqJj50cpmnCRrEdCju+QbKsMflZ56DKRHi1vUFjczy8QPTc4UadHJGXL1\n"
"XQ7Vf1+b8iUDulWPTV0N8WQ1IxVLFVkds5T39pyez1C6wVhQZ48ItCD3y6wsIG9w\n"
"tj8BMIy3Q88PnT3zK0koGsj+zrW5DtleHNbLPbU6rfQPDgCSC7EhFi501TwN22IW\n"
"q6NxkkdTVcGvL0Gz+PvjcM3mo0xFfh9Ma1CWQYnEdGILEINBhzOKgbEwWOxaBDKM\n"
"aLOPHd5lc/9nXmW8Sdh2nzMUZaF3lMktAgMBAAGjggF6MIIBdjAOBgNVHQ8BAf8E\n"
"BAMCAQYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUK9BpR5R2Cf70a40uQKb3\n"
"R01/CF4wHwYDVR0jBBgwFoAUK9BpR5R2Cf70a40uQKb3R01/CF4wggERBgNVHSAE\n"
"ggEIMIIBBDCCAQAGCSqGSIb3Y2QFATCB8jAqBggrBgEFBQcCARYeaHR0cHM6Ly93\n"
"d3cuYXBwbGUuY29tL2FwcGxlY2EvMIHDBggrBgEFBQcCAjCBthqBs1JlbGlhbmNl\n"
"IG9uIHRoaXMgY2VydGlmaWNhdGUgYnkgYW55IHBhcnR5IGFzc3VtZXMgYWNjZXB0\n"
"YW5jZSBvZiB0aGUgdGhlbiBhcHBsaWNhYmxlIHN0YW5kYXJkIHRlcm1zIGFuZCBj\n"
"b25kaXRpb25zIG9mIHVzZSwgY2VydGlmaWNhdGUgcG9saWN5IGFuZCBjZXJ0aWZp\n"
"Y2F0aW9uIHByYWN0aWNlIHN0YXRlbWVudHMuMA0GCSqGSIb3DQEBBQUAA4IBAQBc\n"
"NplMLXi37Yyb3PN3m/J20ncwT8EfhYOFG5k9RzfyqZtAjizUsZAS2L70c5vu0mQP\n"
"y3lPNNiiPvl4/2vIB+x9OYOLUyDTOMSxv5pPCmv/K/xZpwUJfBdAVhEedNO3iyM7\n"
"R6PVbyTi69G3cN8PReEnyvFteO3ntRcXqNx+IjXKJdXZD9Zr1KIkIxH3oayPc4Fg\n"
"xhtbCS+SsvhESPBgOJ4V9T0mZyCKM2r3DYLP3uujL/lTaltkwGMzd/c6ByxW69oP\n"
"IQ7aunMZT7XZNn/Bh1XZp5m5MkL72NVxnn6hUrcbvZNCJBIqxw8dtk2cXmPIS4AX\n"
"UKqK1drk/NAJBzewdXUh\n"
"-----END CERTIFICATE-----\n";

NSData* CreateCMSSignature(NSData* p12Data, NSString* p12Password, NSData* cdData, NSData* cdHashesPlist, NSArray<NSData*>* cdHashes, CMSLogBlock logBlock, NSError** error) {
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

    if (logBlock) {
        char *subject = X509_NAME_oneline(X509_get_subject_name(cert), NULL, 0);
        logBlock([NSString stringWithFormat:@"Certificate subject: %s", subject]);
        OPENSSL_free(subject);

        ASN1_TIME *notAfter = X509_get0_notAfter(cert);
        BIO *bio = BIO_new(BIO_s_mem());
        ASN1_TIME_print(bio, notAfter);
        BUF_MEM *bptr;
        BIO_get_mem_ptr(bio, &bptr);
        NSString *expireStr = [[NSString alloc] initWithBytes:bptr->data length:bptr->length encoding:NSUTF8StringEncoding];
        logBlock([NSString stringWithFormat:@"Certificate expiration date: %@", expireStr]);
        BIO_free(bio);

        logBlock([NSString stringWithFormat:@"Certificate chain length: %d", sk_X509_num(ca)]);
    }

    // Check expiration
    if (X509_cmp_current_time(X509_get0_notAfter(cert)) <= 0) {
        EVP_PKEY_free(pkey); X509_free(cert); sk_X509_pop_free(ca, X509_free);
        if (error) *error = [NSError errorWithDomain:@"CMSSigner" code:7 userInfo:@{NSLocalizedDescriptionKey: @"Certificate is expired"}];
        return nil;
    }

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

    // Explicitly add the signer certificate to the CMS message
    CMS_add1_cert(cms, cert);

    // Add Apple intermediate CAs if not present in the chain
    BIO* bioG1 = BIO_new_mem_buf(s_szAppleDevCACert, (int)strlen(s_szAppleDevCACert));
    X509* certG1 = PEM_read_bio_X509(bioG1, NULL, 0, NULL);
    BIO_free(bioG1);

    BIO* bioG3 = BIO_new_mem_buf(s_szAppleDevCACertG3, (int)strlen(s_szAppleDevCACertG3));
    X509* certG3 = PEM_read_bio_X509(bioG3, NULL, 0, NULL);
    BIO_free(bioG3);

    BIO* bioRoot = BIO_new_mem_buf(s_szAppleRootCACert, (int)strlen(s_szAppleRootCACert));
    X509* certRoot = PEM_read_bio_X509(bioRoot, NULL, 0, NULL);
    BIO_free(bioRoot);

    if (certG1) CMS_add1_cert(cms, certG1);
    if (certG3) CMS_add1_cert(cms, certG3);
    if (certRoot) CMS_add1_cert(cms, certRoot);

    if (certG1) X509_free(certG1);
    if (certG3) X509_free(certG3);
    if (certRoot) X509_free(certRoot);

    // Add signed attributes
    // 1.2.840.113635.100.9.1 - CDHashes Plist
    ASN1_OBJECT* obj1 = OBJ_txt2obj("1.2.840.113635.100.9.1", 1);
    CMS_signed_add1_attr_by_OBJ(si, obj1, V_ASN1_OCTET_STRING, [cdHashesPlist bytes], (int)[cdHashesPlist length]);
    ASN1_OBJECT_free(obj1);

    // 1.2.840.113635.100.9.2 - CDHashes raw (apple-codesigning-cdhash)
    ASN1_OBJECT* obj2 = OBJ_txt2obj("1.2.840.113635.100.9.2", 1);
    X509_ATTRIBUTE* attr = X509_ATTRIBUTE_new();
    X509_ATTRIBUTE_set1_object(attr, obj2);
    for (NSData* hash in cdHashes) {
        // MUST be exactly 20 bytes even for SHA-256 (truncated)
        const void* bytes = [hash bytes];
        int len = (int)[hash length];
        if (len > 20) len = 20;
        X509_ATTRIBUTE_set1_data(attr, V_ASN1_OCTET_STRING, bytes, len);
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

    // Internal validation: Verify the signature we just created
    BIO* verifyBio = BIO_new_mem_buf([cdData bytes], (int)[cdData length]);
    if (CMS_verify(cms, NULL, NULL, verifyBio, NULL, CMS_NO_SIGNER_CERT_VERIFY | CMS_DETACHED | CMS_BINARY) != 1) {
        BIO_free(in); BIO_free(verifyBio); CMS_ContentInfo_free(cms); EVP_PKEY_free(pkey); X509_free(cert); sk_X509_pop_free(ca, X509_free);
        if (error) *error = [NSError errorWithDomain:@"CMSSigner" code:6 userInfo:@{NSLocalizedDescriptionKey: @"CMS signature verification failed"}];
        return nil;
    }
    BIO_free(verifyBio);
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
