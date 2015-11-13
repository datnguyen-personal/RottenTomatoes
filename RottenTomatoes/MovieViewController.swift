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
import KVNProgress

class MovieViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var movieTableView: UITableView!
    @IBOutlet weak var errorUIView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    
    let dataURL = "https://coderschool-movies.herokuapp.com/movies?api_key=xja087zcvxljadsflh214"
    
    var movies = [NSDictionary]()
    
    var refreshControl: UIRefreshControl!
    
    var errorViewFrame: CGRect!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.barTintColor = UIColor(red: 41/255, green: 128/255, blue: 185/255, alpha: 1)
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)]
        
        errorViewFrame = errorUIView.frame
        
        // Do any additional setup after loading the view.
        movieTableView.dataSource = self
        movieTableView.delegate = self
        showProgress()
        
        refreshControl = UIRefreshControl()

        refreshControl.addTarget(self, action: "onRefresh", forControlEvents: UIControlEvents.ValueChanged)
        
        movieTableView.addSubview(refreshControl)
        
        fetchMoviesWithNetwork()
    }
    
    override func viewWillAppear(animated: Bool) {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        movieTableView.deselectRowAtIndexPath(indexPath, animated: true)
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
    
    func onRefresh() {
        fetchMoviesWithNetwork()
    }

    //initiate progress bar
    func showProgress(){
        var config: KVNProgressConfiguration!
        
        config = KVNProgressConfiguration()
        
        //config.fullScreen = true
        config.backgroundFillColor = UIColor(red:0.173, green:0.263, blue:0.856, alpha:0.0)
        config.backgroundTintColor = UIColor(red:1, green:1, blue:1, alpha:1.0)
        
        KVNProgress.setConfiguration(config)
        
        KVNProgress.showWithStatus("Loading movies...")
    }
    
    //dimiss progress bar
    func hideProgress(){
        KVNProgress.dismiss()
    }
    
    func fetchMoviesWithNetwork() {
        
        var reachability: Reachability?
        
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            showNetworkError(reachability!, errorMsg: "System Error")
            print("Unable to create Reachability")
            return
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged:", name: ReachabilityChangedNotification, object: reachability)
        
        do {
            try reachability!.startNotifier()
        } catch {
            showNetworkError(reachability!, errorMsg:"System Error")
            return
        }
        
        if let reachability = reachability {
            if reachability.isReachable() {
                fetchMovies(reachability)
            } else {
                showNetworkError(reachability, errorMsg: "Internet is required to load movies.")
            }
        }
    }
    
    func fetchMovies(reachability: Reachability){
        let url = NSURL(string: self.dataURL)
        
        //let request = NSURLRequest(URL: url!)
        
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithURL(url!) { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            guard error == nil else {
                print("Error Fetching Movie", error)
                return
            }
            
            let json = try! NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as! NSDictionary
            
            self.movies = json["movies"] as! [NSDictionary]
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.movieTableView.hidden = false
                self.movieTableView.reloadData()
                self.refreshControl.endRefreshing()
                self.hideProgress()
                self.dismissNetworkError()
                //reachability.stopNotifier()
            })
            
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
    
    func showNetworkError(reachability: Reachability ,errorMsg: String){
        errorUIView.hidden = false
        errorLabel.text = errorMsg
        refreshControl.endRefreshing()
        //reachability.stopNotifier()
        
    }
    
    func dismissNetworkError(){
        if errorUIView.hidden == false {
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                self.errorUIView.frame = CGRectMake(self.errorViewFrame.origin.x, self.errorViewFrame.origin.y - self.errorViewFrame.height, self.errorViewFrame.width, self.errorViewFrame.height)
            }, completion:{
                (value: Bool) in
                self.errorUIView.hidden = true
            })
            
        }
        
    }
    
    func reachabilityChanged(note: NSNotification) {
        let reachability = note.object as! Reachability
        
        if reachability.isReachable() {
            fetchMovies(reachability)
        } else {
            showNetworkError(reachability, errorMsg: "Internet is required to load movies.")
        }
    }

}
