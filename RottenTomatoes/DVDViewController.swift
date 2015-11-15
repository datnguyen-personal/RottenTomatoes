//
//  DVDViewController.swift
//  RottenTomatoes
//
//  Created by Dat Nguyen on 14/11/15.
//  Copyright © 2015 datnguyen. All rights reserved.
//

import UIKit
import Alamofire
import AFNetworking
import KVNProgress

class DVDViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var movieTableView: UITableView!
    @IBOutlet weak var errorUIView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var movieSearchBar: UISearchBar!
    
    
    let dataURL = "https://coderschool-movies.herokuapp.com/dvds?api_key=xja087zcvxljadsflh214"
    
    var movies = [NSDictionary]()
    
    var refreshControl: UIRefreshControl!
    
    var errorViewFrame: CGRect!
    
    var reachability: Reachability?
    
    var filteredMovies: [NSDictionary] = []
    
    var isSearching: Bool = false
    
    var ratingIconDictionary: NSDictionary = ["Certified Fresh":UIImage(named: "CertifiedFreshIcon")!, "Fresh":UIImage(named: "FreshIcon")!, "Rotten":UIImage(named: "RottenIcon")!]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // set up navigation controller
        navigationController?.navigationBar.barTintColor = UIColor(red: 41/255, green: 128/255, blue: 185/255, alpha: 1.0)
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)]
        navigationController?.navigationBar.tintColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        //set up search bar
        movieSearchBar.barTintColor = UIColor(red: 41/255, green: 128/255, blue: 185/255, alpha: 1.0)
        movieSearchBar.translucent = false
        
        errorViewFrame = errorUIView.frame
        dismissError()
        
        // set up movie table view
        movieTableView.dataSource = self
        movieTableView.delegate = self
        movieSearchBar.delegate = self
        
        //set up refresh controller
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.clearColor()
        refreshControl.addTarget(self, action: "onRefresh", forControlEvents: UIControlEvents.ValueChanged)
        movieTableView.addSubview(refreshControl)
        
        //fetch movies from API with nerwork validation
        fetchMoviesWithNetwork()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        
    }

    @IBAction func dimissErrorBanner(sender: AnyObject) {
        dismissError()
    }
    
    func dismissKeyboard(){
        movieSearchBar.endEditing(true)
    }
    
    deinit {
        
        reachability?.stopNotifier()
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: ReachabilityChangedNotification, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        filteredMovies = movies.filter({ (movieList: NSDictionary) -> Bool in
            let result = movieList["title"]?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch)
            
            return result?.location != NSNotFound
        })
        
        if(filteredMovies.count == 0){
            isSearching = false;
        } else {
            isSearching = true;
        }
        
        movieTableView.reloadData()
        
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        if searchBar.text != "" {
            isSearching = true
        }
        
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        isSearching = false
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        isSearching = false
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        isSearching = false
    }
    
    func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
        let cell = movieTableView.cellForRowAtIndexPath(indexPath)
        cell!.contentView.superview!.backgroundColor = UIColor(red: 41/255, green: 128/255, blue: 185/255, alpha: 0.5)
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        movieTableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, didUnhighlightRowAtIndexPath indexPath: NSIndexPath) {
        let cell = movieTableView.cellForRowAtIndexPath(indexPath)
        cell!.contentView.superview!.backgroundColor = UIColor.clearColor()
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let cell = sender as! UITableViewCell
        let indexPath = movieTableView.indexPathForCell(cell)!
        
        var movie: NSDictionary?
        
        if isSearching {
            movie = filteredMovies[indexPath.row]
        } else {
            movie = movies[indexPath.row]
        }
        
        let movieDetailViewController = segue.destinationViewController as! MovieDetailsViewController
        
        movieDetailViewController.movie = movie
        
        movieDetailViewController.hidesBottomBarWhenPushed = true
    }
    
    func onRefresh() {
        fetchMovies()
    }
    
    //initiate progress bar
    func showProgress(){
        var config: KVNProgressConfiguration!
        
        config = KVNProgressConfiguration()
        
        //config.fullScreen = true
        config.backgroundFillColor = UIColor(red:0.173, green:0.263, blue:0.856, alpha:0.0)
        config.backgroundTintColor = UIColor(red:1, green:1, blue:1, alpha:1.0)
        
        KVNProgress.setConfiguration(config)
        
        KVNProgress.showWithStatus("Loading DVDs...")
    }
    
    //dimiss progress bar
    func hideProgress(){
        KVNProgress.dismiss()
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        
        movieTableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            return filteredMovies.count
        }
        return movies.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = movieTableView.dequeueReusableCellWithIdentifier("dvdCell") as! MovieCell
        
        cell.selectionStyle = .None
        
        var movie: NSDictionary?
        
        if isSearching {
            movie = filteredMovies[indexPath.row]
        } else {
            movie = movies[indexPath.row]
        }
        
        cell.titleLabel.text = movie!["title"] as! String?
        cell.summaryLabel.text = movie!["synopsis"] as! String?
        //print(String(movie!.valueForKeyPath("ratings.critics_score")) + "%")
        cell.ratingLabel?.text = String(movie!.valueForKeyPath("ratings.critics_score") as! Int) + "%"
        cell.durationLabel?.text = String(movie!["runtime"] as! Int) + " mins"
        let ratingType = movie!.valueForKeyPath("ratings.critics_rating") as! String
        
        if let img = ratingIconDictionary[ratingType] as? UIImage {
            cell.ratingImageView?.image = img
        }
        
        //insert image
        //movie.valueForKeyPath("posters.thumbnail")
        if let posters = movie!["posters"] as? NSDictionary {
            let imageURLString = posters["thumbnail"] as! String
            let imageURL = NSURL(string: imageURLString)
            cell.posterImageView.setImageWithURL(imageURL!)
            
        } else {
            print("fail")
        }
        return cell
    }
    
    //show error banner with specific message
    func showError(errorMsg: String){
        
        self.errorUIView.hidden = false
        self.errorLabel.text = errorMsg
        self.refreshControl.endRefreshing()
        self.hideProgress()
        
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.errorUIView.frame = self.errorViewFrame
        })
        
    }
    
    //hide error banner
    func dismissError(){
        if errorUIView.hidden == false {
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.errorUIView.frame = CGRectMake(self.errorViewFrame.origin.x, self.errorViewFrame.origin.y - self.errorViewFrame.height, self.errorViewFrame.width, self.errorViewFrame.height)
                }, completion:{
                    (value: Bool) in
                    self.errorUIView.hidden = true
            })
            
        }
        
    }
    
    //indicate network change
    func reachabilityChanged(note: NSNotification) {
        let reachability = note.object as! Reachability
        
        if reachability.isReachable() {
            fetchMovies()
            //print("Connected")
        } else {
            showError("Internet is not available.")
            //print("Fail")
        }
    }
    
    //function to get a list of movies from given api address
    func fetchMovies(){
        showProgress()
        //dismissError()
        
        // Network check and fecth movies
        if let reachability = reachability {
            if reachability.isReachable() {
                let url = NSURL(string: self.dataURL)
                
                //let request = NSURLRequest(URL: url!)
                
                let session = NSURLSession.sharedSession()
                
                let task = session.dataTaskWithURL(url!) { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                    guard error == nil else {
                        self.refreshControl.endRefreshing()
                        self.hideProgress()
                        self.showError("Error Fetching Movies: \(error)")
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
                        self.dismissError()
                    })
                    
                }
                
                task.resume()
            } else {
                showError("Internet is required to load movies.")
            }
        }
        
        
    }
    
    //function to check for network avalability and call fetchMovies()
    func fetchMoviesWithNetwork(){
        //init rechability
        do {
            let reachability = try Reachability.reachabilityForInternetConnection()
            self.reachability = reachability
        } catch ReachabilityError.FailedToCreateWithAddress(let address) {
            showError("System Error with address\n\(address)")
            return
        } catch {}
        
        //start notification to indicate network state
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged:", name: ReachabilityChangedNotification, object: reachability)
        
        
        do {
            try reachability?.startNotifier()
        } catch {
            showError("System Error with notifier")
            return
        }
        
        // Fecth movies
        fetchMovies()
    }

}
