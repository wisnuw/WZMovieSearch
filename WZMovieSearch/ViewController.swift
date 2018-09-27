//
//  ViewController.swift
//  WZMovieSearch
//
//  Created by wisnu wardana on 26/09/18.
//  Copyright © 2018 wisnu wardana. All rights reserved.
//

import UIKit

struct Movie {
    let id:String?
    let name:String?
    let releaseDate:Date?
    let overview:String?
    let thumbnailUrl:String?
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    var movies:[Movie] = []
    var keywords:[String]? = []
    var cache:NSCache<AnyObject, AnyObject>! = NSCache()
    var pageCount = 1
    var keyword = ""
    var isLoading = false
    var thatsAll = false
    var isShowingKeywords = false
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        
        keywords = fetchAllKeyword()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - TableView Delegate and DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isShowingKeywords {
            if keywords != nil {
                return keywords!.count
            }
        }
        else {
            return movies.count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return isShowingKeywords ? 44 : 136
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isShowingKeywords {
            
            var cell = tableView.dequeueReusableCell(withIdentifier: "keywordCell")
            if cell == nil {
                cell = UITableViewCell(style: .default, reuseIdentifier: "keywordCell")
            }
            
            if !(keywords?.isEmpty)! {
                cell?.textLabel?.text = keywords?[indexPath.row]
            }
            
            return cell!
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "movieCell") as! MovieTableViewCell
            
            if !movies.isEmpty {
                let movie = movies[indexPath.row]
                
                //load image thumbnail - will be cache
                if let thumbnail = movie.thumbnailUrl, let url = URL(string: "http://image.tmdb.org/t/p/w92\(thumbnail)") {
                    let config = URLSessionConfiguration.default
                    config.timeoutIntervalForResource = 60 // timeout, in seconds

                    let session = URLSession(configuration: URLSessionConfiguration.default)
                    session.dataTask(with: url) { data, response, error in
                        if let err = error {
                            print(err.localizedDescription)
                        }
                        else {
                            DispatchQueue.main.async(execute: { () -> Void in
                                // Before we assign the image, check whether the current cell is visible
                                if let updateCell = tableView.cellForRow(at: indexPath) as? MovieTableViewCell {
                                    let img:UIImage! = UIImage(data: data!)
                                    updateCell.posterIV.image = img
                                    self.cache.setObject(img, forKey: (indexPath as NSIndexPath).row as AnyObject)
                                }
                            })
                        }
                        
                    }.resume()
                }
                
                cell.posterIV.image = #imageLiteral(resourceName: "ic_play")
                cell.titleLabel.text = movie.name!
                cell.overviewLabel.text = movie.overview
                
                if let releaseDate = movie.releaseDate {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd MMM yyyy"
                    cell.releaseDateLabel.text = dateFormatter.string(from: releaseDate)
                }
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isShowingKeywords {
            isShowingKeywords = false
            self.keyword = (keywords?[indexPath.row])!
            
            thatsAll = false
            pageCount = 1
            self.movies = []
            getMovies(keyword: self.keyword)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //check if reach last, then load next page
        
        let height = scrollView.frame.size.height
        let contentYoffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset
        if distanceFromBottom < height {
            if !isLoading && !thatsAll && !isShowingKeywords {
                pageCount += 1
                getMovies(keyword: self.keyword)
            }
        }
    }
    
    // MARK: - Search Bar Delegate
    private func showSuccessfulKeywords() {
        keywords = fetchAllKeyword()
        isShowingKeywords = true
        tableView.reloadData()
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        // show previous successful search keywords list
        showSuccessfulKeywords()
        
        return true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        isShowingKeywords = false
        thatsAll = false
        pageCount = 1
        self.movies = []
        getMovies(keyword: searchBar.text!)
    }
    
    private func getMovies(keyword:String) {
        searchBar.resignFirstResponder()
        
        let api = APIRequest()
        let _ = api.getMovies(query: keyword, page: pageCount) { [unowned self] (movies,error) in
            self.keyword = keyword
            
            if let err = error {
                self.showAlert(msg: err.localizedDescription)
            }
            
            self.movies += movies!
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
            if self.movies.count == 0 {
                self.showAlert(msg: "Not Found")
            }
            else {
                self.add(newKeyword: self.keyword)
            }
            
            if movies?.count == 0 {
                self.thatsAll = true
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Stop doing the search stuff
        // and clear the text in the search bar
        searchBar.text = ""
        // Hide the cancel button
        searchBar.showsCancelButton = false
        // You could also change the position, frame etc of the searchBar
        
        movies = []
        tableView.reloadData()
    }
    
    // MARK: - Utilities
    func showAlert(msg:String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Info", message: msg, preferredStyle: .alert)
            let action1 = UIAlertAction(title: "OK", style: .cancel) { (action:UIAlertAction) in
                print("You've pressed cancel");
            }
            alertController.addAction(action1)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func fetchAllKeyword() -> [String]? {
        let arr = UserDefaults.standard.value(forKey: "success_keywords") as? [String]
        return arr?.reversed()
    }
    
    func add(newKeyword:String) {
        var allKeywords:[String]?
        if let list = UserDefaults.standard.value(forKey: "success_keywords") as? [String] {
            allKeywords = list
        }
        else {
            allKeywords = [String]()
        }
        
        let found = allKeywords?.filter {
            $0 == newKeyword
            }.first
        
        if found == nil {
            allKeywords?.append(newKeyword)
            
            if (allKeywords?.count)!>10 {
                for i in 0...(allKeywords?.count)!-2 {
                    allKeywords![i] = allKeywords![i+1]
                }
                
                let _ = allKeywords?.removeLast()
            }
            
            UserDefaults.standard.set(allKeywords, forKey: "success_keywords")
        }
    }
}
