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
    
    var numVertices: Int = 0
    var viewport: vector_uint2 = [0,0]
    let image = UIImage(named: "puppy")!
    
    init(metalView: MTKView) {
        self.metalView = metalView

        guard let device = MTLCreateSystemDefaultDevice() else {
          fatalError("GPU not available")
        }
        self.device = device
        metalView.device = device
        self.commandQueue = device.makeCommandQueue()!
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: "samplingShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        var quadVertices = [
            Vertex(position: [250, -250], textureCoordinate: [1, 1]),
            Vertex(position: [-250, -250], textureCoordinate: [0, 1]),
            Vertex(position: [-250, 250], textureCoordinate: [0, 0]),
            
            Vertex(position: [250, -250], textureCoordinate: [1, 1]),
            Vertex(position: [-250, 250], textureCoordinate: [0, 0]),
            Vertex(position: [250, 250], textureCoordinate: [1, 0]),
        ]
        
        vertexBuffer = device.makeBuffer(bytes: &quadVertices, length: 96, options: .storageModeShared)
        numVertices = quadVertices.count

        
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
        let textureLoader = MTKTextureLoader(device: self.device)
        let usage: MTLTextureUsage = [.shaderRead]
        let options: [MTKTextureLoader.Option: Any] = [
            .textureUsage: NSNumber(value: usage.rawValue),
            .generateMipmaps: NSNumber(value: false)
        ]
        let texture = try! textureLoader.newTexture(cgImage: image.cgImage!, options: options)
        return texture
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.viewport = vector_uint2(x: UInt32(size.width), y: UInt32(size.height))
    }

    func draw(in view: MTKView) {
        let texture = createTexture()
        guard let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = self.commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
                return
        }
        renderEncoder.setViewport(
            MTLViewport(originX: 0,
                        originY: 0,
                        width: Double(self.viewport.x),
                        height: Double(self.viewport.y),
                        znear: -1,
                        zfar: 1
            )
        )
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBytes(&self.viewport, length: MemoryLayout.size(ofValue: self.viewport), index: 1)
        
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: numVertices)
    

        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else {
          return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()

    }
}

