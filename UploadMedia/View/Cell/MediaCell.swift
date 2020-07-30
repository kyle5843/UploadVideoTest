//
//  MediaCell.swift
//  UploadMedia
//
//  Created by Kyle on 2020/7/4.
//  Copyright © 2020 All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol BaseTableCell : UITableViewCell {
    var indexPath: IndexPath? { get set }
    func setData(_ viewModel:BaseCellModel,_ indexPath: IndexPath)
}

class MediaCell: UITableViewCell, BaseTableCell {
    var indexPath: IndexPath?
    var disposeBag = DisposeBag()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        DispatchQueue.main.async {
            self.addSubview(self.split)
            self.selectionStyle = .none
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    lazy var split:UIView = {
        let line = UIView.init(frame: CGRect(x: 0, y: self.bounds.height - 2, width: self.bounds.width, height: 2))
        line.backgroundColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 0.8)
        return line
    }()
    
    lazy var thumbNail:UIImageView = {
        let imgView = UIImageView.init(frame: CGRect(x: 0, y: 0, width: self.bounds.height - 2, height: self.bounds.height - 2))
        imgView.backgroundColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        self.addSubview(imgView)
        return imgView
    }()
    
    lazy var state:UILabel = {
        let posX = self.thumbNail.frame.maxX
        let state = UILabel.init(frame: CGRect.init(x: posX, y: 0, width: self.bounds.width - posX, height: self.bounds.height))
        state.textAlignment = .center
        state.numberOfLines = 0
        state.adjustsFontSizeToFitWidth = true
        self.addSubview(state)
        return state
    }()
    
    var viewModel:MediaCellModel? {
        didSet {
            self.thumbNail.image = nil
            self.state.text = viewModel?.info.state.rawValue
            self.setThumbNailAsync()
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    func setData(_ viewModel: BaseCellModel,_ indexPath: IndexPath) {
        self.indexPath = indexPath
        self.viewModel = viewModel as? MediaCellModel
        self.bind()
    }
    
    func bind() {
        self.disposeBag = DisposeBag()
        self.viewModel!.info.title.asObservable()
            .observeOn(MainScheduler.instance)
            .bind(to:self.state.rx.text)
            .disposed(by:disposeBag)
    }
    
    func setThumbNailAsync() {
        DispatchQueue.global().async {
            let thumbNail = self.viewModel?.info.thunmbNail
            if self.indexPath == self.viewModel?.indexPath {
                DispatchQueue.main.async {
                    self.thumbNail.image = thumbNail
                }
            }
        }
    }
    
}
