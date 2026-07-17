#include "freshBetaCrypto.h"

#include <stdexcept>

#include <openssl/evp.h>
#include <openssl/rand.h>
#include <openssl/pem.h>
#include <openssl/rsa.h>
#include <openssl/err.h>

namespace {
struct EvpCtxFree { void operator()(EVP_CIPHER_CTX *c) const { if (c) EVP_CIPHER_CTX_free(c); } };
struct PkeyFree   { void operator()(EVP_PKEY *p) const { if (p) EVP_PKEY_free(p); } };
struct PkeyCtxFree{ void operator()(EVP_PKEY_CTX *c) const { if (c) EVP_PKEY_CTX_free(c); } };
struct BioFree    { void operator()(BIO *b) const { if (b) BIO_free(b); } };
} // namespace

QByteArray FreshBetaCrypto::randomBytes(int size)
{
    QByteArray out(size, Qt::Uninitialized);
    if (RAND_bytes(reinterpret_cast<unsigned char *>(out.data()), size) != 1) {
        throw std::runtime_error("FreshBetaCrypto: RAND_bytes failed");
    }
    return out;
}

QByteArray FreshBetaCrypto::tsAadBigEndian(qint64 unixMs)
{
    QByteArray aad(8, Qt::Uninitialized);
    quint64 v = static_cast<quint64>(unixMs);
    for (int i = 7; i >= 0; --i) {
        aad[i] = static_cast<char>(v & 0xFF);
        v >>= 8;
    }
    return aad;
}

QByteArray FreshBetaCrypto::rsaOaepSha256Encrypt(const QByteArray &plaintext, const QByteArray &publicKeyPem)
{
    std::unique_ptr<BIO, BioFree> bio(BIO_new_mem_buf(publicKeyPem.constData(), publicKeyPem.size()));
    if (!bio) throw std::runtime_error("FreshBetaCrypto: BIO_new_mem_buf failed");

    EVP_PKEY *rawPkey = PEM_read_bio_PUBKEY(bio.get(), nullptr, nullptr, nullptr);
    if (!rawPkey) throw std::runtime_error("FreshBetaCrypto: PEM_read_bio_PUBKEY failed");
    std::unique_ptr<EVP_PKEY, PkeyFree> pkey(rawPkey);

    std::unique_ptr<EVP_PKEY_CTX, PkeyCtxFree> ctx(EVP_PKEY_CTX_new(pkey.get(), nullptr));
    if (!ctx) throw std::runtime_error("FreshBetaCrypto: EVP_PKEY_CTX_new failed");
    if (EVP_PKEY_encrypt_init(ctx.get()) <= 0)
        throw std::runtime_error("FreshBetaCrypto: EVP_PKEY_encrypt_init failed");
    if (EVP_PKEY_CTX_set_rsa_padding(ctx.get(), RSA_PKCS1_OAEP_PADDING) <= 0)
        throw std::runtime_error("FreshBetaCrypto: set OAEP padding failed");
    if (EVP_PKEY_CTX_set_rsa_oaep_md(ctx.get(), EVP_sha256()) <= 0)
        throw std::runtime_error("FreshBetaCrypto: set OAEP md SHA-256 failed");
    if (EVP_PKEY_CTX_set_rsa_mgf1_md(ctx.get(), EVP_sha256()) <= 0)
        throw std::runtime_error("FreshBetaCrypto: set MGF1 md SHA-256 failed");

    const unsigned char *in = reinterpret_cast<const unsigned char *>(plaintext.constData());
    size_t inLen = static_cast<size_t>(plaintext.size());
    size_t outLen = 0;
    if (EVP_PKEY_encrypt(ctx.get(), nullptr, &outLen, in, inLen) <= 0)
        throw std::runtime_error("FreshBetaCrypto: EVP_PKEY_encrypt (size) failed");
    QByteArray out(static_cast<int>(outLen), Qt::Uninitialized);
    if (EVP_PKEY_encrypt(ctx.get(), reinterpret_cast<unsigned char *>(out.data()), &outLen, in, inLen) <= 0)
        throw std::runtime_error("FreshBetaCrypto: EVP_PKEY_encrypt failed");
    out.resize(static_cast<int>(outLen));
    return out;
}

QByteArray FreshBetaCrypto::aesGcmSeal(const QByteArray &plaintext, const QByteArray &key, const QByteArray &nonce, const QByteArray &aad)
{
    if (key.size() != kAesKeyLen) throw std::runtime_error("FreshBetaCrypto: GCM key must be 32 bytes");
    if (nonce.size() != kNonceLen) throw std::runtime_error("FreshBetaCrypto: GCM nonce must be 12 bytes");

    std::unique_ptr<EVP_CIPHER_CTX, EvpCtxFree> ctx(EVP_CIPHER_CTX_new());
    if (!ctx) throw std::runtime_error("FreshBetaCrypto: EVP_CIPHER_CTX_new failed");
    if (EVP_EncryptInit_ex(ctx.get(), EVP_aes_256_gcm(), nullptr, nullptr, nullptr) != 1)
        throw std::runtime_error("FreshBetaCrypto: EncryptInit (gcm) failed");
    if (EVP_CIPHER_CTX_ctrl(ctx.get(), EVP_CTRL_GCM_SET_IVLEN, kNonceLen, nullptr) != 1)
        throw std::runtime_error("FreshBetaCrypto: set GCM ivlen failed");
    if (EVP_EncryptInit_ex(ctx.get(), nullptr, nullptr, reinterpret_cast<const unsigned char *>(key.constData()), reinterpret_cast<const unsigned char *>(nonce.constData())) != 1)
        throw std::runtime_error("FreshBetaCrypto: EncryptInit key/iv failed");

    int len = 0;
    if (!aad.isEmpty()) {
        if (EVP_EncryptUpdate(ctx.get(), nullptr, &len, reinterpret_cast<const unsigned char *>(aad.constData()), aad.size()) != 1)
            throw std::runtime_error("FreshBetaCrypto: GCM aad update failed");
    }
    QByteArray cipher(plaintext.size(), Qt::Uninitialized);
    int cipherLen = 0;
    if (EVP_EncryptUpdate(ctx.get(), reinterpret_cast<unsigned char *>(cipher.data()), &len, reinterpret_cast<const unsigned char *>(plaintext.constData()), plaintext.size()) != 1)
        throw std::runtime_error("FreshBetaCrypto: GCM encrypt update failed");
    cipherLen = len;
    if (EVP_EncryptFinal_ex(ctx.get(), reinterpret_cast<unsigned char *>(cipher.data()) + cipherLen, &len) != 1)
        throw std::runtime_error("FreshBetaCrypto: GCM encrypt final failed");
    cipherLen += len;
    cipher.resize(cipherLen);

    QByteArray tag(kGcmTagLen, Qt::Uninitialized);
    if (EVP_CIPHER_CTX_ctrl(ctx.get(), EVP_CTRL_GCM_GET_TAG, kGcmTagLen, tag.data()) != 1)
        throw std::runtime_error("FreshBetaCrypto: GCM get tag failed");
    return cipher + tag;
}

QByteArray FreshBetaCrypto::aesGcmOpen(const QByteArray &ctAndTag, const QByteArray &key, const QByteArray &nonce, const QByteArray &aad)
{
    if (key.size() != kAesKeyLen) throw std::runtime_error("FreshBetaCrypto: GCM key must be 32 bytes");
    if (nonce.size() != kNonceLen) throw std::runtime_error("FreshBetaCrypto: GCM nonce must be 12 bytes");
    if (ctAndTag.size() < kGcmTagLen) throw std::runtime_error("FreshBetaCrypto: GCM input too short");

    const int cipherLen = ctAndTag.size() - kGcmTagLen;
    const QByteArray cipher = ctAndTag.left(cipherLen);
    const QByteArray tag = ctAndTag.right(kGcmTagLen);

    std::unique_ptr<EVP_CIPHER_CTX, EvpCtxFree> ctx(EVP_CIPHER_CTX_new());
    if (!ctx) throw std::runtime_error("FreshBetaCrypto: EVP_CIPHER_CTX_new failed");
    if (EVP_DecryptInit_ex(ctx.get(), EVP_aes_256_gcm(), nullptr, nullptr, nullptr) != 1)
        throw std::runtime_error("FreshBetaCrypto: DecryptInit (gcm) failed");
    if (EVP_CIPHER_CTX_ctrl(ctx.get(), EVP_CTRL_GCM_SET_IVLEN, kNonceLen, nullptr) != 1)
        throw std::runtime_error("FreshBetaCrypto: set GCM ivlen failed");
    if (EVP_DecryptInit_ex(ctx.get(), nullptr, nullptr, reinterpret_cast<const unsigned char *>(key.constData()), reinterpret_cast<const unsigned char *>(nonce.constData())) != 1)
        throw std::runtime_error("FreshBetaCrypto: DecryptInit key/iv failed");

    int len = 0;
    if (!aad.isEmpty()) {
        if (EVP_DecryptUpdate(ctx.get(), nullptr, &len, reinterpret_cast<const unsigned char *>(aad.constData()), aad.size()) != 1)
            throw std::runtime_error("FreshBetaCrypto: GCM aad update failed");
    }
    QByteArray plain(cipherLen, Qt::Uninitialized);
    int plainLen = 0;
    if (EVP_DecryptUpdate(ctx.get(), reinterpret_cast<unsigned char *>(plain.data()), &len, reinterpret_cast<const unsigned char *>(cipher.constData()), cipherLen) != 1)
        throw std::runtime_error("FreshBetaCrypto: GCM decrypt update failed");
    plainLen = len;

    if (EVP_CIPHER_CTX_ctrl(ctx.get(), EVP_CTRL_GCM_SET_TAG, kGcmTagLen, const_cast<char *>(tag.constData())) != 1)
        throw std::runtime_error("FreshBetaCrypto: GCM set tag failed");
    if (EVP_DecryptFinal_ex(ctx.get(), reinterpret_cast<unsigned char *>(plain.data()) + plainLen, &len) != 1)
        throw std::runtime_error("FreshBetaCrypto: GCM auth failed (tampered or wrong key)");
    plainLen += len;
    plain.resize(plainLen);
    return plain;
}
