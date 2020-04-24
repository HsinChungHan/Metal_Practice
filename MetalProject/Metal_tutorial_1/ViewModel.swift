//
//  ViewModel.swift
//  MetalProject
//
//  Created by Chung Han Hsin on 2020/4/24.
//  Copyright © 2020 Chung Han Hsin. All rights reserved.
//

import Foundation
import Metal
import QuartzCore

class ViewModel: NSObject {
  fileprivate let vertextData: [Float] = [
    0.0, 1.0, 0.0,
    -1.0, -1.0, 0.0,
    1.0, -1.0, 0.0
  ]
  
  func getVertexData() -> [Float] {
    return vertextData
  }
  
  /// 創建 MTLDevice，可以將 MTLDevice 想象成是你和 CPU 的直接連線
  func makeDevice() -> MTLDevice {
    guard
      let device = MTLCreateSystemDefaultDevice()
      else { fatalError("Failed to make MTLDevice") }
    return device
  }
  
  /// 創建 CAMetalLayer。
  /// 在iOS裡,你在螢幕上看見的所有東西,被一個CALayer所承載。存在不同特效的CALayer的子類,比如:漸變層(gradient layers)、形狀層(shape layers)、重複層(replicator layers) 等等
  /// 若想要用Metal在螢幕上畫一些東西,你需要使用一個特別的CALayer子類,CAMetalLayer。
  /// - Parameters:
  ///   - device: 通過使用 MTLDevice 建立所有其他你需要的 Metal 物件(像是command queues,buffers,textures)
  ///   - pixelFormat: 8位元組代表藍色、綠色、紅色和透明度,通過在0到1之間單位化的值來表示
  ///   - framebufferOnly: 蘋果鼓勵你設定framebufferOnly為true,來增強表現效率。除非你需要對從layer生成的紋理(textures)取樣,或者你需要在layer繪圖紋理(drawable textures)啟用一些計算核心,否則你不需要設定
  func makeCAMetalLayer(device: MTLDevice, pixelFormat: MTLPixelFormat, framebufferOnly: Bool) -> CAMetalLayer {
    let metalLayer = CAMetalLayer()
    metalLayer.device = device
    metalLayer.pixelFormat = pixelFormat
    metalLayer.framebufferOnly = framebufferOnly
    return metalLayer
  }
  
  
  /// 在GPU建立一個新的buffer,並把 vertex data 從 CPU裡輸送過去
  /// 在Metal裡每一個東西都是三角形。在這個應用裡,你只需要畫一個三角形
  /// 不過即使是極其複雜的3D形狀也能被解構為一系列的三角形
  /// - Parameters:
  ///   - device: 通過使用 MTLDevice 建立所有其他你需要的 Metal 物件(像是command queues,buffers,textures)
  ///   - verTextData: 一個三角形的三個頂點，每個頂點都有三個維度(x, y, z)
  func makeMTLBuffer(device: MTLDevice, verTextData: [Float]) -> MTLBuffer {
    //需要獲取vertex data的位元組大小。通過把第一個元素的 size 和陣列元素個數相乘來得到
    let dataSize = verTextData.count * MemoryLayout.size(ofValue: verTextData.first!)
    guard let vertextBuffer = device.makeBuffer(bytes: verTextData, length: dataSize, options: []) else {
      fatalError("faile to create a vertext buffer")
    }
    return vertextBuffer
  }
  
  
  /// 在這裡設定 render pipeline
  /// - Parameters:
  ///   - device: 通過使用 MTLDevice 建立所有其他你需要的 Metal 物件(像是command queues,buffers,textures)
  ///   - vertexName: 定義在 Shader.metal 的 vertex function name
  ///   - fragmentName: 定義在 Shader.metal 的 fragment function name
  func makePipelineState(device: MTLDevice, vertexName: String, fragmentName: String) -> MTLRenderPipelineState {
    //可以通過呼叫device.newDefaultLibrary方法
    //獲得的MTLibrary物件訪問到你專案中的預編譯shaders。然後你能夠通過名字檢索每個shader
    
    guard
      let defaultLibrary = device.makeDefaultLibrary()
      else {
        fatalError("Failed to make default library from device")
    }
    
    guard
      let vertexProgram = defaultLibrary.makeFunction(name: vertexName)
      else {
        fatalError("Failed to make vertexProgram from shader")
    }
    
    guard
      let fragmentProgram = defaultLibrary.makeFunction(name: fragmentName)
      else {
        fatalError("Failed to make fragmentProgram from shader")
    }
    
    /*
     在這裡設定你的render pipeline。它包含你想要使用的shaders、顏色附件(color attachment)的畫素格式(pixel format)。
     (例如:你渲染到的輸入緩衝區,也就是CAMetalLayer)。
     */
    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.vertexFunction = vertexProgram
    pipelineStateDescriptor.fragmentFunction = fragmentProgram
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    
    //最後,你把這個 pipeline 配置編譯到一個 pipeline 狀態(state)中,讓它使用起來有效率
    do {
      let pipelineState = try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
      return pipelineState
    }catch let error {
      fatalError("Failed to create a pipelineState: \(error.localizedDescription)")
    }
  }
  
  /// 想象成是一個列表裝載著你告訴 GPU 一次要執行的命令
  /// - Parameter device: 通過使用 MTLDevice 建立所有其他你需要的 Metal 物件(像是command queues,buffers,textures)
  func makeCommandQueue(device: MTLDevice) -> MTLCommandQueue {
    guard let commandQueue = device.makeCommandQueue() else {
      fatalError("Failed to make command queue")
    }
    return commandQueue
  }
}
