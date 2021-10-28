//
//  CMSDecoder-Extension.swift
//  Mac@IBM Enrollment Helper
//
//  Created by Jan Valentik on 09/12/2020.
//  Copyright © 2021 IBM Inc. All rights reserved
//  SPDX-License-Identifier: Apache2.0
//

import Foundation
import Security

extension CMSDecoder {
    static func decoder() throws -> CMSDecoder {
        var decoderOptional: CMSDecoder?
        CMSDecoderCreate(&decoderOptional)
        return decoderOptional!
    }

    static func decoder(_ bytes: [UInt8]) throws -> CMSDecoder {
        let newDecoder = try decoder()
        CMSDecoderUpdateMessage(newDecoder, bytes, bytes.count)
        CMSDecoderFinalizeMessage(newDecoder)
        return newDecoder
    }
    static func decoder(_ data: Data) throws -> CMSDecoder {
        try data.withUnsafeBytes { try decoder(Array($0)) }
    }
}

extension CMSDecoder {
    func decrypt() throws -> Data {
        var dataOptional: CFData?
        CMSDecoderCopyContent(self, &dataOptional)
        let data = dataOptional! as Data
        return data
    }
}
