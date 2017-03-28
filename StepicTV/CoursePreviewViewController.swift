//
//  CoursePreviewViewController.swift
//  Stepic
//
//  Created by Anton Kondrashov on 14/03/2017.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import UIKit
import MediaPlayer

class CoursePreviewViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    fileprivate var textData : [(String, String)] = []
    
    var video: Video!
    
    var sectionTitles = [String]()
    var isErrorWhileLoadingSections : Bool = false
    var isLoadingSections: Bool = false
    
    var course : Course? = nil{
        didSet{
            if let c = course {
                
                if c.summary != "" {
                    textData += [(NSLocalizedString("Summary", comment: ""), c.summary)]
                }
                if c.courseDescription != "" {
                    textData += [(NSLocalizedString("Description", comment: ""), c.courseDescription)]
                }
                if c.workload != "" {
                    textData += [(NSLocalizedString("Workload", comment: ""), c.workload)]
                }
                if c.certificate != "" {
                    textData += [(NSLocalizedString("Certificate", comment: ""), c.certificate)]
                }
                if c.audience != "" {
                    textData += [(NSLocalizedString("Audience", comment: ""), c.audience)]
                }
                if c.format != "" {
                    textData += [(NSLocalizedString("Format", comment: ""), c.format)]
                }
                if c.requirements != "" {
                    textData += [(NSLocalizedString("Requirements", comment: ""), c.requirements)]
                }
            }
            
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.reloadData()
        tableView.register(UINib(nibName: "TitleTextTableViewCell", bundle: nil), forCellReuseIdentifier: "TitleTextTableViewCell")
        tableView.register(UINib(nibName: "TeachersTableViewCell", bundle: nil), forCellReuseIdentifier: "TeachersTableViewCell")
        tableView.estimatedRowHeight = 300
    }
    
    
    fileprivate func setupPlayerWithVideo(_ video: Video) {
        //
        //        self.video = video
        //
        //        if video.urls.count == 0 {
        //            videoWebView.isHidden = true
        //            playButton.isHidden = true
        //            thumbnailImageView.isHidden = false
        //            return
        //        }
        //
        //        self.moviePlayer = MPMoviePlayerController(contentURL: videoURL)
        //        if let player = self.moviePlayer {
        //            player.scalingMode = MPMovieScalingMode.aspectFit
        //            player.isFullscreen = false
        //            player.movieSourceType = MPMovieSourceType.file
        //            player.repeatMode = MPMovieRepeatMode.none
        //            self.contentView.addSubview(player.view)
        //            NotificationCenter.default.addObserver(self, selector: #selector(CoursePreviewViewController.willExitFullscreen), name: NSNotification.Name.MPMoviePlayerWillExitFullscreen, object: nil)
        //            NotificationCenter.default.addObserver(self, selector: #selector(CoursePreviewViewController.didExitFullscreen), name: NSNotification.Name.MPMoviePlayerDidExitFullscreen, object: nil)
        //
        //            self.moviePlayer?.view.alignLeading("0", trailing: "0", to: self.contentView)
        //            self.moviePlayer?.view.alignTop("0", bottom: "0", to: self.contentView)
        //            self.moviePlayer?.view.isHidden = true
        //        }
    }
    
    //MARK: - Enrollment
    //        if !StepicApplicationsInfo.doesAllowCourseUnenrollment {
//            return
//        }
//        
//        if !AuthInfo.shared.isAuthorized {
//            if let vc = ControllerHelper.getAuthController() as? AuthNavigationViewController {
//                vc.success = {
//                    [weak self] in
//                    if let s = self {
//                        s.joinButtonPressed(sender)
//                    }
//                }
//                self.present(vc, animated: true, completion: nil)
//            }
//            return
//        }
//        
//        //TODO : Add statuses
//        if let c = course {
//            
//            if sender.isEnabledToJoin {
//                
//                sender.isEnabled = false
//                AuthManager.sharedManager.joinCourseWithId(c.id, success : {
//                    
//                    sender.isEnabled = true
//                    sender.setDisabledJoined()
//                    self.course?.enrolled = true
//                    CoreDataHelper.instance.save()
//                    CoursesJoinManager.sharedManager.addedCourses += [c]
//                    
//                    self.performSegue(withIdentifier: "showSections", sender: nil)
//                }, error:  {
//                    status in
//                    
//                    sender.isEnabled = true
//                })
//            } else {
//                askForUnenroll(unenroll: {
//                    
//                    sender.isEnabled = false
//                    AuthManager.sharedManager.joinCourseWithId(c.id, delete: true, success : {
//                        
//                        sender.isEnabled = true
//                        sender.setEnabledJoined()
//                        self.course?.enrolled = false
//                        CoreDataHelper.instance.save()
//                        CoursesJoinManager.sharedManager.deletedCourses += [c]
//                        if #available(iOS 9.0, *) {
//                            WatchDataHelper.parseAndAddPlainCourses(WatchCoursesDisplayingHelper.getCurrentlyDisplayingCourses())
//                        }
//                        self.navigationController?.popToRootViewController(animated: true)
//                    }, error:  {
//                        status in
//                    
//                        sender.isEnabled = true
//                    })
//                })
//            }
//        }
//    }
}

extension CoursePreviewViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return textData.count + 2
    }
    
    func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row != 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CoursePreviewTableViewCell", for: indexPath) as! CoursePreviewTableViewCell
            cell.initWith(course: course!)
            cell.delegate = self
            return cell
        }
        
        if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TeachersTableViewCell", for: indexPath) as! TeachersTableViewCell
            cell.initWithCourse(course!)
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TitleTextTableViewCell", for: indexPath) as! TitleTextTableViewCell
        cell.initWith(title: textData[indexPath.row - 2].0, text: textData[indexPath.row - 2].1)
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section{
        case 0: return "Detailed"
        case 1: return "Detailed"
        case 2: return "Modules"
        default: return nil
        }
    }
}

extension CoursePreviewViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 20
    }
}

extension CoursePreviewViewController : CoursePreviewTableViewCellDelegate{
    func joinButtonTap(in cell: CoursePreviewTableViewCell){
        
    }
    
    func playButtonTap(in cell: CoursePreviewTableViewCell){
        
    }
}
