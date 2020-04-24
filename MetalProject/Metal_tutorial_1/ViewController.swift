//
//  ViewController.swift
//  MetalProject
//
//  Created by Chung Han Hsin on 2020/4/21.
//  Copyright © 2020 Chung Han Hsin. All rights reserved.
//  https://www.raywenderlich.com/7475-metal-tutorial-getting-started

import UIKit
import Metal
//因為 CAMetalLayer 是 QuartzCore 框架的部分,而不是 Metal 框架裡的。
import QuartzCore

class ViewController: UIViewController {
  fileprivate let viewModel = ViewModel()
  fileprivate lazy var device = viewModel.makeDevice()
  fileprivate lazy var metalLayer = viewModel.makeCAMetalLayer(device: device, pixelFormat: .bgra8Unorm, framebufferOnly: true)
  fileprivate lazy var vertexBuffer = viewModel.makeMTLBuffer(device: device, verTextData: viewModel.getVertexData())
  fileprivate lazy var pipelineState = viewModel.makePipelineState(device: device, vertexName: "basic_vertex", fragmentName: "basic_fragment")
  fileprivate lazy var commandQueue = viewModel.makeCommandQueue(device: device)
  fileprivate lazy var timer = makeTimer()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setCAMetalLayer(metalLayer: metalLayer, superView: view)
    timer.add(to: .main, forMode: .default)
  }
}

//MARK: - Lazy Initialization
extension ViewController {
  
  /// 建立一個 Display link 來 render 這個三角型
  /// 想要一個函式,在每次裝置螢幕重新整理的時候被呼叫,這樣你就可以重繪螢幕
  fileprivate func makeTimer() -> CADisplayLink {
    let timer = CADisplayLink(target: self, selector: #selector(gameLoop))
    return timer
  }
  
  @objc
  fileprivate func gameLoop() {
    autoreleasepool {
      render(metalLayer: metalLayer, pipelineState: pipelineState, vertextBuffer: vertexBuffer)
    }
  }
  
}

//MARK: - Supporting Function
extension ViewController {
  
  /// 設定 CAMetalLayer 的 frame，並添加為 view 的 superLayer
  fileprivate func setCAMetalLayer(metalLayer: CAMetalLayer, superView: UIView) {
    metalLayer.frame = superView.layer.frame
    superView.layer.addSublayer(metalLayer)
  }
  
  ///一個command buffer包含一個或多個渲染指令(render commands)
  fileprivate func makeCommandBuffer(commandQueue: MTLCommandQueue) -> MTLCommandBuffer {
    guard let commandBuffer = commandQueue.makeCommandBuffer() else {
      fatalError("Failed to create a command buffer")
    }
    return commandBuffer
  }
  
  /// 在 metalLayer 上渲染你的 vertexData
  fileprivate func render(metalLayer: CAMetalLayer, pipelineState: MTLRenderPipelineState, vertextBuffer: MTLBuffer) {
    //renderPassDescriptor 能配置什麼紋理會被渲染到、什麼是clear color,以及其他的配置
    guard
      let drawable = metalLayer.nextDrawable()
      else { fatalError("Failed to get a drawable from metalLayer") }
    
    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture
    //load action為clear,也就是說在繪製之前,把紋理清空
    renderPassDescriptor.colorAttachments[0].loadAction = .clear
    //把繪製的背景顏色設定為綠色
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0)
    
    
    //你可以把它想象為一系列這一幀想要執行的渲染命令
    //在你提交command buffer之前,沒有事情會真正發生
    //一個command buffer包含一個或多個渲染指令(render commands)
    let commandBuffer = makeCommandBuffer(commandQueue: commandQueue)
    
    
    //建立一個渲染命令(render command),使用一個名叫render command encoder的物件
    guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
      fatalError("Failed to create a render encoder")
    }
    renderEncoder.setRenderPipelineState(pipelineState)
    renderEncoder.setVertexBuffer(vertextBuffer, offset: 0, index: 0)
    
    //告訴GPU,讓它基於vertex buffer畫一系列的三角形。每個三角形由三個頂點組成,從vertex buffer 第一個頂點開始,總共有一個三角形
    renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
    renderEncoder.endEncoding()
    
    
    //提交Command Buffer
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}
