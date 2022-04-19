//
//  FeedViewController.swift
//  parsetagram
//
//  Created by Ryan Sevidal on 4/17/22.
//

import UIKit
import FirebaseFirestore
import Firebase
import SceneKit
import InputBarAccessoryView

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, InputBarAccessoryViewDelegate {
    
    

    @IBOutlet weak var tableView: UITableView!
    
    var posts:[[String:Any]] = [[String:Any]]()
    var inputBar: InputBarAccessoryView = InputBarAccessoryView()
    var showsInputBar = false
    var selectedPost:Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.keyboardDismissMode = .interactive
        
        inputBar.delegate = self
        inputBar.inputTextView.keyboardType = .twitter
        inputBar.inputPlugins = []
        
        inputBar.inputTextView.placeholder = "Add a comment..."
        inputBar.sendButton.title = "Post"
        
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillBeHidden(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        // Do any additional setup after loading the view.
    }
    
    @objc func keyboardWillBeHidden(note: Notification) {
        inputBar.inputTextView.text = nil
        showsInputBar = false
        becomeFirstResponder()
    }
    
    override var inputAccessoryView: UIView? {
        return inputBar
    }
    
    override var canBecomeFirstResponder: Bool {
        return showsInputBar
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        if selectedPost >= 0 && selectedPost < self.posts.count {
            var post = self.posts[selectedPost]
            
            var newComment:[String:Any] = [String:Any]()
            newComment["text"] = text
            
            guard let user = Firebase.Auth.auth().currentUser, let username = user.email else {
                print("cannot set author of post")
                return
            }
            newComment["author"] = String(username[..<(username.firstIndex(of: "@") ?? username.endIndex)])
            newComment["authorUID"] = user.uid
            
            var comments:[[String:Any]] = [[String:Any]]()
            if post["comments"] != nil{
                comments = post["comments"] as! [[String:Any]]
            }
            
            comments.append(newComment)
            let postRef = Firestore.firestore().collection("posts").document(post["docID"] as! String)
            postRef.updateData(["comments": comments]) {
                error in
                if let err = error {
                    print("error adding comment")
                }
                else {
                    print("comment successfully added")
                    post["comments"] = comments
                    self.posts[self.selectedPost] = post
                    self.tableView.reloadData()
                }
                
                self.selectedPost = -1
                
                self.inputBar.inputTextView.text = nil
                self.showsInputBar = false
                self.becomeFirstResponder()
                
                self.inputBar.inputTextView.resignFirstResponder()
            }
        }
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
                self.posts[self.posts.count - 1]["docID"] = document.documentID
                
            }
            
            self.tableView.reloadData()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = self.posts[section]
        return (post["comments"] as? [[String:Any]] ?? []).count + 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = self.posts[indexPath.section]
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
            
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
        else {
            if let comments = (post["comments"] as? [[String:Any]]), indexPath.row < comments.count + 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
                let comment = comments[indexPath.row - 1]
                cell.commentLabel.text = comment["text"] as? String ?? "No Comment Found"
                cell.nameLabel.text = comment["author"] as? String ?? "None"
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentCell")
                return cell!
            }
        }
    }
        
    @IBAction func onLogoutButton(_ sender: Any) {
        do {
            try Firebase.Auth.auth().signOut()
        }
        catch {
            print("No user signed in!")
        }
        
        let main = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = main.instantiateViewController(withIdentifier: "LoginViewController")
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let delegate = windowScene.delegate as? SceneDelegate else { return }
        
        delegate.window?.rootViewController = loginViewController
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var post = self.posts[indexPath.section]
        if var comments = post["comments"] as? [[String:Any]] {
            if indexPath.row == comments.count + 1 {
                showsInputBar = true
                becomeFirstResponder()
                inputBar.inputTextView.becomeFirstResponder()
                selectedPost = indexPath.section
            }
        }
        else if indexPath.row == 1 {
            showsInputBar = true
            becomeFirstResponder()
            inputBar.inputTextView.becomeFirstResponder()
            selectedPost = indexPath.section
        }
        
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
