//
//  PemoMainViewController.swift
//  PEMO
//
//  Created by Jaeseong on 2017. 10. 23..
//  Copyright © 2017년 Jaeseong. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Toaster
import RealmSwift
import ObjectMapper
import AlamofireObjectMapper
import ObjectMapper_Realm
import KUIPopOver
import Kingfisher

enum MemoDataType {
    case list
    case search
}
enum DataType {
    case memo
    case folder
}
class PemoMainViewController: UIViewController, KUIPopOverUsable, PemoFolderCollectionViewControllerDelegate, UIGestureRecognizerDelegate {
    
    var tempFolder: [Folder] = []
    var folderId: Int = 0
    
    
    private var realm: Realm!
    private var memos: Results<MemoData>!
    private var folders: Results<Folder>!
    private var token: NotificationToken!
    //    lazy var memoDao = MemoDAO()
    var contentSize: CGSize {
        return CGSize(width: self.view.frame.width, height: 300)
    }
    
//    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?
    //    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    //    var memoDataList: [MemoData] = [] // 메모 리스트
    
    var transCollection: Bool = true
    var memoSearch: [MemoData] = [] // 메모검색결과 리스트
    let cellSpacingHeight: CGFloat = 10
    let searchBar = UISearchBar()
    var memoTypeSelect: MemoDataType = .list
    // MARK: - @IB
    //
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var topView: UIView!
    @IBOutlet var bottomView: UIView!
    @IBOutlet var newMemoButton: UIButton!
    @IBOutlet var folderButton: UIButton!
    @IBOutlet var searchButton: UIButton!
    @IBOutlet var folderCheckButton: UIButton!
    @IBOutlet var  trashButton: UIButton!
    
    
    
    @IBAction func folder(_ sender: UIButton) {
        // 검색버튼 클릭시 글쓰기 버튼 히든, 테이블뷰 탑으로 이동
        self.newMemoButton.isHidden = true
        self.tableView.contentOffset = CGPoint(x: 0, y: 0)
        
        // PopOver Controller 띄움
        guard let nextViewController = self.storyboard?.instantiateViewController(withIdentifier: "NAVIFOLDERs") as? PemoFolderCollectionViewController else { return }
        nextViewController.popOverType = PopOver.mainFolder
        nextViewController.delegate = self
        nextViewController.showPopover(withNavigationController: sender, sourceRect: sender.bounds)
        
        
    }
    @IBAction func newMemo(_ sender: UIButton) {
        
        guard let nextViewController = self.storyboard?.instantiateViewController(withIdentifier: "NEWMEMO") as? PemoNewMemoViewController else { return }
        nextViewController.writeType = .new
        //        self.navigationController?.pushViewController(nextViewController, animated: true)
        self.present(nextViewController, animated: true, completion: nil)
    }
    @IBAction func search(_ sender: UIButton) {
        self.searchBar.isHidden = false
        self.titleLabel.isHidden = true
        self.newMemoButton.isHidden = true
//        self.topView.addSubview(searchBar)
        //        self.navigationItem.titleView = searchBar
        searchBar.delegate = self
        searchBar.placeholder = "검색"
        searchBar.sizeToFit()
        searchBar.becomeFirstResponder()
        searchBar.showsCancelButton = true
        searchBar.tintColor = UIColor.piAquamarine
        //        searchBar.enablesReturnKeyAutomatically = false
        
    }
    
    
    // MARK: - LIFE CYCLE
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        self.topView.addSubview(searchBar)
        searchBar.isHidden = true
        self.folderCheckButton.isHidden = true
        self.trashButton.isHidden = true
        do {
            realm = try Realm()
        } catch {
            print("\(error)")
        }
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 65
        self.tableView.allowsMultipleSelectionDuringEditing = true
        self.tableView.allowsMultipleSelection = true
        
        
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        
        self.firstGetMemo(method: .get, type: .folder) // 폴더불러오는 알라모파이어
        
        self.folders = realm?.objects(Folder.self).sorted(byKeyPath: "id", ascending: false)
        
        self.firstGetMemo(method: .get, type: .memo) // 메모불러오는 알라모파이어
        
        self.memos = realm.objects(MemoData.self).sorted(byKeyPath: "id", ascending: false)
        self.token = memos.observe({ (change) in
            self.tableView.reloadData()
        })
        
        
        print("테이블뷰 뷰 디드 로드")
        if transCollection == true {
            //            folders = realm?.objects(Folder.self).sorted(byKeyPath: "id", ascending: false)
            //            // 제대로 만들어 졌다면 폴더만 가져와도 메모는 따라온다..?
            //            memos = realm.objects(MemoData.self).sorted(byKeyPath: "id", ascending: false)
            //            //            memos = selectedFolder.memos.sorted(byKeyPath: "id", ascending: false)
            //            token = memos.observe({ (change) in
            //                self.tableView.reloadData()
            //            })
        } else {
            //            memos = selectedFolder.memos.sorted(byKeyPath: "id", ascending: false)
            //            token = memos.observe({ (change) in
            //                self.tableView.reloadData()
            //            })
        }
        
        
        
        self.searchBar.enablesReturnKeyAutomatically = false
        
        self.tableView.reloadData()
        self.uiCustom()
        
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longpress))
        longPressRecognizer.minimumPressDuration = 0.5
        //        longpress.delaysTouchesBegan = true
        longPressRecognizer.delegate = self
//        longPressRecognizer.cancelsTouchesInView = true
        
        self.tableView.addGestureRecognizer(longPressRecognizer)
    }
    
    func alamo(with: PemoFolderCollectionViewController, indexPath: IndexPath) {
        print("PemoFolderCollectionViewControllerDelegate 호출됨")
        
        let count = realm.objects(Folder.self)[indexPath.row]
        let counts = count.memos.filter("TRUEPREDICATE")
        
        self.memos = counts
        self.titleLabel.text = self.folders[indexPath.row].title
        
        self.tableView.reloadData()
    }
    
    func dismiss(with: PemoFolderCollectionViewController) {
        // PopOver ViewController 사라지는경우 모든것 원위치 시킴
        print("dismiss delegate")
        self.newMemoButton.isHidden = false
        self.titleLabel.text = "All"
        self.memos = realm.objects(MemoData.self).sorted(byKeyPath: "id", ascending: false)
        self.token = memos.observe({ (change) in
            self.tableView.reloadData()
        })
        
        //        with.dismissPopover(animated: true)
    }
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(true, animated: true)
        self.tableView.setEditing(true, animated: true)
    }
//    override func setEditing(_ editing: Bool, animated: Bool) {
//        super.setEditing(editing, animated: animated)
////        tableView.setEditing(editing, animated: animated)
//    }
    @objc func longpress(gestureRecognizer: UILongPressGestureRecognizer) {
        
        let point = gestureRecognizer.location(in: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: point)
            
        
//        let cell = self.tableView?.cellForRow(at: indexPath!) as! PemoMainTableViewCell
        
        if gestureRecognizer.state == .began {
            print("롱프레스 시작1")
            self.folderButton.isHidden = true
            self.newMemoButton.isHidden = true
            self.searchButton.isHidden = true
            self.folderCheckButton.isHidden = false
            self.trashButton.isHidden = false
            self.setEditing(true, animated: true)
            print("롱프레스 시작2")
        }
//        } else if gestureRecognizer.state == .ended {
//
//
//            if let index = indexPath {
//
////                cell.iconImage.isHidden = true
////                cell.iconlabel.isHidden = true
////                cell.deleteFolder.isHidden = false
////                cell.editFolder.isHidden = false
////                print(index.row)
////                self.aa = false
//            } else {
//
//            }
//            print("롱프레스 끝")
//        }
        
    }
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        super.prepare(for: segue, sender: sender)
//        print("프리페어포세그")
//        self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: segue.destination)
//        
//        segue.destination.modalPresentationStyle = .custom
//        segue.destination.transitioningDelegate = self.halfModalTransitioningDelegate
//    }
    override func viewWillAppear(_ animated: Bool) {
        print("뷰윌어피어")
        
    }
    override func viewDidAppear(_ animated: Bool) {
        print("뷰디드어피어")
        
        
    }

}
// MARK:- SearchBar Delegate
//
extension PemoMainViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        memos = realm.objects(MemoData.self).filter("content contains[c] %@", searchText).sorted(byKeyPath: "id", ascending: false)
        self.tableView.reloadData()
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.navigationItem.titleView = nil
        self.searchBar.isHidden = true
        
        self.titleLabel.isHidden = false
        self.newMemoButton.isHidden = false
        self.tableView.reloadData()
        searchBar.endEditing(true)
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.navigationItem.titleView = nil
        self.searchBar.isHidden = true
        
        self.titleLabel.isHidden = false
        self.newMemoButton.isHidden = false
        self.tableView.reloadData()
        searchBar.endEditing(true)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.folderButton.isHidden = false
        self.newMemoButton.isHidden = false
        self.searchButton.isHidden = false
        self.folderCheckButton.isHidden = true
        self.trashButton.isHidden = true
        self.tableView.setEditing(false, animated: true)
        self.folderCheckButton.setImage(UIImage(named: "PEMO_FOLDER_SELECT.png"), for: .normal)
        self.trashButton.setImage(UIImage(named: "PEMO_Trash.png"), for: .normal)
    }
}
// MARK: - TableView
//


extension PemoMainViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.memos.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let row = self.memos[indexPath.row]
        let cellid = row.image == nil ? "memoCell" : "memoCellImg"
        //        let cellId = section.image == nil ? "memoCellWithImage" : "memoCell" // 서버에서 이미지구현시 앞뒤 바꿀것
        let cell = tableView.dequeueReusableCell(withIdentifier: cellid) as? PemoMainTableViewCell
        cell?.title.text = row.created_date
        cell?.contents.text = row.content
//        cell?.isEditing = true
        cell?.tintColor = UIColor.piAquamarine
        
        DispatchQueue.main.async {
            guard let path = row.image else { return }
//            if let imageURL = URL(string: path) {
            let imageURL = URL(string: path)
            cell?.img.kf.setImage(with: imageURL, placeholder: nil, options: [.transition(ImageTransition.fade(1))], progressBlock: { (receive, total) in
                print("\(indexPath.row + 1) : \(receive)/\(total)")
            }, completionHandler: { (image, error, cacheType, imageURL) in
                print("\(indexPath.row + 1) : Finished")
            })
            if cellid == "memoCellImg" {
                cell?.img.clipsToBounds = true
                cell?.img.layer.cornerRadius = 10
                cell?.img.layer.masksToBounds = true
                
            }
//                let task = URLSession.shared.dataTask(with: imageURL, completionHandler: { (data, response, error) in
//                    guard let putImage = data else { return }
//                    DispatchQueue.main.async {
//                        cell?.img.image = UIImage(data: putImage)
//                        if cellid == "memoCellImg" {
//                            cell?.img.clipsToBounds = true
//                            cell?.img.layer.cornerRadius = 10
//                            cell?.img.layer.masksToBounds = true
//
//                        }
//
//                    }
//                })
//                task.resume()
//            }
        }
        
        return cell!
    }
//    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
//        return .delete
//    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didselect")
        self.folderCheckButton.setImage(UIImage(named: "PEMO_folderCheck.png"), for: .normal)
        self.trashButton.setImage(UIImage(named: "PEMO_Trash_S.png"), for: .normal)
        if tableView.isEditing == true {
            print("\(indexPath.row)") // memo id 번호 가져옴
            // 알라모파이어로..카테고리넘버..바꿈
            // tableview.setEditing(false, animated: false)
//            ㅇㅓ펜드하고 밑에서 삭제editActionsForRowAt
            print("editing")
            } else {
            guard let nextViewController = self.storyboard?.instantiateViewController(withIdentifier: "NEWMEMO") as? PemoNewMemoViewController else { return }
            nextViewController.writeType = .edit
            nextViewController.memoTransfer = self.memos[indexPath.row]
            nextViewController.memoPkTransfer = self.memos[indexPath.row].id
            self.navigationController?.pushViewController(nextViewController, animated: true)
        }
        
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete", handler: { (deleteAction, indexPath) in
            let alert = UIAlertController(title: nil, message: "Delete Selected Memo", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let delete = UIAlertAction(title: "Delete", style: .default, handler: { (_) in
                do {
                    try self.realm.write {
                        
                        self.memoDelete(id: self.memos[indexPath.row].id)
                        //self.realm.delete(self.memos[indexPath.row]).image 먼저 삭제 해야함
                        self.realm.delete(self.memos[indexPath.row])
                        
                    }
                } catch {
                    print("\(error)")
                }
            })
            alert.addAction(cancel)
            alert.addAction(delete)
            self.present(alert, animated: true, completion: nil)
        })
        deleteAction.backgroundColor = UIColor.piAquamarine
        
        return [deleteAction]
    }
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

//// MARK: - Alamofire
extension PemoMainViewController {
    
    //    // 메모삭제
    func memoDelete(id: Int) {
        let url = mainDomain + "memo/\(id)/"
        let tokenValue = TokenAuth()
        guard let headers = tokenValue.getAuthHeaders() else { return }
        let call = Alamofire.request(url, method: .delete, parameters: nil, encoding: JSONEncoding.default, headers: headers)
        call.responseJSON { (response) in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                print(json)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            case .failure(let error):
                print(error)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
    }
    func firstGetMemo(method: HTTPMethod, type: DataType) {
        print("알라모")
        switch type {
        case .folder:
            let userDefault = UserDefaults.standard
            guard userDefault.value(forKey: "firstloginfolder") == nil else { return }
            
            let url = mainDomain + "category/"
            let tokenValue = TokenAuth()
            let headers = tokenValue.getAuthHeaders()
            let call = Alamofire.request(url, method: method, parameters: nil, headers: headers)
            call.responseJSON { (response) in
                switch response.result {
                case .success(let value):
                    let aa = JSON(value)
//                    print("메인뷰컨트롤러 처음 정보 불러옴 JSON",aa)
                    //                    print(" 초기 로딩 폴더정보 가져옴 ",folderResponse)
                    guard let folderResponse = Mapper<Folder>().mapArray(JSONObject: value) else { return }
                    
                    do {
                        try self.realm.write {
                            self.realm.add(folderResponse)
                        }
                    } catch {
                        print("\(error)")
                    }
                    userDefault.setValue(true, forKey: "firstloginfolder")
                case .failure(let error):
                    print(error)
                }
            }
        case .memo:
            let userDefault = UserDefaults.standard
            guard userDefault.value(forKey: "firstloginmemo") == nil else { return }
            
            let url = mainDomain + "memo/"
            let tokenValue = TokenAuth()
            let headers = tokenValue.getAuthHeaders()
            let call = Alamofire.request(url, method: method, parameters: nil, headers: headers)
            call.responseJSON { (response) in
                switch response.result {
                case .success(let value):
                    guard let memoResponse = Mapper<MemoData>().mapArray(JSONObject: value) else { return }
                    print(memoResponse)
                    do {
                        try self.realm.write {
                            
                            for tempfolder in self.folders {
                                for tempmemo in memoResponse {
                                    if tempfolder.id == tempmemo.category_id {
                                        print(tempmemo.image)
                                        tempfolder.memos.append(tempmemo)
                                    }
                                }
                            }
                        }
                    } catch {
                        print("\(error)")
                    }
                    userDefault.setValue(true, forKey: "firstloginmemo")
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
}


// MARK: - uiCustom
//
extension PemoMainViewController {
    func uiCustom() {
        
        //        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "mainviewcolor")!)
        
        self.bottomView.addTopBorderWithColor(color: .lightGray, width: 0.8)
        self.titleLabel.textColor = UIColor.piBrownishGrey
        //        self.newMemoButton.layer.cornerRadius = 7
        //        self.newMemoButton.layer.borderColor = UIColor.lightGray.cgColor
        //        self.newMemoButton.layer.borderWidth = 1
        
        // titleview image
        
        
        //        let rightBar = UIBarButtonItem(customView: imageView)
        //        self.navigationItem.rightBarButtonItem = rightBar
        //        self.navigationController?.navigationBar.barTintColor = UIColor.white
        //        self.navigationController?.navigationBar.tintColor = UIColor.white
        //        self.navigationController?.navigationBar.isTranslucent = false
        // navigationbar image
        //        let viewImage = UIImage(named: "navigationbar")
        //        let width = self.navigationController?.navigationBar.frame.size.width
        //        let height = self.navigationController?.navigationBar.frame.size.height
        //        viewImage?.draw(in: CGRect(x: 0, y: 0, width: width!, height: height!))
        //        self.navigationController?.navigationBar.setBackgroundImage(viewImage, for: .default)
        // newMemobutton
        //        let shadowSize : CGFloat = 5.0
        //        let shadowPath = UIBezierPath(rect: CGRect(x: -shadowSize / 2, y: -shadowSize / 2, width: self.newMemoButton.frame.size.width, height: self.newMemoButton.frame.size.height))
        //        self.newMemoButton.layer.masksToBounds = false
        //        self.newMemoButton.layer.borderColor = UIColor.piGreyish.cgColor
        //        self.newMemoButton.layer.borderWidth = 0.5
        //        self.newMemoButton.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        //        self.newMemoButton.layer.shadowOpacity = 0.3
        //        //        self.newMemoButton.layer.shadowPath = shadowPath.cgPath
    }
    func stringDate(_ value: String) -> Date {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.date(from: value)!
    }
    
    func DateString(_ value: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: value as Date)
    }
}


