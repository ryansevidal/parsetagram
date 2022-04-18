//
//  CameraViewController.swift
//  parsetagram
//
//  Created by Ryan Sevidal on 4/18/22.
//

import UIKit
import Firebase
import FirebaseStorage
import AlamofireImage

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var commentField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func onSubmitButton(_ sender: Any) {
        guard let imageData = imageView.image?.pngData() else {
            print("can't get image data")
            return
        }
        
        let storageRef = FirebaseStorage.Storage.storage().reference()
        guard let userUID = Firebase.Auth.auth().currentUser?.uid else {
            print("can't set filename")
            return
        }
        
        let fileRef = storageRef.child("\(userUID)/files/\(Date().timeIntervalSince1970.formatted()).png")
        
        let uploadTask = fileRef.putData(imageData, metadata: nil) { metadata, error in
            guard metadata != nil else { return }
            if error != nil {
                print(error?.localizedDescription ?? "Error")
                return
            }
            
            fileRef.downloadURL { url, error in
                if error != nil {
                    print("Error getting file url")
                    return
                }
                
                var post:[String:Any] = [String:Any]()
                post["caption"] = self.commentField.text
                post["image"] = url?.absoluteString ?? ""
                
                guard let username = FirebaseAuth.Auth.auth().currentUser?.email else {
                    print("can't set author of post")
                    return
                }
                post["author"] = username[..<(username.firstIndex(of: "@") ?? username.endIndex)]
                post["authorUID"] = "\(userUID)"
                
                let postID = "\(userUID)-post\(Date().timeIntervalSince1970.formatted())"
                
                let db = Firestore.firestore()
                db.collection("posts").document(postID).setData(post) { error in
                    if error != nil {
                        print("Error making post!")
                    }
                    else {
                        print("Post successfully written!")
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func onCameraButton(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.editedImage] as! UIImage
        
        let size = CGSize(width: 300, height: 300)
        let scaledImage = image.af_imageScaled(to: size)
        
        imageView.image = scaledImage
        
        dismiss(animated: true, completion: nil)
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
