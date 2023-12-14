//
//  CameraDisplayViewController.swift
//  App
//
//  Created by Kim dohyun on 12/11/23.
//

import UIKit

import Core
import DesignSystem
import Photos
import RxDataSources
import RxSwift
import RxCocoa
import ReactorKit
import SnapKit


public final class CameraDisplayViewController: BaseViewController<CameraDisplayViewReactor> {
    //MARK: Views
    private let displayView: UIImageView = UIImageView()
    private let confirmButton: UIButton = UIButton.createCircleButton(radius: 36)
    private let displayIndicatorView: UIActivityIndicatorView = UIActivityIndicatorView(style: .medium)
    private let archiveButton: UIBarButtonItem = UIBarButtonItem()
    private let titleView: UILabel = UILabel()
    private let displayEditButton: UIButton = UIButton.createCircleButton(radius: 21.5)
    private let displayEditCollectionView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let displayEditDataSources: RxCollectionViewSectionedReloadDataSource<DisplayEditSectionModel> = .init { dataSources, collectionView, indexPath, sectionItem in
        switch sectionItem {
        case let .fetchDisplayItem(cellReactor):
            guard let displayEditCell = collectionView.dequeueReusableCell(withReuseIdentifier: "DisplayEditCollectionViewCell", for: indexPath) as? DisplayEditCollectionViewCell else { return UICollectionViewCell() }
            displayEditCell.reactor = cellReactor
            return displayEditCell
        }
    }
    
    //MARK: LifeCylce
    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //MARK: Configure
    public override func setupUI() {
        super.setupUI()
        view.addSubviews(displayView, confirmButton, displayIndicatorView)
        displayView.addSubviews(displayEditButton, displayEditCollectionView)
    }
    
    public override func setupAttributes() {
        super.setupAttributes()
        
        titleView.do {
            $0.textColor = .white
            $0.text = "사진 올리기"
        }
        
        navigationItem.do {
            $0.titleView = titleView
            $0.rightBarButtonItem = archiveButton
        }
        
        archiveButton.do {
            $0.image = DesignSystemAsset.archive.image
        }
        
        displayView.do {
            $0.layer.cornerRadius = 40
            $0.clipsToBounds = true
        }
        
        displayEditButton.do {
            $0.setTitle("T", for: .normal)
            $0.setTitleColor(.white, for: .normal)
            $0.backgroundColor = .black.withAlphaComponent(0.3)
        }
        
        confirmButton.do {
            $0.backgroundColor = .white
            $0.setImage(DesignSystemAsset.confirm.image, for: .normal)
            
        }
        
        displayEditCollectionView.do {
            $0.register(DisplayEditCollectionViewCell.self, forCellWithReuseIdentifier: "DisplayEditCollectionViewCell")
            $0.showsVerticalScrollIndicator = false
            $0.showsHorizontalScrollIndicator = false
            $0.backgroundColor = .clear
            $0.isScrollEnabled = false
        }
        
        displayIndicatorView.do {
            $0.hidesWhenStopped = true
            $0.color = .gray
        }
    }
    
    public override func setupAutoLayout() {
        super.setupAutoLayout()
        
        displayView.snp.makeConstraints {
            $0.width.equalToSuperview()
            $0.height.equalTo(375)
            $0.center.equalToSuperview()
        }
        
        confirmButton.snp.makeConstraints {
            $0.top.equalTo(displayView.snp.bottom).offset(36)
            $0.centerX.equalTo(displayView)
        }
        
        displayIndicatorView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        displayEditButton.snp.makeConstraints {
            $0.bottom.equalToSuperview().offset(-15)
            $0.centerX.equalToSuperview()
        }
        
        displayEditCollectionView.snp.makeConstraints {
            $0.height.equalTo(61)
            $0.width.equalTo(view.frame.size.width - 43)
            $0.center.equalToSuperview()
        }
        
    }
    
    
    public override func bind(reactor: CameraDisplayViewReactor) {
        archiveButton
            .rx.tap
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .map { Reactor.Action.didTapArchiveButton }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        Observable
            .just(())
            .map { Reactor.Action.viewDidLoad }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$displayData)
            .map { UIImage(data: $0) }
            .asDriver(onErrorJustReturn: .none)
            .drive(displayView.rx.image)
            .disposed(by: disposeBag)
        
        
        reactor.state
            .map { $0.isLoading }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(displayIndicatorView.rx.isAnimating)
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$displayData)
            .skip(until: rx.methodInvoked(#selector(viewWillAppear(_:))))
            .withUnretained(self)
            .bind(onNext: { $0.0.setupCameraDisplayPermission(owner: $0.0, $0.1) })
            .disposed(by: disposeBag)
        
        displayEditCollectionView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$displaySection)
            .asDriver(onErrorJustReturn: [])
            .drive(displayEditCollectionView.rx.items(dataSource: displayEditDataSources))
            .disposed(by: disposeBag)
    }
}


extension CameraDisplayViewController {
    private func setupCameraDisplayPermission(owner: CameraDisplayViewController, _ originalData: Data) {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .authorized || status == .limited {
            PHPhotoLibrary.shared().performChanges {
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: originalData, options: nil)
                owner.makeToastView(title: "이미지가 저장되었습니다.", textColor: .white, radius: 5)
            }
        } else {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { stauts in
                switch status {
                case .authorized, .limited:
                    print("앨범 및 사진에 대한 권한이 부여 되었습니다.")
                case .denied:
                    //TODO: 권한 Alert 팝업 추가 예정
                    print("앨범 및 사진에 대한 권한을 거부 당했습니다.")
                default:
                    print("다른 여부의 권한을 거부 당했습니다.")
                }
            }
        }
    }
    
}

extension CameraDisplayViewController: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 38, height: 61)
    }
}
