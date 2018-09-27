//
//  WZMovieSearchTests.swift
//  WZMovieSearchTests
//
//  Created by wisnu wardana on 26/09/18.
//  Copyright © 2018 wisnu wardana. All rights reserved.
//

import XCTest
@testable import WZMovieSearch

class WZMovieSearchTests: XCTestCase {
    
    let api = APIRequest()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    func waitExpectation() {
        self.waitForExpectations(timeout: 10.0) { (error) in
            if let error = error {
                XCTFail("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func testSearchNotFound() {
        let exp = self.expectation(description: "Negative Not Found")
        let keyword = "dwvvqdwcqdc"
        
        let _ = api.getMovies(query: keyword, page: 1) { (movies,error) in
            
            exp.fulfill()
            XCTAssertTrue(movies?.count == 0)
        }
        
        waitExpectation()
    }
    
    func testSearchNothing() {
        let exp = self.expectation(description: "Negative No Keyword")
        let keyword = ""
        
        let _ = api.getMovies(query: keyword, page: 1) { (movies,error) in
            
            exp.fulfill()
            XCTAssertTrue(movies?.count == 0)
            
        }
        
        waitExpectation()
    }
    
    func testGetMovies() {
        let exp = self.expectation(description: "Positive found")
        let keyword = ""
        
        let api = APIRequest()
        let _ = api.getMovies(query: keyword, page: 1) { (movies,error) in
            
            exp.fulfill()
            
            guard (movies?.count)! > 0 else {
                XCTAssertTrue(movies?.count == 0)
                return
            }
            
            let firstMovieID = movies![0].id
            XCTAssertTrue(firstMovieID == "268")
            XCTAssertFalse(firstMovieID == "999")
            XCTAssertFalse((movies?.contains(where: { (movie) -> Bool in
                movie.id == "999"
            }))!)
            
        }
        
        waitExpectation()
    }
}
