//
//  MovieViewController.swift
//  RottenTomatoes
//
//  Created by Dat Nguyen on 11/11/15.
//  Copyright © 2015 datnguyen. All rights reserved.
//

import UIKit
import Alamofire
import AFNetworking

class MovieViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var movieTableView: UITableView!
    
    let dataURL = "https://coderschool-movies.herokuapp.com/movies?api_key=xja087zcvxljadsflh214"
    
    var movies = [NSDictionary]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        movieTableView.dataSource = self
        movieTableView.delegate = self
        
        fetchMovies()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let cell = sender as! UITableViewCell
        let indexPath = movieTableView.indexPathForCell(cell)!
        
        let movie = movies[indexPath.row]
        
        let movieDetailViewController = segue.destinationViewController as! MovieDetailsViewController
        
        movieDetailViewController.movie = movie
    }

    
    func fetchMovies() {
        let url = NSURL(string: dataURL)
        
        let request = NSURLRequest(URL: url!)
        
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithURL(url!) { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            guard error == nil else {
                print("Error Fetching Movie", error)
                return
            }
            
            let json = try! NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as! NSDictionary
            
            self.movies = json["movies"] as! [NSDictionary]
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.movieTableView.reloadData()
            })
            
            //print("json", self.movies)
            
        }
        
        task.resume()
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        
        movieTableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = movieTableView.dequeueReusableCellWithIdentifier("movieCell") as! MovieCell
        
        let movie = movies[indexPath.row]
        
        cell.titleLabel.text = movie["title"] as! String?
        cell.summaryLabel.text = movie["synopsis"] as! String?
        
        //insert image
        //movie.valueForKeyPath("posters.thumbnail")
        if let posters = movie["posters"] as? NSDictionary {
            let imageURLString = posters["thumbnail"] as! String
            let imageURL = NSURL(string: imageURLString)
            cell.posterImageView.setImageWithURL(imageURL!)
        
        } else {
            print("fail")
        }
        return cell
    }

}
