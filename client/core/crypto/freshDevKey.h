#ifndef FRESHDEVKEY_H
#define FRESHDEVKEY_H

// Fresh VPN beta DEV gateway RSA-2048 public key (SPKI PEM).
// DEV/staging only. Prod must inject via CI secrets (CISO control #12).
// Source: work-projects/fresh-vpn-gateway/dev_keys/agw_dev_pub.pem
static const char *const FRESH_DEV_AGW_PUBLIC_KEY_PEM = R"FRESHKEY(
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAu1dIr/1de4HMLZ/4gJbV
uWZv9WZbsRohGWEREyjONr+8Ctv+53OIAxGLWlEMyRIGLXbwFK42GGDOxXB7LF2P
PSgaUXfcJ6Wc4kDnt6ih8y4ieNU3M3mI+LkvDnupYK1HhjEP80EYsK0ExGk00xLd
f13rl1GX8dpzSt0RAU+FZqlI9AVed45hgmHcQiMQW+epFYl9eBohWrTKT2mniLtz
6ASmHS0d7hWeoUtsscI1Ydm2cY8lfNkJeY77LMVNfxedteAKnwcFduBldfZ0QtOr
U8lHZ3a9iRvykd/Sm23bFD+PwrbMnVXtq8qv0cH03M3VuYX6JVmP88CYQW850wuE
dwIDAQAB
-----END PUBLIC KEY-----
)FRESHKEY";


// Fresh VPN update-signing Ed25519 public key (SPKI PEM). PINNED for verify-before-apply (R1).
// Private key lives only on germany /home/georgiy/fresh-update-signing/update_ed25519.pem (chmod600, NOT web-served).
static const char *const FRESH_UPDATE_ED25519_PUB_PEM = R"FRESHUPDKEY(
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEAwvp9Gk89LDMS7/UFTmrkC/8NXFOV+Tk+DmTqQrfOmls=
-----END PUBLIC KEY-----
)FRESHUPDKEY";

#endif // FRESHDEVKEY_H
