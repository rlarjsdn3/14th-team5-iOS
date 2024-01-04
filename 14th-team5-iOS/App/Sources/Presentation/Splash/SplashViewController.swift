//
//  SplashViewController.swift
//  App
//
//  Created by 김건우 on 1/4/24.
//

import UIKit
import Core
import DesignSystem

public final class SplashViewController: BaseViewController<SplashReactor> {
    // MARK: - Mertic
    private enum Metric {
        static let bibbiOffset: CGFloat = 80
        static let bibbiHeight: CGFloat = 70
        static let bibbiInset: CGFloat = 100
        static let titleOffset: CGFloat = 26
    }
    
    // MARK: - Views
    private let bibbiImageView = UIImageView()
    private let mainTitleLabel = UILabel()
    
    private let iconsImageView = UIImageView()
    
    // MARK: - LifeCycles
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    // MARK: - Helpers
    override public func setupUI() {
        super.setupUI()
        view.addSubviews(bibbiImageView, mainTitleLabel, iconsImageView)
    }
    
    override public func setupAttributes() {
        super.setupAttributes()
        
        bibbiImageView.do {
            $0.image = DesignSystemAsset.newBibbi.image
            $0.contentMode = .scaleAspectFit
        }
        
        mainTitleLabel.do {
            $0.text = AccountSignInStrings.mainTitle
            $0.textColor = .gray100
            $0.font = UIFont.pretendard(.head2Bold)
        }
        
        iconsImageView.do {
            $0.image = DesignSystemAsset.splashIcons.image
            $0.contentMode = .scaleAspectFit
        }
    }
    
    override public func setupAutoLayout() {
        super.setupAutoLayout()
        
        bibbiImageView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(Metric.bibbiOffset)
            $0.height.equalTo(Metric.bibbiHeight)
            $0.horizontalEdges.equalToSuperview()
        }
        
        mainTitleLabel.snp.makeConstraints {
            $0.top.equalTo(bibbiImageView.snp.bottom).offset(Metric.titleOffset)
            $0.centerX.equalToSuperview()
        }
        
        iconsImageView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-60)
            $0.height.equalTo(iconsImageView.snp.width).multipliedBy(0.8)
        }
    }
    
    override public func bind(reactor: SplashReactor) { }
}
