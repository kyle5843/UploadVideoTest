//
//  UploadMediaViewController.swift
//  UploadMedia
//
//  Created by Kyle on 2020/7/19.
//  Copyright © 2020 All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class UploadMediaViewController: UIViewController, BlackNavigationStyle {
    
    let navTitle:String = "MainPage"
    let disposeBag = DisposeBag()
    let btnHeight:CGFloat = 44
    let spacing:CGFloat = 10
    
    let videoPicker = UIImagePickerController()
    lazy var albumButton:UIButton = {
        
        let safeArea = UIApplication.shared.windows[0].safeAreaLayoutGuide.layoutFrame
        let posY = safeArea.height + safeArea.minY - self.btnHeight - self.spacing
        let button = UIButton.init(frame: CGRect(x: self.spacing, y: posY, width: self.view.frame.width / 2 - self.spacing*2, height: self.btnHeight))
        button.backgroundColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        button.setTitle("Select Video", for: UIControl.State.normal)
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        
        self.view.addSubview(button)
        
        return button
    }()
    
    lazy var sendButton:UIButton = {
        
        let safeArea = UIApplication.shared.windows[0].safeAreaLayoutGuide.layoutFrame
        let posY = safeArea.height + safeArea.minY - self.btnHeight - self.spacing
        let width = self.view.frame.width / 2
        let button = UIButton.init(frame: CGRect(x: width + self.spacing, y: posY, width: width - self.spacing*2, height: self.btnHeight))
        button.backgroundColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        button.setTitle("Upload", for: UIControl.State.normal)
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        
        self.view.addSubview(button)
        
        return button
    }()
    
    lazy var videoTableView:UITableView = {
        
        let safeArea = UIApplication.shared.windows[0].safeAreaLayoutGuide.layoutFrame
        let frame = CGRect(x: safeArea.minX, y: safeArea.minY, width: safeArea.width, height: safeArea.height - self.btnHeight - self.spacing*2)
        let tableView = UITableView.init(frame: frame)
        tableView.separatorStyle = .none
        tableView.backgroundColor = #colorLiteral(red: 0.8000000119, green: 0.8000000119, blue: 0.8000000119, alpha: 1)
        
        self.view.addSubview(tableView)
        
        return tableView
    }()
    
    let viewModel = UploadMediaViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        initView()
        bind()
        
        viewModel.requestPrivacy()
    }
    
    private func initView(){
        self.setupNavigation()
        
        self.videoTableView.delegate = self
        self.videoTableView.dataSource = self
        self.videoTableView.register(MediaCell.self, forCellReuseIdentifier: MediaCellModel.identifier)
    }
    
    private func bind(){
        
        self.albumButton.rx.tap.subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            
            // open video picker
            self.videoPicker.delegate = self
            self.videoPicker.mediaTypes = ["public.movie"]
            self.videoPicker.sourceType = .photoLibrary
            self.videoPicker.allowsEditing = true
            self.present(self.videoPicker, animated: true) {}
            
        }).disposed(by: disposeBag)
        
        self.sendButton.rx.tap.subscribe(onNext: { [weak self] in
            
            self?.viewModel.upload()
            
        }).disposed(by: disposeBag)
    }
}

//MARK: UIImagePickerController delegate
extension UploadMediaViewController:UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.videoPicker.dismiss(animated: true) {}
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // type map check
        if Dictionary<UIImagePickerController.InfoKey, Any>.isValidity(dict: info, typeMap: MediaInfo.typeMap()) {
            let info = MediaInfo.init(info: info)
            self.viewModel.videoInfos.append(MediaCellModel.init(info: info))
            self.videoTableView.beginUpdates()
            let indexPath = IndexPath.init(row: self.viewModel.videoInfos.count - 1, section: 0)
            self.videoTableView.insertRows(at: [indexPath], with: .none)
            self.videoTableView.endUpdates()
        }
        
        self.videoPicker.dismiss(animated: true) {}
    }
    
}

//MARK: UITableView delegate
extension UploadMediaViewController:UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.videoInfos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellModel = self.viewModel.videoInfos[indexPath.row]
        cellModel.indexPath = indexPath
        
        let cell:BaseTableCell = tableView.dequeueReusableCell(withIdentifier: cellModel.identifier, for: indexPath) as! BaseTableCell
        cell.setData(cellModel, indexPath)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let cellModel = self.viewModel.videoInfos[indexPath.row]
        cellModel.indexPath = indexPath
        
        return cellModel.cellHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellModel = self.viewModel.videoInfos[indexPath.row]
        cellModel.indexPath = indexPath
        cellModel.hostVC = self
        cellModel.didSelected()
    }
}
