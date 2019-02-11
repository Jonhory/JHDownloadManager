//
//  TestCell.swift
//  JHDownloadManager
//
//  Created by Jonhory on 2019/1/29.
//  Copyright © 2019 jdj. All rights reserved.
//

import UIKit

private let TestCellID = "TestCellID"

extension UIColor {
    //返回随机颜色
    class var randomColor: UIColor {
        get {
            let red = CGFloat(arc4random() % 256) / 255.0
            let green = CGFloat(arc4random() % 256) / 255.0
            let blue = CGFloat(arc4random() % 256) / 255.0
            return UIColor(red: red, green: green, blue: blue, alpha: 0.5)
        }
    }
}

protocol TestCellDelegate: class {
    
    func beginDownload(_ model: TestCellModel)
    func delete(_ model: TestCellModel, _ cell: TestCell)
}

class TestCell: UITableViewCell {

    weak var delegate: TestCellDelegate?
    
    class func configWith(_ table: UITableView) -> TestCell {
        var cell = table.dequeueReusableCell(withIdentifier: TestCellID)
        if cell == nil {
            cell = TestCell(style: .default, reuseIdentifier: TestCellID)
        }
        return cell as! TestCell
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        loadUI()
    }
    
    @objc func btnClicked(_ btn: UIButton) {
        if btn.backgroundColor == .blue {
            delegate?.beginDownload(model!)
        } else {
            delegate?.delete(model!, self)
        }
    }
    
    
    var model: TestCellModel? {
        didSet {
            if model == nil { return }

            contentView.backgroundColor = model!.backColor
            showDatasToUI()
        }
    }
    
    func showDatasToUI() {
        progressLabel.text = String(format: "%.2f %%", model!.progress*100.0)
        speedLabel.text = model!.speed + "/s"
        stateBtn.setTitle(model!.state, for: .normal)
        progress.progress = model!.progress
        indexL.text = model!.index
    }
    
    var progressLabel: UILabel = {
        let l = UILabel()
        l.text = "0.00%"
        l.textAlignment = .center
        l.backgroundColor = .black
        l.textColor = .white
        return l
    }()
    
    var stateBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("开始", for: .normal)
        btn.backgroundColor = .blue
        btn.setTitleColor(.white, for: .normal)
        return btn
    }()
    
    var deleteBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("删除", for: .normal)
        btn.backgroundColor = .red
        btn.setTitleColor(.white, for: .normal)
        return btn
    }()
    
    var progress: UIProgressView = {
        let p = UIProgressView(progressViewStyle: .default)
        p.progressTintColor = .red
        p.trackTintColor = .gray
        return p
    }()
    
    var speedLabel: UILabel = {
        let l = UILabel()
        l.text = "0 kb/s"
        l.textAlignment = .center
        l.backgroundColor = .black
        l.textColor = .white
        return l
    }()
    
    var indexL: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

extension TestCell {
    
    func loadUI() {
        let margin: CGFloat = 12
        let btnW: CGFloat = 60
        let btnH: CGFloat = 30
        progressLabel.frame = CGRect(x: margin, y: margin, width: 80, height: btnH)
        speedLabel.frame = CGRect(x: 0, y: 0, width: 100, height: btnH - 10)
        
        progress.frame = CGRect(x: progressLabel.frame.maxX + margin, y: margin, width: screen.width - progressLabel.frame.maxX - margin*4 - btnW*2, height: 2)
        stateBtn.frame = CGRect(x: screen.width - btnW*2 - margin*2, y: margin, width: btnW, height: btnH)
        deleteBtn.frame = CGRect(x: stateBtn.frame.maxX+margin, y: margin, width: btnW, height:
            btnH)
        
        stateBtn.addTarget(self, action: #selector(btnClicked(_:)), for: .touchUpInside)
        deleteBtn.addTarget(self, action: #selector(btnClicked(_:)), for: .touchUpInside)
        
        speedLabel.center = CGPoint(x: progress.center.x, y: progress.frame.maxY + margin)
        
        contentView.addSubview(progressLabel)
        contentView.addSubview(progress)
        contentView.addSubview(stateBtn)
        contentView.addSubview(speedLabel)
        contentView.addSubview(deleteBtn)
        
        contentView.backgroundColor = UIColor.randomColor
        
        indexL = UILabel(frame: CGRect(x: margin, y: progressLabel.frame.maxY + margin, width: progressLabel.frame.width, height: 20))
        contentView.addSubview(indexL)
        
    }
}
