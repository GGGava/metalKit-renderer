//
//  Utils.swift
//  VideoTest
//
//  Created by Gustavo Gava on 8/12/21.
//

import Foundation
import MetalKit

struct Vertex
{
    let position: vector_float2
    let textureCoordinate: vector_float2
}

public extension UIImage {
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
        }
    }

class Primitive {
    class func makeCube(device: MTLDevice, size: Float) -> MDLMesh {
        let allocator = MTKMeshBufferAllocator(device: device)
        let mesh = MDLMesh(boxWithExtent: [size, size, size],
                           segments: [1, 1, 1],
                           inwardNormals: false, geometryType: .triangles,
                           allocator: allocator)
        return mesh
    }
    
    class func makePlane(device: MTLDevice, size: Float) -> MDLMesh {
        let allocator = MTKMeshBufferAllocator(device: device)
        let mesh = MDLMesh(planeWithExtent: [size, size, size], segments: [1,1], geometryType: .triangles, allocator: allocator)
        return mesh
    }
}

struct PixelData {
    var b: UInt8
    var g: UInt8
    var r: UInt8
    var a: UInt8
}
