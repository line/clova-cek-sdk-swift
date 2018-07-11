/**
 * Copyright 2018 LINE Corporation
 *
 * LINE Corporation licenses this file to you under the Apache License,
 * version 2.0 (the "License"); you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at:
 *
 *   https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations
 * under the License.
 **/

import Foundation
import Kitura
import KituraNet
import Cryptor

#if os(macOS)
import Security
#elseif os(Linux)
import OpenSSL
#endif

/// A public key in PEM format for signature verification
let pubKeyPem = """
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwiMvQNKD/WQcX9KiWNMb
nSR+dJYTWL6TmqqwWFia69TyiobVIfGfxFSefxYyMTcFznoGCpg8aOCAkMxUH58N
0/UtWWvfq0U5FQN9McE3zP+rVL3Qul9fbC2mxvazxpv5KT7HEp780Yew777cVPUv
3+I73z2t0EHnkwMesmpUA/2Rp8fW8vZE4jfiTRm5vSVmW9F37GC5TEhPwaiIkIin
KCrH0rXbfe3jNWR7qKOvVDytcWgRHJqRUuWhwJuAnuuqLvqTyAawqEslhKZ5t+1Z
0GN8b2zMENSuixa1M9K0ZKUw3unzHpvgBlYmXRGPTSuq/EaGYWyckYz8CBq5Lz2Q
UwIDAQAB
-----END PUBLIC KEY-----
"""

/// A simple struct that conforms to Error
public struct VerificationError: Swift.Error {}

#if os(Linux)
/// A utility function that read Data of PEM to BIO
///
/// - Parameter data: A data of PEM encoded using .utf8
/// - Returns: A pointer to PublicKey object
private func readPublicKey(data: Data) -> UnsafeMutablePointer<EVP_PKEY> {
    let bio = BIO_new(BIO_s_mem())
    defer {
        BIO_free(bio)
    }

    data.withUnsafeBytes() { (buffer: UnsafePointer<UInt8>)  in
        BIO_write(bio, buffer, Int32(data.count))
        BIO_ctrl(bio, BIO_CTRL_FLUSH, 0, nil)
    }

    guard let pubkey = PEM_read_bio_PUBKEY(bio, nil, nil, nil) else {
        fatalError("Failed to read PEM")
    }
    return pubkey
}

#endif

#if os(macOS)
/// A public key type for mac OS. Uses Security framework
typealias PublicKey = SecKey
#elseif os(Linux)
/// A public key tyoe for Linux. Uses OpenSSL
typealias PublicKey = UnsafeMutablePointer<EVP_PKEY>
#endif

public class SignatureVerifier {
    /// PEM begin marker
    static private let PEM_BEGIN_MARKER = "-----BEGIN PUBLIC KEY-----"

    /// PEM end marker
    static private let PEM_END_MARKER = "-----END PUBLIC KEY-----"

    /// A function which will be executed only once
    fileprivate static var setupChecker = { () -> Bool in
#if os(Linux)
        SSL_library_init()
#endif
        return true
    }()

    /// A cache of an extracted public key
    private static var pubKey: PublicKey?


    /// Extract a public key from PEM
    ///
    /// - Parameter pem: A PEM format string of a public key
    /// - Returns: Optional object of public key. SecKey? in macOS, UnsafeMutablePointer<EVP_PKEY> in Linux.
    private static func extractPublicKey(pem: String) -> PublicKey? {
        #if os(macOS)
        // Strip prefixes and suffixes of X.509 certificates
        let pemString = String(pem.components(separatedBy: "\n").joined()
            .dropFirst(PEM_BEGIN_MARKER.count)
            .dropLast(PEM_END_MARKER.count))
        guard let data = Data.init(base64Encoded: pemString) else {
                return nil
        }

        var error: Unmanaged<CFError>?
        let pubKey = SecKeyCreateWithData(data as CFData, [kSecAttrKeyType: kSecAttrKeyTypeRSA,
                                                            kSecAttrKeyClass: kSecAttrKeyClassPublic,
                                                            kSecReturnPersistentRef: true] as CFDictionary, &error)
        return pubKey

        #elseif os(Linux)

        let evp_key = readPublicKey(data: pem.data(using: .utf8)!)
        return evp_key
        #endif
    }


    /// Verify a digest of the message body with a given signature
    ///
    /// - Parameters:
    ///   - pubKey: A public key that is another pair of a private key which was used to produce the digest
    ///   - body: A request body
    ///   - signature: An encrypted sha1 hash of the body
    /// - Returns: True if verified
    private static func verifyDigest(pubKey: PublicKey, body: Data, signature: Data) -> Bool {
        #if os(macOS)

        return SecKeyVerifySignature(pubKey,
                                 .rsaSignatureMessagePKCS1v15SHA256,
                                 body as CFData,
                                 signature as CFData,
                                 nil)

        #elseif os(Linux)

        let mdctx = EVP_MD_CTX_create()
        defer {
            EVP_MD_CTX_destroy(mdctx)
        }

        var result: Int32 = 0

        let bodySize = body.count * MemoryLayout<UInt8>.size

        EVP_DigestVerifyInit(mdctx, nil, EVP_sha256(), nil, pubKey)

        body.withUnsafeBytes() { buffer in
            result = EVP_DigestUpdate(mdctx, buffer, bodySize)
        }

        guard result == 1 else {
            return false
        }

        var signatureCopy = signature
        let signatureSize = signature.count * MemoryLayout<UInt8>.size
        signatureCopy.withUnsafeMutableBytes() { (buffer) -> () in
            result = EVP_DigestVerifyFinal(mdctx, buffer, signatureSize)
        }

        return result == 1

        #else

        // Unimplemented
        return false

        #endif
    }


    /// A function to verify a signature. throws
    /// - Throws: VerificationError
    public static func verifyRequest(body: String, headers: Headers) throws {
        _ = setupChecker // Run some logic only once

        guard let signatureCek = headers["SignatureCEK"],
            let signatureData = Data.init(base64Encoded: signatureCek) else {
            throw VerificationError()
        }

        // Extract a public key from the certificate and cache it
        if self.pubKey == nil {
            self.pubKey = extractPublicKey(pem: pubKeyPem)
        }

        // Verify the digest using the public key
        guard let bodyData = body.data(using: .utf8),
            let pubKey = self.pubKey,
            verifyDigest(pubKey: pubKey, body: bodyData, signature: signatureData) == true else {
                throw VerificationError()
        }
    }
}
