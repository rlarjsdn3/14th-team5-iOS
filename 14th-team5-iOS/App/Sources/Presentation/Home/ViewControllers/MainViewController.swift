//
//  HomeViewController.swift
//  App
//
//  Created by 마경미 on 05.12.23.
//

import UIKit

import Core
import Domain
import DesignSystem

import RxDataSources
import RxCocoa
import RxSwift

final class MainViewController: BaseViewController<MainViewReactor>, UICollectionViewDelegateFlowLayout {
    private let familyViewController: MainFamilyViewController = MainFamilyViewControllerWrapper().makeViewController()
    
    private let timerView: TimerView = TimerView(reactor: TimerReactor())
    private let descriptionLabel: BBLabel = BBLabel(.body2Regular, textAlignment: .center, textColor: .gray300)
    private let imageView: UIImageView = UIImageView()
    
    private let contributorView: ContributorView = ContributorView(reactor: ContributorReactor())
    private let segmentControl: BibbiSegmentedControl = BibbiSegmentedControl()
    private let pageViewController: SegmentPageViewController = SegmentPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    
    private let cameraButton: MainCameraButtonView = MainCameraButtonView(reactor: MainCameraReactor())
    private let alertConfirmRelay: PublishRelay<(String, String)> = PublishRelay<(String, String)>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.inviteCode = nil
    }
    
    override func bind(reactor: MainViewReactor) {
        print("bind main reactor")
        super.bind(reactor: reactor)
        bindInput(reactor: reactor)
        bindOutput(reactor: reactor)
    }
    
    override func setupUI() {
        super.setupUI()
        
        addChild(familyViewController)
        addChild(pageViewController)
        
        view.addSubviews(familyViewController.view, timerView, descriptionLabel,
                         imageView, segmentControl, pageViewController.view,
                         cameraButton, contributorView)
        
        familyViewController.didMove(toParent: self)
        pageViewController.didMove(toParent: self)
    }
    
    override func setupAutoLayout() {
        super.setupAutoLayout()
        
        familyViewController.view.snp.makeConstraints {
            $0.top.equalTo(navigationBarView.snp.bottom)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(138)
        }
        
        timerView.snp.makeConstraints {
            $0.top.equalTo(familyViewController.view.snp.bottom)
            $0.height.equalTo(48)
            $0.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
        }
        
        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(timerView.snp.bottom).offset(8)
            $0.height.equalTo(20)
            $0.centerX.equalToSuperview()
        }
        
        imageView.snp.makeConstraints {
            $0.top.equalTo(descriptionLabel)
            $0.size.equalTo(20)
            $0.leading.equalTo(descriptionLabel.snp.trailing).offset(2)
        }
        
        contributorView.snp.makeConstraints {
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(20)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        
        segmentControl.snp.makeConstraints {
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(138)
            $0.height.equalTo(40)
        }
        
        pageViewController.view.snp.makeConstraints {
            $0.top.equalTo(segmentControl.snp.bottom).offset(40)
            $0.horizontalEdges.bottom.equalToSuperview()
        }
        
        cameraButton.snp.makeConstraints {
            $0.bottom.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(140)
        }
    }
    
    override func setupAttributes() {
        super.setupAttributes()
        
        navigationBarView.do {
            $0.setNavigationView(leftItem: .family, centerItem: .logo, rightItem: .calendar)
        }
        
        contributorView.do {
            $0.isHidden = true
        }
    }
}

extension MainViewController {
    private func bindInput(reactor: MainViewReactor) {
        Observable.merge(
            Observable.just(())
                .map { _ in Reactor.Action.calculateTime },
            NotificationCenter.default.rx.notification(UIScene.willEnterForegroundNotification)
                .map { _ in Reactor.Action.calculateTime }
        )
        .bind(to: reactor.action)
        .disposed(by: disposeBag)
        
        Observable.merge(
            segmentControl.survivalButton.rx.tap.map { Reactor.Action.didTapSegmentControl(.survival) },
            segmentControl.missionButton.rx.tap.map { Reactor.Action.didTapSegmentControl(.mission) },
            pageViewController.indexRelay.filter { $0.way == .scroll }.map { $0.index }.map { Reactor.Action.didTapSegmentControl($0 == 0 ? .survival : .mission)}
        )
        .observe(on: MainScheduler.instance)
        .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
        .bind(to: reactor.action)
        .disposed(by: disposeBag)
        
        Observable.merge(
            contributorView.nextButtonTapEvent.map { Reactor.Action.openNextViewController(.contributorNextButtonTap)},
            cameraButton.camerTapEvent.map { Reactor.Action.openNextViewController(.cameraButtonTap )},
            navigationBarView.rx.rightButtonTap.map { Reactor.Action.openNextViewController(.navigationRightButtonTap)},
            navigationBarView.rx.leftButtonTap.map { _ in Reactor.Action.openNextViewController(.navigationLeftButtonTap)}
        )
        .observe(on: MainScheduler.instance)
        .throttle(RxConst.milliseconds300Interval, scheduler: MainScheduler.instance)
        .bind(to: reactor.action)
        .disposed(by: disposeBag)
        
        alertConfirmRelay.map { Reactor.Action.pickConfirmButtonTapped($0.0, $0.1) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        contributorView.infoButton.rx.tap
            .throttle(RxConst.milliseconds300Interval, scheduler: MainScheduler.instance)
            .withUnretained(self)
            .bind(onNext: {
                $0.0.makeDescriptionPopoverView(
                    $0.0,
                    sourceView: $0.0.contributorView.infoButton,
                    text: "생존신고 횟수가 동일한 경우\n이모지, 댓글 수를 합산해서 등수를 정해요",
                    popoverSize: CGSize(width: 260, height: 62),
                    permittedArrowDrections: [.up]
                )
            })
            .disposed(by: disposeBag)
    }
    
    private func bindOutput(reactor: MainViewReactor) {
        reactor.state.map { $0.isInTime }.compactMap { $0 }
            .distinctUntilChanged()
            .withUnretained(self)
            .observe(on: MainScheduler.instance)
            .bind(onNext: { $0.0.setInTimeView($0.1) })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$familySection)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(to: familyViewController.familySectionRelay)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.pageIndex }
            .distinctUntilChanged()
            .withUnretained(self)
            .observe(on: MainScheduler.instance)
            .bind(onNext: {
                $0.0.pageViewController.indexRelay.accept(.init(way: .segmentTap, index: $0.1))
                $0.0.segmentControl.isSelected = ($0.1 == 0)
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$cameraEnabled)
            .distinctUntilChanged()
            .bind(to: cameraButton.cameraEnabledRelay)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.balloonText }
            .distinctUntilChanged { $0.message }
            .bind(to: cameraButton.textRelay)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.description }
            .distinctUntilChanged { $0.text }
            .withUnretained(self)
            .observe(on: MainScheduler.instance)
            .bind(onNext: { $0.0.setDescription($0.1) })
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.isMissionUnlocked }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(to: segmentControl.isUpdatedRelay)
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$contributor)
            .bind(to: contributorView.contributorRelay)
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$openNextView).compactMap { $0 }
            .withUnretained(self)
            .observe(on: MainScheduler.instance)
            .bind(onNext: { $0.0.pushViewController(type: $0.1) })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$shouldPresentPickSuccessToastMessage)
            .compactMap { $0 }
            .bind(with: self) { owner, name in
                owner.makeBibbiToastView(
                    text: "\(name)님에게 생존신고 알림을 보냈어요",
                    image: DesignSystemAsset.yellowPaperPlane.image
                )
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$shouldPresentCopySuccessToastMessage)
            .filter { $0 }
            .bind(with: self) { owner, _ in
                owner.makeBibbiToastView(
                    text: "링크가 복사되었어요",
                    image: DesignSystemAsset.link.image
                )
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$shouldPresentFailureToastMessage)
            .filter { $0 }
            .bind(with: self) { owner, _ in
                owner.makeErrorBibbiToastView()
            }
            .disposed(by: disposeBag)
    }
}

extension MainViewController {
    private func setInTimeView(_ isInTime: Bool) {
        if isInTime {
            contributorView.isHidden = true
            pageViewController.view.isHidden = false
            segmentControl.isHidden = false
        } else {
            contributorView.isHidden = false
            pageViewController.view.isHidden = true
            segmentControl.isHidden = true
        }
    }
    
    private func setDescription(_ description: Description) {
        if case let .missionNone(number) = description {
            let attributedString = NSMutableAttributedString(string: description.text)
            let range = (description.text as NSString).range(of: "\(number)명")
            attributedString.addAttribute(.foregroundColor, value: UIColor.mainYellow, range: range)
            descriptionLabel.attributedText = attributedString
        } else {
            descriptionLabel.text = description.text
        }
        imageView.image = description.image
    }
    
    private func pushViewController(type: MainViewReactor.OpenType) {
        switch type {
        case .monthlyCalendarViewController:
            navigationController?.pushViewController(MonthlyCalendarDIConatainer().makeViewController(), animated: true)
        case .familyManagementViewController:
            navigationController?.pushViewController(FamilyManagementDIContainer().makeViewController(), animated: true)
        case .weeklycalendarViewController(let date):
            navigationController?.pushViewController(WeeklyCalendarDIConatainer(date: date.toDate()).makeViewController(), animated: true)
        case .cameraViewController(let type):
            MPEvent.Home.cameraTapped.track(with: nil)
                navigationController?.pushViewController(CameraViewControllerWrapper(cameraType: type).viewController, animated: true)
        case .survivalAlert:
            BibbiAlertBuilder(self)
                .alertStyle(.takeSurvival)
                .setConfirmAction { [weak self] in
                    guard let self else { return }
                    self.navigationController?.pushViewController(CameraViewControllerWrapper(cameraType: .survival).viewController, animated: true)
                }
                .present()
        case .pickAlert(let name, let id):
            BibbiAlertBuilder(self)
                .alertStyle(.pickMember(name))
                .setConfirmAction {  [weak self] in 
                    guard let self else { return }
                    self.alertConfirmRelay.accept((name, id)) }
                .present()
        case .missionUnlockedAlert:
            BibbiAlertBuilder(self)
                .alertStyle(.missionKey)
                .setConfirmAction { [weak self] in
                    guard let self else { return }
                    self.navigationController?.pushViewController(CameraViewControllerWrapper(cameraType: .mission).viewController, animated: true)
                }
                .present()
        }

    }
}

extension MainViewController: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
