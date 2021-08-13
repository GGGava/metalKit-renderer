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
    
    var bitmaps: [[PixelData]]!
    let size = 400
    var currentImage = 0
    
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
        
        //REMOVABLE
        let black = Array(repeating: PixelData(b: 0, g: 0, r: 0, a: 255), count: size*size)
        bitmaps = Array(repeating: black, count: 20)
        for i in 0...19 {
            createBitmap(i)
        }
        //
        
        metalView.clearColor = MTLClearColor(red: 1.0, green: 1.0,
                                             blue: 0.8, alpha: 1.0)
        metalView.delegate = self
    }
    
    func createTexture() -> MTLTexture {
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
        let texture = nextImage()
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

extension Renderer {
    func createBitmap(_ step: Int = 0) {
        
        let red = PixelData(b: 0, g: 0, r: 255, a: 255)
        for i in 0..<size*size/3 {
            bitmaps[step][i+(step*size*10)] = red
        }
    }
    
    func createTexture(pixels: [PixelData], width: Int, height: Int) -> MTLTexture? {
        var arr = pixels
        let descriptor = MTLTextureDescriptor()
        descriptor.pixelFormat = .bgra8Unorm
        descriptor.width = width
        descriptor.height = height
        let texture = self.device.makeTexture(descriptor: descriptor)
        let bytesPerRow = 4 * width
        
        let region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: width, height: height, depth: 1))
        texture?.replace(region: region, mipmapLevel: 0, withBytes: &arr, bytesPerRow: bytesPerRow)
        return texture
    }
    
    func nextImage() -> MTLTexture {
        let img = self.createTexture(pixels: self.bitmaps[currentImage], width: self.size, height: self.size)
        self.currentImage = (currentImage + 1) % self.bitmaps.count
        return img!
    }
}
