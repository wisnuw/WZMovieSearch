//
//  APIRequest.swift
//  WZMovieSearch
//
//  Created by wisnu wardana on 27/09/18.
//  Copyright © 2018 wisnu wardana. All rights reserved.
//

import Foundation

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
                if let json = self.parseJSON(from: data!) as? [String:Any], json["errors"] == nil {
                    
                    guard json["error"] == nil else {
                        if let errorArray = json["error"] as? [String] {
                            let errorTemp = NSError(domain: "error", code: 0, userInfo: ["msg":errorArray.joined(separator: ",")])
                            
                            completion(nil,errorTemp as Error)
                            return
                        }
                        
                        return
                    }
                    
                    if let _ = json["status_code"] as? String {
                        let errorTemp = NSError(domain: "error", code: 0, userInfo: ["msg":json["status_message"] as! String])
                        
                        completion(nil,errorTemp as Error)
                        return
                    }
                    
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
