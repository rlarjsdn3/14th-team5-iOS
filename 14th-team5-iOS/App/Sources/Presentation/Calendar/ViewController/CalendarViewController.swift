//
//  CalendarViewController.swift
//  App
//
//  Created by 김건우 on 12/6/23.
//

import UIKit

import Core
import FSCalendar
import ReactorKit
import RxCocoa
import RxSwift
import RxDataSources
import SnapKit
import Then

// MARK: - Delegate
protocol CalendarViewDelegate: AnyObject {
    func goToCalendarFeedView(_ date: Date)
    func presentPopoverView(sourceView: UIView)
}

// MARK: - ViewController
final class CalendarViewController: BaseViewController<CalendarViewReactor> {
    // MARK: - Views
    private lazy var collectionView: UICollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: orthogonalCompositionalLayout
    )
    
    // MARK: - Lifecycles
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Helpers
    override func setupUI() { 
        super.setupUI()
        view.addSubview(collectionView)
    }
    
    override func setupAutoLayout() { 
        super.setupAutoLayout()
        collectionView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    override func setupAttributes() {
        collectionView.do {
            $0.dataSource = self
            
            $0.isScrollEnabled = false
            $0.backgroundColor = UIColor.black
            $0.register(CalendarPageCell.self, forCellWithReuseIdentifier: CalendarPageCell.id)
        }
    }
    
    override func bind(reactor: CalendarViewReactor) { }
}

extension CalendarViewController {
    var orthogonalCompositionalLayout: UICollectionViewCompositionalLayout {
        // item
        let itemSize: NSCollectionLayoutSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item: NSCollectionLayoutItem = NSCollectionLayoutItem(layoutSize: itemSize)
        
        // group
        let groupSize: NSCollectionLayoutSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let group: NSCollectionLayoutGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitem: item,
            count: 1
        )
        
        // section
        let section: NSCollectionLayoutSection = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging
        
        // layout
        let layout: UICollectionViewCompositionalLayout = UICollectionViewCompositionalLayout(section: section)
        
        return layout
    }
}

extension CalendarViewController: CalendarViewDelegate {
    func goToCalendarFeedView(_ date: Date) {
        let vc = CalendarFeedViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func presentPopoverView(sourceView: UIView) {
        let vc = CalendarDescriptionPopoverViewController()
        vc.preferredContentSize = CGSize(
            width: CalendarVC.Attribute.popoverWidth,
            height: CalendarVC.Attribute.popoverHeight
        )
        vc.modalPresentationStyle = .popover
        if let presentation = vc.presentationController {
            presentation.delegate = self
        }
        present(vc, animated: true)
        if let pop = vc.popoverPresentationController {
            pop.sourceView = sourceView
            pop.sourceRect = sourceView.bounds
        }
        
    }
}

// Temp Code
extension CalendarViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CalendarPageCell.id,
            for: indexPath
        ) as! CalendarPageCell
        cell.reactor = CalendarPageCellReactor()
        cell.delegate = self
        return cell
    }
}

extension CalendarViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
