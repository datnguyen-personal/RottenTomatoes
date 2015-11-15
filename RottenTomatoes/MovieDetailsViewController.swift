//
//  MovieDetailsViewController.swift
//  RottenTomatoes
//
//  Created by Dat Nguyen on 11/11/15.
//  Copyright © 2015 datnguyen. All rights reserved.
//

import UIKit
import Alamofire

class MovieDetailsViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var synopsisTextView: UITextView!
    
    var movie: NSDictionary!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        titleLabel.text = movie["title"] as? String
        synopsisTextView.text = movie["synopsis"] as? String
        
        let imageURL = NSURL (string: movie.valueForKeyPath("posters.detailed") as! String)!
        let thumbnailURL = NSURL (string: movie.valueForKeyPath("posters.thumbnail") as! String)!
        
        posterImageView.setImageWithURL(thumbnailURL)
        posterImageView.setImageWithURL(imageURL)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
