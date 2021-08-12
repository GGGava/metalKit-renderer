//
//  ViewController.swift
//  VideoTest
//
//  Created by Gustavo Gava on 8/5/21.
//

import UIKit
import MetalKit
import Alloy

class ViewController: UIViewController {
    @IBOutlet weak var metalView: MTKView!
    var renderer: Renderer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        renderer = Renderer(metalView: metalView)
    }
}

