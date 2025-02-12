//
//  NoteCell.swift
//  notepadApp
//
//  Created by TuanTa on 12/2/25.
//

import UIKit

class NoteCell: UICollectionViewCell {
    let titleLabel = UILabel()
    let contentLabel = UILabel()
    let dateLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 8
        layer.shadowOpacity = 0.1
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, contentLabel, dateLabel])
        stack.axis = .vertical
        stack.spacing = 4
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
        
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = .secondaryLabel
    }
}
