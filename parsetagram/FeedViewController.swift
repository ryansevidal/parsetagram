//
//  FeedViewController.swift
//  parsetagram
//
//  Created by Ryan Sevidal on 4/17/22.
//

import UIKit
import FirebaseFirestore
import Firebase

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var posts:[[String:Any]] = [[String:Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.posts.removeAll()
        
        let postsRef = Firestore.firestore().collection("posts")
        postsRef.limit(to: 20).getDocuments { querySnapshot, error in
            if let err = error {
                print("Error retrieving posts")
                return
            }
            
            for document in querySnapshot!.documents {
                self.posts.append(document.data())
            }
            
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
        
        let post = self.posts[indexPath.row]
        cell.usernameLabel.text = post["author"] as? String ?? ""
        cell.captionLabel.text = post["caption"] as? String ?? ""
        
        guard let url = URL(string: "\(post["image"] as? String ?? "")" ) else {
            print("can't get image url")
            cell.photoView.image = UIImage(named: "image_placeholder")
            return cell
        }
        
        cell.photoView.af.setImage(withURL: url)
        return cell
    }
        
        
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
