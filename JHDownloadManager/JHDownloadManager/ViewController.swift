//
//  ViewController.swift
//  JHDownloadManager
//
//  Created by Jonhory on 2019/1/21.
//  Copyright © 2019 jdj. All rights reserved.
//

import UIKit

let screen = UIScreen.main.bounds.size

class ViewController: UIViewController {

    let testUrl = "http://ips.ifeng.com/video19.ifeng.com/video09/2018/03/28/23591189-102-9987625-115926.mp4?vid=4e045192-0b58-4e77-aeed-6e2717ae0070&uid=1539670854082_fhblr64962&from=v_Free&pver=vHTML5Player_v2.0.0&sver=&se=%E6%8F%90%E9%98%BF%E4%B9%88%E7%88%B1%E9%9F%B3%E4%B9%90&cat=212-213&ptype=212&platform=pc&sourceType=h5&dt=1522209518000&gid=XHkhsWhvku6X&sign=415ee2dc6ea9bea8b9808e86fe4be5a5&tm=1548060126873"
    
    let testUrl2 = "https://ss1.bdstatic.com/70cFuXSh_Q1YnxGkpoWK1HF6hhy/it/u=613953350,215982135&fm=26&gp=0.jpg"
    
    var deleteAllBtn: UIButton?
    
    let downloadManager = JHDownloadManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = .white
        
        downloadManager.cachesDirName = "videoCache"
        print("缓存路径: ", downloadManager.cachesDirectory)
        loadTestModels()
        loadTable()
    }
    
    @objc func btnClicked(_ btn: UIButton) {
        downloadManager.deleteAllFiles()
        
        for m in testDatas {
            m.reload()
        }
        tableView.reloadData()
    }
    
    var testDatas: [TestCellModel] = []
    lazy var tableView: UITableView = {
        let table = UITableView(frame: CGRect.zero, style: .grouped)
        table.delegate = self
        table.dataSource = self
        table.tableFooterView = UIView()
        table.rowHeight = 12*2 + 30 + 20
        table.backgroundColor = .lightGray
        table.separatorStyle = .none
        return table
    }()

}

extension ViewController {
    
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
    
    func loadTestModels() {
        for i in 0..<30 {
            let m = TestCellModel()
            m.url = testUrl + "&\(i)"
            m.index = "\(i)"
            testDatas.append(m)
        }
    }
}

extension ViewController {
    
    func loadTable() {
        tableView.frame = CGRect(x: 0, y: 88, width: screen.width, height: screen.height - 88 - 83)
        view.addSubview(tableView)
        
        deleteAllBtn = createBtn(at: screen.height/2, t: "删除全部", x: 0)
        deleteAllBtn?.frame = CGRect(x: 0, y: tableView.frame.maxY + 2, width: screen.width/4, height: 35)
        deleteAllBtn?.center.x = view.center.x
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return testDatas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = TestCell.configWith(tableView)
        cell.model = testDatas[indexPath.row]
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
}

extension ViewController: UITableViewDataSource {
    
}

extension ViewController: TestCellDelegate {
    
    func beginDownload(_ model: TestCellModel) {
        downloadManager.download(url: model.url, name: "文件名" + model.index, type: "mov",  progress: { (receivedSize, expectedSize,  progress, speed) in
            
            model.speed = speed
            model.progress = progress

            if let cell = self.tableView.cellForRow(at: IndexPath(row: Int(model.index)!, section: 0)) as? TestCell {
                cell.showDatasToUI()
            }
            
        }) { (state, error) in
            
            model.state = state.desc
            
            if let cell = self.tableView.cellForRow(at: IndexPath(row: Int(model.index)!, section: 0)) as? TestCell {
                cell.showDatasToUI()
            }
        }
    }
    
    func delete(_ model: TestCellModel, _ cell: TestCell) {
        
        downloadManager.deleteFile(with: model.url)
        model.reload()
        cell.showDatasToUI()
    }
    
    
}
