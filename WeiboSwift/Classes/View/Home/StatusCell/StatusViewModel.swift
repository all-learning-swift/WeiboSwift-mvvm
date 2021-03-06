//
//  StatusViewModel.swift
//  WeiboSwift
//
//  Created by zhoujianfeng on 2017/1/21.
//  Copyright © 2017年 周剑峰. All rights reserved.
//

import Foundation

class StatusViewModel: CustomStringConvertible {
    
    /// 微博模型
    var status: Status
    
    /// 会员等级图标 - 内存换cpu
    var memberIcon: UIImage?
    
    /// 认证图标
    var vipIcon: UIImage?
    
    /// 转发文字
    var retweetString: String?
    
    /// 评论文字
    var commentString: String?
    
    /// 点赞文字
    var likeString: String?
    
    /// 配图区域尺寸
    var pictureViewSize = CGSize()
    
    /// 微博配图，如果被转发的微博没图，就返回原创的，原创没有就返回nil。因为被转发微博如果有图，那原创微博一定没图
    var picUrls: [StatusPicture]? {
        return status.retweeted_status?.pic_urls ?? status.pic_urls
    }
    
    /// 被转发微博文字
    var retweetedText: String?
    
    /// 行高
    var rowHeight: CGFloat = 0
    
    init(model: Status) {
        self.status = model
        
        guard let user = model.user else {
            return
        }
        
        // 会员等级图标 会员等级  0-6
        if user.mbrank > 0 && user.mbrank < 7 {
            let imageName = "common_icon_membership_level\(user.mbrank)"
            memberIcon = UIImage(named: imageName)
        } else {
            let imageName = "common_icon_membership_expired"
            memberIcon = UIImage(named: imageName)
        }
        
        // -1没有认证 0认证用户 2，3，5企业认证 220达人
        switch user.verified_type {
        case 0:
            vipIcon = UIImage(named: "avatar_vip")
        case 2, 3, 5:
            vipIcon = UIImage(named: "avatar_enterprise_vip")
        case 220:
            vipIcon = UIImage(named: "avatar_grassroot")
        default:
            break
        }
        
        // 转换字符串
        retweetString = countToString(count: model.reposts_count, defaultString: "转发")
        commentString = countToString(count: model.comments_count, defaultString: "评论")
        likeString = countToString(count: model.attitudes_count, defaultString: "赞")
        
        // 被转发微博文字
        if let retweeted_status = status.retweeted_status,
            let user = status.retweeted_status?.user {
            retweetedText = "@" + (user.screen_name ?? "") + ":" + (retweeted_status.text ?? "")
        }
        
        // 计算配图区域尺寸
        pictureViewSize = calcPictureViewSize(count: picUrls?.count ?? 0)
        
        // 计算cell行高
        updateRowHeight()
    }
    
    /// 计算行高
    func updateRowHeight() {
        // 原创微博：顶部分割视图(12) + 间距(12) + 头像(34) + 间距(12) + 正文(计算) + 配图(计算) + 间距(12) + 底部条(35)
        // 转发微博：顶部分割视图(12) + 间距(12) + 头像(34) + 间距(12) + 正文(计算) + 间距(12) + 间距(12) + 转发文本(计算) + 配图(计算) + 间距(12) + 底部条(35)
        
        let margin: CGFloat = 12
        let avatarHeight: CGFloat = 34
        let toolBarHeight: CGFloat = 35
        
        // 正文尺寸
        let textSize = CGSize(width: UIScreen.cz_screenWidth() - 2 * margin, height: CGFloat(MAXFLOAT))
        let originalFont = UIFont.systemFont(ofSize: 15)
        let retweetedFont = UIFont.systemFont(ofSize: 14)
        
        var height: CGFloat = 0
        
        // 顶部高度 顶部灰色条8
        height = margin * 2 + avatarHeight + 8
        
        // 正文
        if let text = status.text {
            height += (text as NSString).boundingRect(with: textSize,
                                                      options: .usesLineFragmentOrigin,
                                                      attributes: [NSFontAttributeName : originalFont],
                                                      context: nil).height
        }
        
        // 是否是被转发微博
        if let text = retweetedText {
            
            height += margin * 2
            
            // 被转发微博正文
            height += (text as NSString).boundingRect(with: textSize,
                                                      options: .usesLineFragmentOrigin,
                                                      attributes: [NSFontAttributeName : retweetedFont],
                                                      context: nil).height
        }
        
        // 微博配图
        height += pictureViewSize.height
        
        // 底部条
        height = height + margin + toolBarHeight
    
        // cell高度
        rowHeight = height
    }
    
    /// 计算配图区域尺寸
    ///
    /// - Parameter count: 配图数量
    /// - Returns: 尺寸
    private func calcPictureViewSize(count: Int) -> CGSize {
        
        // 没有配图
        if count == 0 {
            return CGSize()
        }
        
        /**
         行数
         1 2 3 = 0 1 2 / 3 = 0 + 1 = 1
         4 5 6 = 3 4 5 / 3 = 1 + 1 = 2
         7 8 9 = 6 7 8 / 3 = 2 + 1 = 3
         */
        let row = (count - 1) / 3 + 1
        
        /// 配图区域高度
        let height: CGFloat = STATUS_PICTURE_VIEW_OUTER_MARGIN + CGFloat(row) * STATUS_PICTURE_ITEM_WIDTH + STATUS_PICTURE_VIEW_INNER_MARGIN * CGFloat(row - 1)
        
        return CGSize(width: STATUS_PICTURE_VIEW_WIDHT, height: height)
    }
    
    /// 微博只有一张配图时更新图片区域尺寸
    ///
    /// - Parameter image: 图片
    func updateSingleImageSize(image: UIImage) {
        var size = image.size
        // 限制最大最小尺寸
        let maxWidth: CGFloat = 300
        let minWidth: CGFloat = 40
        
        if size.width > maxWidth {
            size.width = maxWidth
            size.height = size.height * size.width / maxWidth
        } else if size.width < minWidth {
            size.width = minWidth
            size.height = size.height * size.width / minWidth
            // 图片过长也需要处理
            if size.height > 250 {
                size.height = size.height / 4
            }
        }
        
        size.height += STATUS_PICTURE_VIEW_OUTER_MARGIN
        pictureViewSize = size
        
        // 计算cell行高
        updateRowHeight()
    }
    
    /// 数量转字符串 0显示默认字符串 小于10000显示具体数字 大于10000显示x.xx万
    ///
    /// - Parameters:
    ///   - count: 数量
    ///   - defaultString: 默认字符串
    /// - Returns: 转换后的字符串
    private func countToString(count: Int, defaultString: String) -> String {
        if count == 0 {
            return defaultString
        } else if count < 10000 {
            return count.description
        }
        return String(format: "%.02f 万", CGFloat(count) / 10000)
    }
    
    var description: String {
        return status.description
    }
    
}
