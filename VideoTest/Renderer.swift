//
//  Renderer.swift
//  VideoTest
//
//  Created by Gustavo Gava on 8/12/21.
//

import Foundation
import MetalKit

class Renderer: NSObject {
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var mesh: MTKMesh!
    var vertexBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState!
    let metalView: MTKView
    
    var timer: Float = 0

    
    init(metalView: MTKView) {
        self.metalView = metalView

        guard let device = MTLCreateSystemDefaultDevice() else {
          fatalError("GPU not available")
        }
        self.device = device
        metalView.device = device
        self.commandQueue = device.makeCommandQueue()!
        
        let mdlMesh = Primitive.makeCube(device: device, size: 1)
        //let mdlMesh = Primitive.makePlane(device: device, size: 1)
        do {
            mesh = try MTKMesh(mesh: mdlMesh, device: device)
        } catch let error {
            print(error.localizedDescription)
        }

        vertexBuffer = mesh.vertexBuffers[0].buffer
        
        
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mdlMesh.vertexDescriptor)
        
        metalView.depthStencilPixelFormat = .invalid
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        super.init()
        
        metalView.clearColor = MTLClearColor(red: 1.0, green: 1.0,
                                             blue: 0.8, alpha: 1.0)
        metalView.delegate = self
    }
    
    func createTexture() -> MTLTexture {
        //let image = UIImage(named: "puppy")!
        let image = UIImage(color: .black)!
        let textureLoader = MTKTextureLoader(device: self.device)
        let usage: MTLTextureUsage = [.shaderRead]
        let options: [MTKTextureLoader.Option: Any] = [
            .textureUsage: NSNumber(value: usage.rawValue),
            .generateMipmaps: NSNumber(value: false)
        ]
        let texture = try! textureLoader.newTexture(cgImage: image.cgImage!, options: options)
        return texture
//        let descriptor = MTLTextureDescriptor()
//        descriptor.pixelFormat = .bgra8Unorm
//        descriptor.width = Int(image.size.width)
//        descriptor.height = Int(image.size.height)
//        let texture = Renderer.device.makeTexture(descriptor: descriptor)
        
//        let bytesPerRow = Int(4 * image.size.width)
//        let region = MTLRegion(
//            origin: MTLOrigin(x: 0, y: 0, z: 0),
//            size: MTLSize(width: Int(image.size.width), height: Int(image.size.height), depth: 1)
//        )
//        texture?.replace(region: region, mipmapLevel: 0, withBytes: image.cgImage!, bytesPerRow: bytesPerRow)
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }

    func draw(in view: MTKView) {
        let _ = createTexture()
        guard let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = self.commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
                return
        }
        
        timer += 0.05
        var currentTime = sin(timer)
        renderEncoder.setVertexBytes(&currentTime,
                                      length: MemoryLayout<Float>.stride,
                                      index: 1)


        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        for submesh in mesh.submeshes {
            renderEncoder.drawIndexedPrimitives(type: .triangle,
            indexCount: submesh.indexCount,
            indexType: submesh.indexType,
            indexBuffer: submesh.indexBuffer.buffer,
            indexBufferOffset: submesh.indexBuffer.offset)
        }


        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else {
          return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()

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

