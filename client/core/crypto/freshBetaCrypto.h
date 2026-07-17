#ifndef FRESHBETACRYPTO_H
#define FRESHBETACRYPTO_H

#include <QByteArray>

// Fresh VPN Beta transport envelope crypto (variant beta).
// Source of truth: fresh-vpn-gateway/ENVELOPE.md and crypto.py (client_seal/client_open).
// Vetted only, OpenSSL EVP - no custom crypto.
//   RSA-OAEP SHA-256: OAEP digest + MGF1 digest both SHA-256 (set explicitly).
//   AES-256-GCM (AEAD), 12-byte nonce, 16-byte tag.
// Functions throw std::runtime_error on failure (caught by caller).

namespace FreshBetaCrypto
{
    constexpr int kAesKeyLen = 32;
    constexpr int kNonceLen = 12;
    constexpr int kGcmTagLen = 16;

    QByteArray randomBytes(int size);
    QByteArray rsaOaepSha256Encrypt(const QByteArray &plaintext, const QByteArray &publicKeyPem);
    QByteArray aesGcmSeal(const QByteArray &plaintext, const QByteArray &key, const QByteArray &nonce, const QByteArray &aad);
    QByteArray aesGcmOpen(const QByteArray &ctAndTag, const QByteArray &key, const QByteArray &nonce, const QByteArray &aad);
    QByteArray tsAadBigEndian(qint64 unixMs);
} // namespace FreshBetaCrypto

#endif // FRESHBETACRYPTO_H
