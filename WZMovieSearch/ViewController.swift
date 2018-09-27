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
            
            cell?.textLabel?.text = keywords?[indexPath.row]
            return cell!
        }
        else {
            let movie = movies[indexPath.row]
            let cellIdentifier = "movieCell"
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! MovieTableViewCell
            
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
            if !isLoading && !thatsAll {
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
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // show previous successful search keywords list
        showSuccessfulKeywords()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        isShowingKeywords = true
        thatsAll = false
        pageCount = 1
        self.movies = []
        getMovies(keyword: searchBar.text!)
    }
    
    private func getMovies(keyword:String) {
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
        return UserDefaults.standard.value(forKey: "success_keywords") as? [String]
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
            UserDefaults.standard.set(allKeywords, forKey: "success_keywords")
        }
    }
}


class APIRequest {
    func getMovies(query:String, page:Int, completion: @escaping ([Movie]?, Error?) -> ()) {
        let apiKey = "2696829a81b1b5827d515ff121700838"
        let request = URLRequest(url: URL(string: "http://api.themoviedb.org/3/search/movie?query=\(query)&page=\(page)&api_key=\(apiKey)")!)
        
        let dataTask = URLSession.shared.dataTask(with: request, completionHandler: { (data, url, error) in
            
            if let err = error {
                completion(nil,err)
            }
            else {
                var result : [Movie] = []
                if let json = self.parseJSON(from: data!) as? [String:Any],  json["errors"] == nil {
                    
                    let jsonObjectArray = json["results"] as! Array<Any>
                    
                    for jsonObject in jsonObjectArray {
                        if let movieRaw = jsonObject as? [String:Any] {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd"
                            let releaseDate = dateFormatter.date(from: movieRaw["release_date"] as! String)
                            
                            let movieObj = Movie(id: (movieRaw["id"] as! NSNumber).stringValue, name: movieRaw["title"] as? String, releaseDate: releaseDate, overview: movieRaw["overview"] as? String, thumbnailUrl: movieRaw["poster_path"] as? String)
                            result.append(movieObj)
                        }
                    }
                }
                
                completion(result,nil)
            }
        })
        
        dataTask.resume()
    }
    
    func parseJSON(from data: Data) -> Any? {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            return json
        } catch {
            return nil
        }
    }
}
