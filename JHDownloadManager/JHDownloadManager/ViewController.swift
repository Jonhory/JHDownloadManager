//
//  ViewController.swift
//  JHDownloadManager
//
//  Created by Jonhory on 2019/1/21.
//  Copyright © 2019 jdj. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let testUrl1 = "http://ips.ifeng.com/video19.ifeng.com/video09/2018/03/28/23591189-102-9987625-115926.mp4?vid=4e045192-0b58-4e77-aeed-6e2717ae0070&uid=1539670854082_fhblr64962&from=v_Free&pver=vHTML5Player_v2.0.0&sver=&se=%E6%8F%90%E9%98%BF%E4%B9%88%E7%88%B1%E9%9F%B3%E4%B9%90&cat=212-213&ptype=212&platform=pc&sourceType=h5&dt=1522209518000&gid=XHkhsWhvku6X&sign=415ee2dc6ea9bea8b9808e86fe4be5a5&tm=1548060126873"
    
    let testUrl2 = "https://ss1.bdstatic.com/70cFuXSh_Q1YnxGkpoWK1HF6hhy/it/u=613953350,215982135&fm=26&gp=0.jpg"
    
    let screen = UIScreen.main.bounds.size
    
    var label1: UILabel?
    var label2: UILabel?
    var btn1: UIButton?
    var btn2: UIButton?
    var delete1: UIButton?
    var delete2: UIButton?
    var url1Progress: UIProgressView?
    var url2Progress: UIProgressView?
    
    var deleteAllBtn: UIButton?
    
    let downloadManager = JHDownloadManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = .white
        
        loadUI()
        showCaches()
    }
    
    @objc func btnClicked(_ btn: UIButton) {
        
        if btn == btn1 {
            download(url: testUrl1, lable: label1!, btn: btn1!, p: url1Progress!)
        } else if btn == btn2 {
            download(url: testUrl2, lable: label2!, btn: btn2!, p: url2Progress!)
        } else if btn == delete1 {
            delete(url: testUrl1, lable: label1!, btn: btn1!, p: url1Progress!)
        } else if btn == delete2 {
            delete(url: testUrl2, lable: label2!, btn: btn2!, p: url2Progress!)
        } else if btn == deleteAllBtn {
            downloadManager.deleteAllFiles()
        }
    }
    
    func download(url: String, lable: UILabel, btn: UIButton, p: UIProgressView) {
        
        downloadManager.download(url: url, progress: { (receivedSize, expectedSize, progress) in
            DispatchQueue.main.async {
                lable.text = String(format: "%.2f %%", progress*100.0)
                p.progress = progress
                btn.setTitle("下载中", for: .normal)
            }
        }) { (state) in
            DispatchQueue.main.async {
                btn.setTitle(state.desc, for: .normal)
            }
        }
    }
    
    func delete(url: String, lable: UILabel, btn: UIButton, p: UIProgressView) {
        downloadManager.deleteFile(with: url)
        lable.text = "0.00%"
        btn.setTitle("开始", for: .normal)
        p.progress = 0
    }
    
    func showCaches() {
        let p1 = downloadManager.progressSize(with: testUrl1)
        url1Progress?.progress = p1
        label1?.text = String(format: "%.2f %%", p1 * 100.0)
        if p1 == 1 {
            btn1?.setTitle("完成", for: .normal)
        } else if p1 > 0 {
            btn1?.setTitle("暂停", for: .normal)
        }
        
        let p2 = downloadManager.progressSize(with: testUrl2)
        url2Progress?.progress = p2
        label2?.text = String(format: "%.2f %%", p2 * 100.0)
        if p2 == 1 {
            btn2?.setTitle("完成", for: .normal)
        } else if p2 > 0 {
            btn2?.setTitle("暂停", for: .normal)
        }
        
    }
    
    func loadUI() {
        
        label1 = createLabel(150)
        label2 = createLabel(200)
        
        btn1 =  createBtn(at: 150)
        btn2 = createBtn(at: 200)
        
        url1Progress = createProgressView(at: 150)
        url2Progress = createProgressView(at: 200)
        
        delete1 = createBtn(at: 150, t: "删除", x: btn1!.frame.maxX + 10)
        delete2 = createBtn(at: 200, t: "删除", x: btn1!.frame.maxX + 10)
        
        deleteAllBtn = createBtn(at: screen.height/2, t: "删除全部", x: 0)
        deleteAllBtn?.frame = CGRect(x: 0, y: screen.height/2 + 50, width: screen.width/4, height: 35)
        deleteAllBtn?.center.x = view.center.x
    }

}

extension ViewController {
    
    func createLabel(_ y: CGFloat) -> UILabel {
        let l = UILabel(frame: CGRect(x: 20, y: y, width: screen.width/4 - 30, height: 35))
        l.text = "0.00%"
        l.textColor = .white
        l.backgroundColor = .black
        l.textAlignment = .center
        view.addSubview(l)
        return l
    }
    func createBtn(at y: CGFloat, t: String = "开始", x: CGFloat = UIScreen.main.bounds.width/4*3 - 10) -> UIButton {
        let btn = UIButton(type: .system)
        btn.frame = CGRect(x: x, y: y, width: screen.width/7 - 10, height: 35)
        btn.setTitle(t, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.tag = Int(y)
        btn.addTarget(self, action: #selector(btnClicked(_:)), for: .touchUpInside)
        btn.backgroundColor = .blue
        view.addSubview(btn)
        return btn
    }
    
    func createProgressView(at y: CGFloat) -> UIProgressView {
        let p = UIProgressView(progressViewStyle: .default)
        p.frame = CGRect(x: screen.width/4, y: y, width: screen.width/2 - 20, height: 2)
        p.center.y = y + 35/2
        p.progressTintColor = .red
        p.trackTintColor = .gray
        view.addSubview(p)
        return p
    }
    
}
