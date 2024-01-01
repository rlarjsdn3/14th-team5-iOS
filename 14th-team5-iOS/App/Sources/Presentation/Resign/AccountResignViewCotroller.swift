//
//  AccountResignViewCotroller.swift
//  App
//
//  Created by Kim dohyun on 1/1/24.
//

import UIKit

import Core
import DesignSystem
import RxCocoa
import ReactorKit
import SnapKit
import Then


final class AccountResignViewCotroller: BaseViewController<AccountResignViewReactor> {
    
    //TODO: 텍스트 컬러, 폰트 정해지면 수정
    private let resignNavigationBarView: BibbiNavigationBarView = BibbiNavigationBarView()
    private let resignDesrptionLabel: BibbiLabel = BibbiLabel(.caption, textColor: .gray200)
    private let resignReasonLabel: BibbiLabel = BibbiLabel(.body1Bold, textColor: .white)
    private let resignExampleLabel: BibbiLabel = BibbiLabel(.caption, textColor: .gray200)
    private let resignIndicatorView: UIActivityIndicatorView = UIActivityIndicatorView(style: .medium)
    private let confirmButton: UIButton = UIButton()
    private let bibbiTermsView: BibbiCheckBoxView = BibbiCheckBoxView(frame: .zero)
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func setupUI() {
        super.setupUI()
        view.addSubviews(resignNavigationBarView, resignDesrptionLabel, resignReasonLabel, resignExampleLabel, confirmButton, resignIndicatorView, bibbiTermsView)
    }
    
    override func setupAttributes() {
        super.setupAttributes()
        resignNavigationBarView.do {
            $0.leftBarButtonItem = .arrowLeft
            $0.leftBarButtonItemTintColor = .gray300
            $0.navigationTitle = "회원 탈퇴"
        }
        
        resignDesrptionLabel.do {
            $0.textAlignment = .left
            $0.numberOfLines = 1
            $0.text = "삐삐 서비스와 헤어지게 되어 아쉬워요.."
        }
        
        resignReasonLabel.do {
            $0.textAlignment = .left
            $0.numberOfLines = 0
            $0.text = "탈퇴 사유를 알려주세요.\n삐삐 서비스를 개선하는데 많은 도움이 됩니다.\n더 나은 서비스가 될 수 있도록 노력할게요!"
        }
        
        resignExampleLabel.do {
            $0.textAlignment = .left
            $0.numberOfLines = 1
            $0.text = "최소 1개 이상 선택해 주세요."
        }
        
        resignIndicatorView.do {
            $0.hidesWhenStopped = true
            $0.color = .gray
        }
        
        confirmButton.do {
            $0.layer.cornerRadius = 8
            $0.clipsToBounds = true
            $0.setTitle("탈퇴 하기", for: .normal)
            $0.titleLabel?.font = DesignSystemFontFamily.Pretendard.semiBold.font(size: 16)
            $0.setTitleColor(DesignSystemAsset.black.color, for: .normal)
            $0.backgroundColor = DesignSystemAsset.gray600.color
            $0.isEnabled = false
        }
    }
    
    override func setupAutoLayout() {
        super.setupAutoLayout()
        resignNavigationBarView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.left.right.equalToSuperview()
            $0.height.equalTo(42)
        }
        
        bibbiTermsView.snp.makeConstraints {
            $0.top.equalTo(resignExampleLabel.snp.bottom).offset(15)
            $0.left.equalToSuperview()
            $0.height.equalTo(152)
            $0.centerX.equalTo(resignNavigationBarView)
        }
        
        resignDesrptionLabel.snp.makeConstraints {
            $0.top.equalTo(resignNavigationBarView.snp.bottom).offset(26)
            $0.left.equalToSuperview().offset(16)
            $0.centerX.equalTo(resignNavigationBarView)
            $0.height.equalTo(18)
        }
        
        resignReasonLabel.snp.makeConstraints {
            $0.top.equalTo(resignDesrptionLabel.snp.bottom).offset(24)
            $0.left.equalToSuperview().offset(12)
            $0.height.equalTo(72)
            $0.centerX.equalTo(resignNavigationBarView)
        }
        
        resignExampleLabel.snp.makeConstraints {
            $0.top.equalTo(resignReasonLabel.snp.bottom).offset(24)
            $0.left.equalToSuperview().offset(12)
            $0.height.equalTo(18)
            $0.centerX.equalTo(resignNavigationBarView)
        }
        
        confirmButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.height.equalTo(56)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
        }
        
    }
    
    override func bind(reactor: AccountResignViewReactor) {

        
        // resignViewController -> checkBoxView.checkBoxButtons = isSelected true
        // scan 해서 true false 체크
        Observable.merge(bibbiTermsView.checkButtons.map { button in
            button.rx.tap.map { _ in button.isSelected }
        })
        .scan(false) { [weak self] _, isSelected in
            guard let self = self else { return false }
            return isSelected || self.bibbiTermsView.checkButtons.contains { $0.isSelected }
        }
        .distinctUntilChanged()
        .map { Reactor.Action.didTapCheckButton($0)}
        .bind(to: reactor.action)
        .disposed(by: disposeBag)

        
        confirmButton
            .rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .withUnretained(self)
            .bind(onNext: {$0.0.showResignAlertController()})
            .disposed(by: disposeBag)
        
        reactor.state
            .map { $0.isSeleced }
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind(onNext: { $0.0.setupButton(isSelected: $0.1)})
            .disposed(by: disposeBag)
        
    }
    
}


extension AccountResignViewCotroller {
    
    private func setupButton(isSelected: Bool) {
        confirmButton.backgroundColor = isSelected ? DesignSystemAsset.gray100.color : DesignSystemAsset.gray600.color
        confirmButton.isEnabled = isSelected
    }
    
    private func showResignAlertController() {
        let resignAlertController = UIAlertController(
            title: "회원 탈퇴",
            message: "회원을 탈퇴해도 나의 활동 내역은 \n유지됩니다. 정말 탈퇴하시겠습니까?",
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel) { _ in
            resignAlertController.dismiss(animated: true)
        }
        
        let confirmAction = UIAlertAction(title: "확인", style: .default) { _ in
            print("확인 Check")
        }
        
        [cancelAction, confirmAction].forEach(resignAlertController.addAction(_:))
        
        present(resignAlertController, animated: true)
    }
    
}
